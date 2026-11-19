import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/active_session.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';
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
  int listSessionsCalls = 0;
  int endSessionCalls = 0;
  int endOtherSessionsCalls = 0;
  int changePasswordCalls = 0;
  bool revokeHeartbeat = false;
  final List<DateTime> _wrongPasswordAttempts = [];
  final Map<String, ({bool mandatory, bool push, bool email})> _preferences = {
    'booking': (mandatory: true, push: true, email: true),
    'payment': (mandatory: true, push: true, email: true),
    'support': (mandatory: false, push: true, email: true),
    'reminders': (mandatory: false, push: true, email: true),
    'review': (mandatory: false, push: true, email: true),
    'account': (mandatory: true, push: true, email: true),
  };
  int getPreferencesCalls = 0;
  int setPreferenceCalls = 0;
  late final List<ActiveSession> sessions = [
    ActiveSession(
      id: 'session-current',
      deviceLabel: 'Samsung SM-A546 · Android 14',
      platform: SessionPlatform.android,
      createdAt: _now().subtract(const Duration(days: 20)),
      lastActiveAt: _now(),
      isCurrent: true,
    ),
    ActiveSession(
      id: 'session-ios',
      deviceLabel: 'iPhone 15 · iOS 18',
      platform: SessionPlatform.ios,
      createdAt: _now().subtract(const Duration(days: 12)),
      lastActiveAt: _now().subtract(const Duration(hours: 2)),
      isCurrent: false,
    ),
    ActiveSession(
      id: 'session-web',
      deviceLabel: 'Chrome · Windows',
      platform: SessionPlatform.web,
      createdAt: _now().subtract(const Duration(days: 4)),
      lastActiveAt: _now().subtract(const Duration(days: 1)),
      isCurrent: false,
    ),
  ];

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

  @override
  Future<List<ActiveSession>> listSessions() => _delayed(() {
    listSessionsCalls++;
    _requireAccount();
    return ActiveSession.sorted(sessions);
  });

  @override
  Future<void> endSession(String id) => _delayed(() {
    endSessionCalls++;
    _requireAccount();
    final index = sessions.indexWhere((session) => session.id == id);
    if (index < 0) _fail('NOT_FOUND');
    if (sessions[index].isCurrent) _fail('SESSION_IS_CURRENT');
    sessions.removeAt(index);
  });

  @override
  Future<void> endOtherSessions() => _delayed(() {
    endOtherSessionsCalls++;
    _requireAccount();
    sessions.removeWhere((session) => !session.isCurrent);
  });

  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) => _delayed(() {
    changePasswordCalls++;
    _requireAccount();
    if (!auth.currentHasPassword) _fail('ACTION_NOT_ALLOWED');
    final now = _now();
    _wrongPasswordAttempts.removeWhere(
      (attempt) => now.difference(attempt) >= const Duration(minutes: 15),
    );
    if (!auth.currentPasswordMatches(current)) {
      _wrongPasswordAttempts.add(now);
      if (_wrongPasswordAttempts.length >= 6) {
        throw AppFailure(
          ErrorMapper.fromCode(
            'RATE_LIMITED',
            details: {
              'retry_at': now
                  .add(const Duration(minutes: 15))
                  .toIso8601String(),
              'retry_after_seconds': 900,
            },
          ),
        );
      }
      _fail('PASSWORD_INCORRECT');
    }
    if (next.length < 8 ||
        !RegExp('[A-Za-z]').hasMatch(next) ||
        !RegExp(r'\d').hasMatch(next) ||
        next == current) {
      _fail('PASSWORD_WEAK');
    }
    auth.changeCurrentPassword(next);
    _wrongPasswordAttempts.clear();
    sessions.removeWhere((session) => !session.isCurrent);
  });

  @override
  Future<void> heartbeat() => _delayed(() {
    _requireAccount();
    if (revokeHeartbeat) _fail('SESSION_REVOKED');
  });

  @override
  Future<List<NotificationPreference>> getPreferences() => _delayed(() {
    getPreferencesCalls++;
    _requireAccount();
    return _preferences.entries
        .map(
          (entry) => NotificationPreference(
            key: entry.key,
            labelKey: NotificationPreference.categoryLabelKey(entry.key),
            isMandatory: entry.value.mandatory,
            channels: {
              NotificationChannel.push: PreferenceChannel(
                enabled: entry.value.push,
              ),
              NotificationChannel.email: PreferenceChannel(
                enabled: entry.value.email,
              ),
            },
          ),
        )
        .toList(growable: false);
  });

  @override
  Future<void> setPreference(
    String category,
    NotificationChannel channel,
    bool enabled,
  ) => _delayed(() {
    setPreferenceCalls++;
    _requireAccount();
    final current = _preferences[category];
    if (current == null) _fail('NOT_FOUND');
    if (current.mandatory) _fail('VALIDATION_FAILED');
    _preferences[category] = (
      mandatory: false,
      push: channel == NotificationChannel.push ? enabled : current.push,
      email: channel == NotificationChannel.email ? enabled : current.email,
    );
  });

  bool pushEnabled(String category) => _preferences[category]?.push ?? true;

  void _requireAccount() {
    if (auth.account == null) _fail('UNAUTHENTICATED');
  }

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
