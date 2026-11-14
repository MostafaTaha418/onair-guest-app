import 'dart:async';

import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/domain/social_identity.dart';

/// The canned social sign-in outcomes the mock can serve. Testers pick one
/// via the long-press debug dialog on the Google button (T034).
enum MockSocialScenario {
  newUser,
  incompleteUser,
  completeUser,
  legacyUser,
  unconfirmedEmailCollision,
  cancel,
  failure,
}

/// In-memory auth for `BACKEND_MODE=mock` (Guest Plan §2.6).
///
/// Follows the same contract as the Supabase implementation: 6-digit codes
/// ([MockBackend.verificationCode]), uniform messages that never reveal
/// whether an account exists, unconfirmed email continues on the code screen,
/// and every new account starts `incomplete` without a phone — the WhatsApp
/// step activates it (S005). Data lives only for the app session.
final class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    DateTime Function()? clock,
    this.currentTermsVersion = MockBackend.termsVersion,
  }) : _clock = clock ?? DateTime.now {
    // The S005 legacy account (T069): active, confirmed phone, no WhatsApp
    // step — the same object the `legacyUser` social scenario and the
    // `legacy@onair.test` email sign-in return (US7's one-account rule in
    // mock form).
    final legacy = _MockUser('mock-guest-legacy')
      ..email = 'legacy@onair.test'
      ..emailVerified = true
      ..password = legacyPassword
      ..status = AccountStatus.active
      ..phone = '+201012340000'
      ..phoneVerified = true
      ..fullName = 'Legacy Guest';
    _usersById[legacy.id] = legacy;
  }

  final DateTime Function() _clock;
  final String currentTermsVersion;
  final _changes = StreamController<GuestAccount?>.broadcast();
  final Map<String, _MockUser> _usersById = {};
  _MockUser? _current;
  String? _recoveryEmail;
  int _nextId = 1;

  /// The password of the seeded legacy mock user (and of every journey
  /// seed) — the mock accepts any sign-in with it.
  static const legacyPassword = 'Passw0rd!';

  /// The next social sign-in outcome; reset to [MockSocialScenario.newUser]
  /// after every served sign-in.
  MockSocialScenario scenario = MockSocialScenario.newUser;
  int socialSignInCalls = 0;

  @override
  Stream<GuestAccount?> get authStateChanges => _changes.stream;

  /// The current account for tests and the debug harness.
  GuestAccount? get account => _current?.toAccount();

  @override
  Future<GuestAccount?> restoreSession() async => _current?.toAccount();

  @override
  Future<GuestAccount?> refreshAccount() async => _current?.toAccount();

  @override
  Future<SocialSignInResult> signInWithGoogle() =>
      _signInWithSocial(SocialProvider.google);

  @override
  Future<SocialSignInResult> signInWithApple() =>
      _signInWithSocial(SocialProvider.apple);

  Future<SocialSignInResult> _signInWithSocial(SocialProvider provider) async {
    socialSignInCalls += 1;
    final picked = scenario;
    scenario = MockSocialScenario.newUser;
    switch (picked) {
      case MockSocialScenario.cancel:
        throw const SocialSignInCancelled();
      case MockSocialScenario.failure:
        throw const AuthRequestRejected('SOCIAL_FAILED');
      case MockSocialScenario.newUser || MockSocialScenario.incompleteUser:
        final user = _create()
          ..email = provider == SocialProvider.apple
              ? 'x7k2@privaterelay.appleid.com'
              : 'social-new@onair.test'
          ..emailVerified = true;
        final account = _signIn(user);
        return SocialSignInResult(
          account: account,
          providerFullName:
              provider == SocialProvider.google &&
                  picked == MockSocialScenario.newUser
              ? 'Mona Adel'
              : null,
        );
      case MockSocialScenario.completeUser:
        final user = _create()
          ..status = AccountStatus.active
          ..email = 'social-complete@onair.test'
          ..emailVerified = true
          ..phone = '+201012345678'
          ..phoneVerified = true
          ..fullName = 'زائر تجريبي';
        return SocialSignInResult(account: _signIn(user));
      case MockSocialScenario.legacyUser:
        // The seeded legacy account itself — the same id the email sign-in
        // returns (T069).
        return SocialSignInResult(
          account: _signIn(_usersById['mock-guest-legacy']!),
        );
      case MockSocialScenario.unconfirmedEmailCollision:
        final user = _create()
          ..email = 'collide@onair.test'
          ..emailVerified = true;
        return SocialSignInResult(account: _signIn(user));
    }
  }

  @override
  Future<CodeChallenge> signUpEmail(
    String name,
    String email,
    String password,
    String termsVersion,
  ) async {
    if (termsVersion != currentTermsVersion) throw const ProfileTermsChanged();
    final normalized = _normalize(email);
    // Uniform result: an existing email gets the same response.
    if (_findBy((u) => u.email == normalized) == null) {
      _create()
        ..email = normalized
        ..password = password
        ..fullName = name.trim()
        ..acceptedTermsVersion = termsVersion
        ..acceptedTermsAt = _clock().toUtc();
    }
    return _challenge(VerificationChannel.emailSignup, normalized);
  }

  @override
  Future<CodeChallenge> requestEmailVerification(String email) async =>
      _challenge(VerificationChannel.emailSignup, _normalize(email));

  @override
  Future<GuestAccount> verifyEmailCode(String email, String code) async {
    _checkCode(code);
    final user = _findBy((u) => u.email == _normalize(email));
    if (user == null) throw const AuthCodeRejected('OTP_INVALID');
    user.emailVerified = true;
    // S005 US6: the email code never completes an account — only «أكّد
    // رقمك» (US3–US5) confirms the phone and activates it.
    return _signIn(user);
  }

  @override
  Future<GuestAccount> signInEmail(String email, String password) async {
    final normalized = _normalize(email);
    final user = _findBy((u) => u.email == normalized);
    if (user == null || user.password != password) {
      throw const AuthRequestRejected('INVALID_CREDENTIALS');
    }
    if (!user.emailVerified) {
      throw AuthVerificationRequired(
        _challenge(VerificationChannel.emailSignup, normalized),
      );
    }
    return _signIn(user);
  }

  @override
  Future<CodeChallenge> requestRecovery(String email) async =>
      _challenge(VerificationChannel.emailRecovery, _normalize(email));

  @override
  Future<void> verifyRecovery(String email, String code) async {
    _checkCode(code);
    final normalized = _normalize(email);
    if (_findBy((u) => u.email == normalized) == null) {
      throw const AuthCodeRejected('OTP_INVALID');
    }
    _recoveryEmail = normalized;
  }

  @override
  Future<GuestAccount> setNewPassword(String password) async {
    final email = _recoveryEmail;
    final user = email == null ? null : _findBy((u) => u.email == email);
    if (user == null) throw const AuthRequestRejected('UNAUTHENTICATED');
    user
      ..password = password
      ..emailVerified = true;
    _recoveryEmail = null;
    return _signIn(user);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }

  /// S005 mock: «أكّد رقمك» confirms the number and activates the
  /// account (the WhatsApp step's success path, US4).
  void activatePhone({required String userId, required String phoneE164}) {
    final user = _usersById[userId];
    if (user == null) return;
    user
      ..phone = phoneE164
      ..phoneVerified = true
      ..status = AccountStatus.active;
    if (identical(user, _current)) _changes.add(user.toAccount());
  }

  Future<void> dispose() => _changes.close();

  void _checkCode(String code) {
    if (code != MockBackend.verificationCode) {
      throw const AuthCodeRejected('OTP_INVALID');
    }
  }

  GuestAccount _signIn(_MockUser user) {
    _current = user;
    final account = user.toAccount();
    _changes.add(account);
    return account;
  }

  CodeChallenge _challenge(VerificationChannel channel, String target) =>
      CodeChallenge(
        channel: channel,
        target: target,
        resendAt: _clock().toUtc().add(MockBackend.resendInterval),
      );

  _MockUser? _findBy(bool Function(_MockUser) test) {
    for (final user in _usersById.values) {
      if (test(user)) return user;
    }
    return null;
  }

  _MockUser _create() {
    final user = _MockUser('mock-guest-${_nextId++}');
    _usersById[user.id] = user;
    return user;
  }

  String _normalize(String email) => email.trim().toLowerCase();
}

final class _MockUser {
  _MockUser(this.id);

  final String id;
  AccountStatus status = AccountStatus.incomplete;
  String? phone;
  bool phoneVerified = false;
  String? email;
  bool emailVerified = false;
  String? password;
  String? fullName;
  String? acceptedTermsVersion;
  DateTime? acceptedTermsAt;

  GuestAccount toAccount() => GuestAccount(
    id: id,
    status: status,
    phone: phone,
    phoneVerified: phoneVerified,
    email: email,
    emailVerified: emailVerified,
    fullName: fullName,
    acceptedTermsVersion: acceptedTermsVersion,
    acceptedTermsAt: acceptedTermsAt,
  );
}
