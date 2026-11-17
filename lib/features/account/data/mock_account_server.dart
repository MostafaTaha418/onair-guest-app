import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:uuid/uuid.dart';

/// The in-memory account backend for mock mode, one story at a time
/// (deletion rules, contracts U5).
final class MockAccountServer implements AccountRepository {
  MockAccountServer({
    required this.auth,
    DateTime Function()? now,
    this.latency = const Duration(milliseconds: 250),
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final MockAuthRepository auth;
  final DateTime Function() _now;
  final Duration latency;

  /// The email the mock refuses deletion for (T064): an active booking is
  /// still running.
  static const blockedEmail = 'blocked@onair.test';

  final Map<String, DeletionRequest> _challenges = {};
  final List<DeletionBlocker> _lateBlockers = [];
  int requestCalls = 0;
  int sendCalls = 0;
  int confirmCalls = 0;
  int updateProfileCalls = 0;
  final List<({String? fullName, String? locale})> profileUpdates = [];
  String? profileLocale;
  bool deleted = false;

  /// Open deletion challenges (tests assert the request opened one).
  int get challengeCount => _challenges.length;

  /// Simulates a blocker appearing between the request and the confirm
  /// (T064: the server re-checks).
  void addLateBlocker(DeletionBlocker blocker) => _lateBlockers.add(blocker);

  /// The booking blocker the blocked account carries.
  static const blockedBooking = DeletionBlocker(
    kind: DeletionBlockerKind.booking,
    id: 'b0000000-0000-4000-8000-0000000000bb',
    code: 'OA-BLOCKED',
  );

  Future<T> _delayed<T>(T Function() action) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return action();
  }

  List<DeletionBlocker> _blockersFor(String? email) {
    if (email != null && email.startsWith(blockedEmail)) {
      return const [blockedBooking];
    }
    if (_lateBlockers.isNotEmpty) return List.of(_lateBlockers);
    return const [];
  }

  @override
  Future<DeletionRequest> requestDeletion() => _delayed(() {
    requestCalls++;
    final account = auth.account;
    if (account == null) {
      throw AppFailure(ErrorMapper.fromCode('UNAUTHENTICATED'));
    }
    final blockers = _blockersFor(account.email);
    if (blockers.isNotEmpty) throw DeletionBlockedException(blockers);
    final request = DeletionRequest(
      challengeId: const Uuid().v4(),
      maskedEmail: _maskEmail(account.email ?? 'guest@onair.test'),
    );
    _challenges[request.challengeId] = request;
    return request;
  });

  @override
  Future<SendWindow> sendDeletionCode(String challengeId) => _delayed(() {
    sendCalls++;
    if (!_challenges.containsKey(challengeId)) {
      throw AppFailure(ErrorMapper.fromCode('NOT_FOUND'));
    }
    final now = _now();
    return SendWindow(
      serverTime: now,
      receivedAt: now,
      // The email ladder allows the next send after a minute (T065's
      // `SendWindow from /v1/otp/send`).
      nextSendAt: now.add(const Duration(minutes: 1)),
    );
  });

  @override
  Future<void> confirmDeletion(String challengeId, String code) => _delayed(() {
    confirmCalls++;
    final request = _challenges[challengeId];
    if (request == null) {
      throw AppFailure(ErrorMapper.fromCode('NOT_FOUND'));
    }
    if (code != MockBackend.verificationCode) {
      throw AppFailure(ErrorMapper.fromCode('OTP_INVALID'));
    }
    // The server re-checks the blockers inside the confirm (contracts
    // U5, race).
    final account = auth.account;
    final blockers = _blockersFor(account?.email);
    if (blockers.isNotEmpty) throw DeletionBlockedException(blockers);
    deleted = true;
  });

  @override
  Future<void> updateProfile({String? fullName, String? locale}) =>
      _delayed(() {
        updateProfileCalls++;
        profileUpdates.add((fullName: fullName, locale: locale));
        if (fullName != null) {
          final trimmed = fullName.trim();
          final hasLetter = RegExp(r'[A-Za-z\u0621-\u064A]').hasMatch(trimmed);
          if (trimmed.length < 2 || trimmed.length > 80 || !hasLetter) {
            _fail('VALIDATION_FAILED');
          }
          auth.renameCurrentUser(trimmed);
        }
        if (locale != null) {
          if (locale != 'ar' && locale != 'en') _fail('VALIDATION_FAILED');
          profileLocale = locale;
        }
      });

  /// The server's masking (contracts U5): `a***@g***.com`.
  static String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return 'a***@g***.com';
    final local = email.substring(0, at);
    final domain = email.substring(at + 1);
    final dot = domain.indexOf('.');
    final domainHead = dot <= 0 ? domain : domain.substring(0, dot);
    final domainTail = dot <= 0 ? '' : domain.substring(dot);
    return '${local[0]}***@${domainHead[0]}***$domainTail';
  }

  Never _fail(String code) => throw AppFailure(ErrorMapper.fromCode(code));
}
