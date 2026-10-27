import 'dart:async';

import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/egypt_phone.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

/// In-memory auth for `BACKEND_MODE=mock` (Guest Plan §2.6).
///
/// Follows the same contract as the Supabase implementation: Egyptian
/// numbers only, 6-digit codes ([MockBackend.verificationCode]), uniform
/// messages that never reveal whether an account exists, unconfirmed email
/// continues on the code screen, and terms version checks. Data lives only
/// for the app session.
final class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    DateTime Function()? clock,
    this.currentTermsVersion = MockBackend.termsVersion,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final String currentTermsVersion;
  final _changes = StreamController<GuestAccount?>.broadcast();
  final Map<String, _MockUser> _usersById = {};
  _MockUser? _current;
  String? _recoveryEmail;
  int _nextId = 1;

  @override
  Stream<GuestAccount?> get authStateChanges => _changes.stream;

  @override
  Future<GuestAccount?> restoreSession() async => _current?.toAccount();

  @override
  Future<CodeChallenge> requestPhoneCode(String phone) async {
    final parsed = EgyptPhone.tryParse(phone);
    if (parsed == null) {
      throw const AuthRequestRejected('PHONE_COUNTRY_NOT_SUPPORTED');
    }
    return _challenge(VerificationChannel.sms, parsed.e164);
  }

  @override
  Future<GuestAccount> verifyPhoneCode(String phone, String code) async {
    _checkCode(code);
    final e164 = EgyptPhone.parse(phone).e164;
    final user = (_findBy((u) => u.phone == e164) ?? _create())
      ..phone = e164
      ..phoneVerified = true;
    return _signIn(user);
  }

  @override
  Future<CodeChallenge> signUpEmail(
    String name,
    String email,
    String password,
  ) async {
    final normalized = _normalize(email);
    // Uniform result: an existing email gets the same response.
    if (_findBy((u) => u.email == normalized) == null) {
      _create()
        ..email = normalized
        ..password = password
        ..fullName = name.trim();
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
  Future<GuestAccount> completeProfile(String name, String termsVersion) async {
    final user = _current;
    if (user == null) throw const AuthRequestRejected('UNAUTHENTICATED');
    if (termsVersion != currentTermsVersion) {
      throw const ProfileTermsChanged();
    }
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 80) {
      throw const AuthRequestRejected('VALIDATION_FAILED');
    }
    user
      ..fullName = trimmed
      ..acceptedTermsVersion = termsVersion
      ..acceptedTermsAt = _clock().toUtc();
    final account = user.toAccount();
    _changes.add(account);
    return account;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
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
    phone: phone,
    phoneVerified: phoneVerified,
    email: email,
    emailVerified: emailVerified,
    fullName: fullName,
    acceptedTermsVersion: acceptedTermsVersion,
    acceptedTermsAt: acceptedTermsAt,
  );
}
