import 'dart:async';

import 'package:on_air/features/auth/data/profile_repository.dart';
import 'package:on_air/features/auth/data/social_credential_source.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/domain/social_identity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class PhoneAuthUser {
  const PhoneAuthUser({
    required this.id,
    this.phone,
    this.email,
    this.phoneVerified = false,
    this.emailVerified = false,
  });

  factory PhoneAuthUser.fromSupabase(User user) => PhoneAuthUser(
    id: user.id,
    phone: _nonBlank(user.phone),
    email: _nonBlank(user.email),
    phoneVerified: user.phoneConfirmedAt != null,
    emailVerified: user.emailConfirmedAt != null,
  );

  final String id;
  final String? phone;
  final String? email;
  final bool phoneVerified;
  final bool emailVerified;
}

String? _nonBlank(String? value) =>
    value == null || value.trim().isEmpty ? null : value;

abstract interface class PhoneAuthClient {
  PhoneAuthUser? get currentUser;
  Stream<PhoneAuthUser?> get userChanges;
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  });
  Future<void> signUpWithEmail(
    String name,
    String email,
    String password,
    String termsVersion, {
    required String locale,
  });
  Future<void> resendSignupEmail(String email);
  Future<PhoneAuthUser> verifySignupEmailOtp(String email, String token);
  Future<PhoneAuthUser> signInWithEmailPassword(
    String email,
    String password,
  );
  Future<void> requestPasswordRecovery(String email);
  Future<void> verifyRecoveryEmailOtp(String email, String token);
  Future<PhoneAuthUser> updatePassword(String password);
  Future<void> signOut();
}

final class SupabasePhoneAuthClient implements PhoneAuthClient {
  const SupabasePhoneAuthClient(this._client);
  final GoTrueClient _client;

  @override
  PhoneAuthUser? get currentUser => switch (_client.currentUser) {
    final user? => PhoneAuthUser.fromSupabase(user),
    null => null,
  };

  @override
  Stream<PhoneAuthUser?> get userChanges => _client.onAuthStateChange.map(
    (event) => switch (event.session?.user) {
      final user? => PhoneAuthUser.fromSupabase(user),
      null => null,
    },
  );

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) => _client.signInWithIdToken(
    provider: provider,
    idToken: idToken,
    accessToken: accessToken,
    nonce: nonce,
  );

  @override
  Future<void> signUpWithEmail(
    String name,
    String email,
    String password,
    String termsVersion, {
    required String locale,
  }) async {
    await _client.signUp(
      email: email,
      password: password,
      // The phone is gone from registration (S005 US6): «أكّد رقمك» owns
      // the number after the email code.
      data: {
        'full_name': name.trim(),
        'accepted_terms_version': termsVersion,
        'locale': locale,
      },
    );
  }

  @override
  Future<void> resendSignupEmail(String email) async {
    await _client.resend(email: email, type: OtpType.signup);
  }

  @override
  Future<PhoneAuthUser> verifySignupEmailOtp(
    String email,
    String token,
  ) async {
    final response = await _client.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
    return _requiredUser(response.user);
  }

  @override
  Future<PhoneAuthUser> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await _client.signInWithPassword(
      email: email,
      password: password,
    );
    return _requiredUser(response.user);
  }

  @override
  Future<void> requestPasswordRecovery(String email) =>
      _client.resetPasswordForEmail(email);

  @override
  Future<void> verifyRecoveryEmailOtp(String email, String token) async {
    await _client.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  @override
  Future<PhoneAuthUser> updatePassword(String password) async {
    final response = await _client.updateUser(
      UserAttributes(password: password),
    );
    return _requiredUser(response.user);
  }

  PhoneAuthUser _requiredUser(User? user) {
    if (user == null) {
      throw const AuthException('Auth response returned no user');
    }
    return PhoneAuthUser.fromSupabase(user);
  }

  @override
  Future<void> signOut() => _client.signOut();
}

final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._auth,
    this._profiles, {
    DateTime Function()? clock,
    SocialCredentialSource? socialCredentials,
    String Function()? locale,
  }) : _clock = clock ?? DateTime.now,
       _socialCredentials = socialCredentials ?? GoogleAppleCredentialSource(),
       _locale = locale ?? (() => 'ar');

  final PhoneAuthClient _auth;
  final ProfileSource _profiles;
  final DateTime Function() _clock;
  final SocialCredentialSource _socialCredentials;

  /// The current locale code the sign-up metadata carries.
  final String Function() _locale;

  @override
  Stream<GuestAccount?> get authStateChanges =>
      _auth.userChanges.asyncMap(_accountFor);

  @override
  Future<GuestAccount?> restoreSession() async =>
      _accountFor(_auth.currentUser);

  @override
  Future<GuestAccount?> refreshAccount() async =>
      _accountFor(_auth.currentUser);

  @override
  Future<SocialSignInResult> signInWithGoogle() =>
      _signInWithSocial(SocialProvider.google);

  @override
  Future<SocialSignInResult> signInWithApple() =>
      _signInWithSocial(SocialProvider.apple);

  Future<SocialSignInResult> _signInWithSocial(
    SocialProvider provider,
  ) async {
    final credential = switch (provider) {
      SocialProvider.google => await _socialCredentials.google(),
      SocialProvider.apple => await _socialCredentials.apple(),
    };
    try {
      final response = await _auth.signInWithIdToken(
        provider: switch (provider) {
          SocialProvider.google => OAuthProvider.google,
          SocialProvider.apple => OAuthProvider.apple,
        },
        idToken: credential.idToken,
        accessToken: credential.accessToken,
        nonce: credential.rawNonce,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Social sign-in returned no user');
      }
      final account = await _accountFor(PhoneAuthUser.fromSupabase(user));
      if (account == null) {
        throw const AuthException('Social sign-in returned no session');
      }
      return SocialSignInResult(
        account: account,
        providerFullName: _socialFullName(credential),
      );
    } on AuthException catch (error) {
      if (_isNetwork(error)) throw const AuthNetworkFailure();
      throw const AuthRequestRejected('SOCIAL_FAILED');
    }
  }

  String? _socialFullName(SocialCredential credential) {
    final joined =
        '${credential.givenName ?? ''} '
                '${credential.familyName ?? ''}'
            .trim();
    return joined.isNotEmpty ? joined : credential.displayName;
  }

  Exception _mapVerifyError(AuthException error) {
    if (_isNetwork(error)) return const AuthNetworkFailure();
    if (_isRateLimited(error)) return AuthRateLimited(_retryDeadline(error));
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();
    if (code.contains('expired') || message.contains('expired')) {
      return const AuthCodeRejected('OTP_EXPIRED');
    }
    return const AuthCodeRejected('OTP_INVALID');
  }

  /// GoTrue wraps connection failures and timeouts in this subclass.
  bool _isNetwork(AuthException error) =>
      error is AuthRetryableFetchException && error.statusCode == null;

  bool _isRateLimited(AuthException error) =>
      error.statusCode == '429' ||
      (error.code?.contains('rate_limit') ?? false);

  DateTime _retryDeadline(AuthException error) {
    final seconds = RegExp(
      r'(\d+)\s*(?:seconds?|secs?|s)\b',
      caseSensitive: false,
    ).firstMatch(error.message);
    return _clock().toUtc().add(
      Duration(seconds: int.tryParse(seconds?.group(1) ?? '') ?? 0),
    );
  }

  Future<GuestAccount?> _accountFor(PhoneAuthUser? user) async {
    if (user == null) return null;
    final profile = await _profiles.loadOwnProfile(user.id);
    return GuestAccount(
      id: user.id,
      status: profile.status,
      phone: profile.phone ?? user.phone,
      phoneVerified: profile.phoneVerified || user.phoneVerified,
      email: profile.email ?? user.email,
      emailVerified: profile.emailVerified || user.emailVerified,
      fullName: profile.fullName,
      authProviders: profile.authProviders,
      hasPassword: profile.hasPassword,
      acceptedTermsVersion: profile.acceptedTermsVersion,
      acceptedTermsAt: profile.acceptedTermsAt,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<CodeChallenge> signUpEmail(
    String name,
    String email,
    String password,
    String termsVersion,
  ) async {
    try {
      await _auth.signUpWithEmail(
        name,
        _normalizeEmail(email),
        password,
        termsVersion,
        locale: _locale(),
      );
      return _emailChallenge(VerificationChannel.emailSignup, email);
    } on AuthRequestRejected {
      rethrow;
    } on AuthException catch (error) {
      throw _mapEmailRequestError(error);
    }
  }

  @override
  Future<CodeChallenge> requestEmailVerification(String email) async {
    try {
      await _auth.resendSignupEmail(_normalizeEmail(email));
      return _emailChallenge(VerificationChannel.emailSignup, email);
    } on AuthException catch (error) {
      throw _mapEmailRequestError(error);
    }
  }

  @override
  Future<GuestAccount> verifyEmailCode(String email, String code) async {
    try {
      final user = await _auth.verifySignupEmailOtp(
        _normalizeEmail(email),
        code,
      );
      return (await _accountFor(user))!;
    } on AuthException catch (error) {
      throw _mapVerifyError(error);
    }
  }

  @override
  Future<GuestAccount> signInEmail(String email, String password) async {
    try {
      final user = await _auth.signInWithEmailPassword(
        _normalizeEmail(email),
        password,
      );
      return (await _accountFor(user))!;
    } on AuthException catch (error) {
      if (_isNetwork(error)) throw const AuthNetworkFailure();
      if (_isRateLimited(error)) throw AuthRateLimited(_retryDeadline(error));
      if (error.code == 'email_not_confirmed') {
        // FR-027: an unconfirmed email must not lock the guest out. GoTrue only
        // reports this after the password matched, so no account is revealed.
        throw AuthVerificationRequired(await _resendSignupCode(email));
      }
      throw const AuthRequestRejected('INVALID_CREDENTIALS');
    }
  }

  /// Requests a fresh signup code. A throttled resend still continues to the
  /// code screen (the previous code may be valid) with the server deadline.
  Future<CodeChallenge> _resendSignupCode(String email) async {
    try {
      await _auth.resendSignupEmail(_normalizeEmail(email));
      return _emailChallenge(VerificationChannel.emailSignup, email);
    } on AuthException catch (error) {
      if (_isNetwork(error)) throw const AuthNetworkFailure();
      return CodeChallenge(
        channel: VerificationChannel.emailSignup,
        target: _normalizeEmail(email),
        resendAt: _isRateLimited(error)
            ? _retryDeadline(error)
            : _clock().toUtc(),
      );
    }
  }

  @override
  Future<CodeChallenge> requestRecovery(String email) async {
    final normalized = _normalizeEmail(email);
    try {
      await _auth.requestPasswordRecovery(normalized);
    } on AuthException catch (error) {
      if (_isNetwork(error)) throw const AuthNetworkFailure();
      // Account discovery is deliberately prevented. Only throttling is shown.
      if (_isRateLimited(error)) throw AuthRateLimited(_retryDeadline(error));
    }
    return _emailChallenge(VerificationChannel.emailRecovery, normalized);
  }

  @override
  Future<void> verifyRecovery(String email, String code) async {
    try {
      await _auth.verifyRecoveryEmailOtp(_normalizeEmail(email), code);
    } on AuthException catch (error) {
      throw _mapVerifyError(error);
    }
  }

  @override
  Future<GuestAccount> setNewPassword(String password) async {
    try {
      return (await _accountFor(await _auth.updatePassword(password)))!;
    } on AuthException catch (error) {
      if (_isNetwork(error)) throw const AuthNetworkFailure();
      throw AuthRequestRejected(error.code ?? 'INTERNAL');
    }
  }

  CodeChallenge _emailChallenge(VerificationChannel channel, String email) =>
      CodeChallenge(
        channel: channel,
        target: _normalizeEmail(email),
        resendAt: _clock().toUtc(),
      );

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Exception _mapEmailRequestError(AuthException error) {
    if (_isNetwork(error)) return const AuthNetworkFailure();
    if (_isRateLimited(error)) return AuthRateLimited(_retryDeadline(error));
    for (final code in [
      'PHONE_COUNTRY_NOT_SUPPORTED',
      'PHONE_ALREADY_USED',
      'TERMS_CHANGED',
      'VALIDATION_FAILED',
    ]) {
      if (error.message.contains(code)) return AuthRequestRejected(code);
    }
    return AuthRequestRejected(error.code ?? 'INTERNAL');
  }
}
