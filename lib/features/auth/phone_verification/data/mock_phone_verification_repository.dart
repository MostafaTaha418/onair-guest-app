import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/device/device_identity.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/data/mock_otp_server.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:uuid/uuid.dart';

/// The mock «أكّد رقمك» server for `BACKEND_MODE=mock`. The limits (the
/// ladder and the 7-day block) live in [MockOtpServer] (node-otp.md A8) and
/// are keyed with the injected [DeviceIdentity]; the contract mirrors the
/// real backend: Egyptian numbers only, 6-digit codes
/// ([MockBackend.verificationCode]), server timestamps in the windows.
final class MockPhoneVerificationRepository
    implements PhoneVerificationRepository {
  MockPhoneVerificationRepository({
    required this._auth,
    this._deviceIdentity,
    MockOtpServer? otpServer,
  }) : otpServer = otpServer ?? MockOtpServer();

  final MockAuthRepository _auth;
  final DeviceIdentity? _deviceIdentity;

  /// Shared when an app restart replays the same mock backend, so the
  /// ladder and the block survive the reboot (quickstart V4–V6).
  final MockOtpServer otpServer;

  /// The device identity the limit keys use, exposed for the test harness.
  DeviceIdentity? get deviceIdentity => _deviceIdentity;

  final Map<String, _MockChallenge> _challenges = {};

  /// Injectable so the US5 ladder tests and the mock-clock integration runs
  /// can drive time; the default follows [MockBackend.clock] dynamically.
  DateTime Function()? _clockOverride;
  DateTime Function() get clock => _clockOverride ?? MockBackend.clock;
  set clock(DateTime Function() value) => _clockOverride = value;

  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) async {
    final account = _auth.account;
    if (account == null) {
      throw AppFailure(ErrorMapper.fromCode('UNAUTHENTICATED'));
    }
    if (purpose == PhoneVerificationPurpose.register &&
        account.status == AccountStatus.active) {
      throw AppFailure(ErrorMapper.fromCode('PROFILE_ALREADY_COMPLETE'));
    }
    if (purpose == PhoneVerificationPurpose.change &&
        account.status != AccountStatus.active) {
      throw AppFailure(ErrorMapper.fromCode('PHONE_NOT_VERIFIED'));
    }
    if (draft.phone.e164 == '+201111111111') {
      // The canned "already used" number (T057).
      throw AppFailure(ErrorMapper.fromCode('PHONE_ALREADY_USED'));
    }
    if (purpose == PhoneVerificationPurpose.register &&
        draft.acceptedTermsVersion != null &&
        draft.acceptedTermsVersion != _auth.currentTermsVersion) {
      throw AppFailure(ErrorMapper.fromCode('TERMS_CHANGED'));
    }
    final challengeId = const Uuid().v4();
    _challenges[challengeId] = _MockChallenge(
      userId: account.id,
      phone: draft.phone.e164,
    );
    return challengeId;
  }

  @override
  Future<WhatsAppChallenge> send(String challengeId) async {
    final challenge = _challenge(challengeId);
    final deviceId = await _deviceId();
    // A8 steps 2–8: the limiter throws the mapped 429s or returns the
    // window the counters produced.
    final window = otpServer.send(
      accountId: challenge.userId,
      phone: challenge.phone,
      deviceId: deviceId,
    );
    // The code generations rotate so the stale-code path is reachable in
    // mock mode (review extra): the first send uses the universal code, a
    // resend moves to [MockBackend.resendVerificationCode].
    challenge
      ..sentAt = window.serverTime
      ..deviceId = deviceId
      ..generation += 1
      ..previousCode = challenge.currentCode
      ..currentCode = challenge.generation == 1
          ? MockBackend.verificationCode
          : MockBackend.resendVerificationCode
      ..wrongAttempts = 0;
    return WhatsAppChallenge(
      challengeId: challengeId,
      maskedPhone: _mask(challenge.phone),
      expiresAt: window.serverTime.add(MockBackend.otpTtl),
      window: window,
    );
  }

  @override
  Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(
    String challengeId,
  ) async {
    final challenge = _challenge(challengeId);
    final now = clock();
    final delivered =
        challenge.sentAt != null &&
        now.difference(challenge.sentAt!) >= const Duration(seconds: 2);
    final (status, failure) = switch ((challenge.phone, delivered)) {
      (_, false) => (DeliveryStatus.pending, null),
      (final phone, true) when phone.endsWith('0000') => (
        DeliveryStatus.failed,
        DeliveryFailure.notOnWhatsApp,
      ),
      (_, true) => (DeliveryStatus.delivered, null),
    };
    return (
      status,
      failure,
      challenge.deviceId == null
          ? SendWindow(serverTime: now, receivedAt: now)
          : otpServer.windowOf(
              accountId: challenge.userId,
              phone: challenge.phone,
              deviceId: challenge.deviceId!,
            ),
    );
  }

  @override
  Future<GuestAccount> verify(String challengeId, String code) async {
    final challenge = _challenge(challengeId);
    // A8: the code lives `otp_ttl_minutes`; expiry is checked first.
    final sentAt = challenge.sentAt;
    if (sentAt == null || clock().difference(sentAt) >= MockBackend.otpTtl) {
      throw AppFailure(ErrorMapper.fromCode('OTP_EXPIRED'));
    }
    // A8 `otp_max_attempts`: after the fifth wrong code the code is burned —
    // even the right one is refused until a resend rotates it.
    if (challenge.wrongAttempts >= 5) {
      throw AppFailure(ErrorMapper.fromCode('OTP_ATTEMPTS_EXCEEDED'));
    }
    if (code == challenge.currentCode) {
      // T057: the WhatsApp confirmation is what activates the mock account.
      _auth.activatePhone(
        userId: challenge.userId,
        phoneE164: challenge.phone,
      );
      // A8 "Reset on success": the keys of the last send go back to zero.
      if (challenge.deviceId != null) {
        otpServer.countSuccess(
          accountId: challenge.userId,
          phone: challenge.phone,
          deviceId: challenge.deviceId!,
        );
      }
      final account = _auth.account;
      if (account == null) {
        throw AppFailure(ErrorMapper.fromCode('UNAUTHENTICATED'));
      }
      return account;
    }
    // An older generation's code is superseded, not wrong (review extra).
    if (code == challenge.previousCode) {
      throw AppFailure(ErrorMapper.fromCode('OTP_SUPERSEDED'));
    }
    // A8 `otp_max_attempts` (5): the fifth wrong code ends the challenge.
    challenge.wrongAttempts += 1;
    if (challenge.wrongAttempts >= 5) {
      throw AppFailure(ErrorMapper.fromCode('OTP_ATTEMPTS_EXCEEDED'));
    }
    throw AppFailure(ErrorMapper.fromCode('OTP_INVALID'));
  }

  Future<String> _deviceId() async {
    try {
      return await _deviceIdentity?.id() ?? 'unavailable';
    } on Object {
      // A8 requires a device id for the WhatsApp channel; a mock without an
      // identity still counts under a shared key.
      return 'unavailable';
    }
  }

  _MockChallenge _challenge(String challengeId) {
    final challenge = _challenges[challengeId];
    if (challenge == null) {
      throw AppFailure(ErrorMapper.fromCode('NOT_FOUND'));
    }
    return challenge;
  }

  /// The server mask — the shared [maskPhone] helper (T076).
  static String _mask(String e164) => maskPhone(e164);
}

final class _MockChallenge {
  _MockChallenge({required this.userId, required this.phone});

  final String userId;
  final String phone;
  DateTime? sentAt;

  /// Set by the last successful [MockPhoneVerificationRepository.send] —
  /// the device third of the limit keys (A8 step 4).
  String? deviceId;

  /// The code generations (review extra): generation 1 carries
  /// [MockBackend.verificationCode], a resend rotates to
  /// [MockBackend.resendVerificationCode] and pushes the old one to
  /// [previousCode] — that older code answers `OTP_SUPERSEDED`.
  int generation = 0;
  int wrongAttempts = 0;
  String? currentCode;
  String? previousCode;
}
