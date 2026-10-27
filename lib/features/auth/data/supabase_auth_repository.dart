import 'dart:async';

import 'package:on_air/features/auth/data/profile_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
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
    phone: user.phone,
    email: user.email,
    phoneVerified: user.phoneConfirmedAt != null,
    emailVerified: user.emailConfirmedAt != null,
  );

  final String id;
  final String? phone;
  final String? email;
  final bool phoneVerified;
  final bool emailVerified;
}

abstract interface class PhoneAuthClient {
  PhoneAuthUser? get currentUser;
  Stream<PhoneAuthUser?> get userChanges;
  Future<void> requestOtp(String phone);
  Future<PhoneAuthUser> verifySmsOtp(String phone, String token);
  Future<void> signUpWithEmail(String name, String email, String password);
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
  Future<void> requestOtp(String phone) =>
      _client.signInWithOtp(phone: phone, shouldCreateUser: true);

  @override
  Future<PhoneAuthUser> verifySmsOtp(String phone, String token) async {
    final response = await _client.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    final user = response.user;
    if (user == null) throw const AuthException('OTP returned no user');
    return PhoneAuthUser.fromSupabase(user);
  }

  @override
  Future<void> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    await _client.signUp(
      email: email,
      password: password,
      data: {'full_name': name.trim()},
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
  }) : _clock = clock ?? DateTime.now;

  final PhoneAuthClient _auth;
  final ProfileSource _profiles;
  final DateTime Function() _clock;

  @override
  Stream<GuestAccount?> get authStateChanges =>
      _auth.userChanges.asyncMap(_accountFor);

  @override
  Future<GuestAccount?> restoreSession() async =>
      _accountFor(_auth.currentUser);

  @override
  Future<CodeChallenge> requestPhoneCode(String phone) async {
    final parsed = EgyptPhone.tryParse(phone);
    if (parsed == null) {
      throw const AuthRequestRejected('PHONE_COUNTRY_NOT_SUPPORTED');
    }
    try {
      await _auth.requestOtp(parsed.e164);
      // GoTrue does not expose resend headers. An immediate deadline avoids
      // inventing a client-side interval; server rate limits remain authoritative.
      return CodeChallenge(
        channel: VerificationChannel.sms,
        target: parsed.e164,
        resendAt: _clock().toUtc(),
      );
    } on AuthException catch (error) {
      throw _mapRequestError(error);
    }
  }

  @override
  Future<GuestAccount> verifyPhoneCode(String phone, String code) async {
    try {
      final user = await _auth.verifySmsOtp(EgyptPhone.parse(phone).e164, code);
      return (await _accountFor(user))!;
    } on AuthException catch (error) {
      throw _mapVerifyError(error);
    }
  }

  Exception _mapRequestError(AuthException error) {
    if (_isRateLimited(error)) return AuthRateLimited(_retryDeadline(error));
    if (error.code == 'phone_provider_disabled' ||
        error.code == 'phone_country_not_supported' ||
        error.message.toLowerCase().contains('country')) {
      return const AuthRequestRejected('PHONE_COUNTRY_NOT_SUPPORTED');
    }
    return AuthRequestRejected(error.code ?? 'INTERNAL');
  }

  Exception _mapVerifyError(AuthException error) {
    if (_isRateLimited(error)) return AuthRateLimited(_retryDeadline(error));
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();
    if (code.contains('expired') || message.contains('expired')) {
      return const AuthCodeRejected('OTP_EXPIRED');
    }
    return const AuthCodeRejected('OTP_INVALID');
  }

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
      phone: user.phone,
      phoneVerified: user.phoneVerified,
      email: user.email,
      emailVerified: user.emailVerified,
      fullName: profile.fullName,
      acceptedTermsVersion: profile.acceptedTermsVersion,
      acceptedTermsAt: profile.acceptedTermsAt,
    );
  }

  @override
  Future<GuestAccount> completeProfile(
    String name,
    String termsVersion,
  ) async {
    try {
      final profile = await _profiles.completeProfile(name, termsVersion);
      final user = _auth.currentUser;
      if (user == null) throw const AuthException('Session missing');
      return GuestAccount(
        id: user.id,
        phone: user.phone,
        phoneVerified: user.phoneVerified,
        email: user.email,
        emailVerified: user.emailVerified,
        fullName: profile.fullName,
        acceptedTermsVersion: profile.acceptedTermsVersion,
        acceptedTermsAt: profile.acceptedTermsAt,
      );
    } on PostgrestException catch (error) {
      if (error.code == 'TERMS_CHANGED' ||
          error.message.contains('TERMS_CHANGED')) {
        throw const ProfileTermsChanged();
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<CodeChallenge> signUpEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      await _auth.signUpWithEmail(name, _normalizeEmail(email), password);
      return _emailChallenge(VerificationChannel.emailSignup, email);
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
      if (_isRateLimited(error)) throw AuthRateLimited(_retryDeadline(error));
      throw const AuthRequestRejected('INVALID_CREDENTIALS');
    }
  }

  @override
  Future<CodeChallenge> requestRecovery(String email) async {
    final normalized = _normalizeEmail(email);
    try {
      await _auth.requestPasswordRecovery(normalized);
    } on AuthException catch (error) {
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
    if (_isRateLimited(error)) return AuthRateLimited(_retryDeadline(error));
    return AuthRequestRejected(error.code ?? 'INTERNAL');
  }
}
