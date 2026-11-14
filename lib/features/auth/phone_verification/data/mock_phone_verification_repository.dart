import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:uuid/uuid.dart';

/// The mock «أكّد رقمك» server for `BACKEND_MODE=mock`. Phase 6 runs it
/// **without limits** (T057); US5 swaps the internals for the ladder-driven
/// mock OTP server. The contract mirrors node-otp.md A8: Egyptian numbers
/// only, 6-digit codes ([MockBackend.verificationCode]), server timestamps
/// in the windows.
final class MockPhoneVerificationRepository
    implements PhoneVerificationRepository {
  MockPhoneVerificationRepository({required this._auth});

  final MockAuthRepository _auth;
  final Map<String, _MockChallenge> _challenges = {};

  /// Injectable so the US5 ladder tests and the mock-clock integration runs
  /// can drive time.
  DateTime Function() clock = DateTime.now;

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
    final challenge = _challenge(challengeId)
      ..sentAt = clock()
      ..sendCount += 1;
    // A generous window: US5 replaces it with the real ladder.
    final now = clock();
    return WhatsAppChallenge(
      challengeId: challengeId,
      maskedPhone: _mask(challenge.phone),
      expiresAt: now.add(const Duration(minutes: 10)),
      window: SendWindow(
        serverTime: now,
        nextSendAt: now.add(const Duration(seconds: 30)),
      ),
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
      SendWindow(
        serverTime: now,
        nextSendAt: now.add(const Duration(seconds: 30)),
      ),
    );
  }

  @override
  Future<GuestAccount> verify(String challengeId, String code) async {
    final challenge = _challenge(challengeId);
    if (code != MockBackend.verificationCode) {
      throw AppFailure(ErrorMapper.fromCode('OTP_INVALID'));
    }
    // T057: the WhatsApp confirmation is what activates the mock account.
    _auth.activatePhone(userId: challenge.userId, phoneE164: challenge.phone);
    final account = _auth.account;
    if (account == null) {
      throw AppFailure(ErrorMapper.fromCode('UNAUTHENTICATED'));
    }
    return account;
  }

  _MockChallenge _challenge(String challengeId) {
    final challenge = _challenges[challengeId];
    if (challenge == null) {
      throw AppFailure(ErrorMapper.fromCode('NOT_FOUND'));
    }
    return challenge;
  }

  /// `+201012345678` → `+20 10•• ••• 678`.
  static String _mask(String e164) {
    final digits = e164.replaceFirst('+', '');
    if (digits.length < 7) return e164;
    return '+20 10•• ••• ${digits.substring(digits.length - 3)}';
  }
}

final class _MockChallenge {
  _MockChallenge({required this.userId, required this.phone});

  final String userId;
  final String phone;
  DateTime? sentAt;
  int sendCount = 0;
}
