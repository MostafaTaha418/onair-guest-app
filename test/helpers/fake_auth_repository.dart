import 'dart:async';

import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

final class FakeAuthRepository implements AuthRepository {
  final _changes = StreamController<GuestAccount?>.broadcast();
  GuestAccount? account;
  CodeChallenge? challenge;
  AuthRateLimited? rateLimit;
  Exception? requestRecoveryError;
  Exception? verifyEmailError;
  Exception? signInEmailError;
  Future<void>? requestEmailVerificationBarrier;
  Future<void>? signUpEmailBarrier;
  Future<void>? requestRecoveryBarrier;
  Future<void>? setNewPasswordBarrier;
  int requestEmailVerificationCalls = 0;
  int signUpEmailCalls = 0;
  int requestRecoveryCalls = 0;
  int setNewPasswordCalls = 0;
  int refreshAccountCalls = 0;
  String? lastEmail;
  String? lastPassword;
  String? lastName;
  String? lastPhone;
  String? lastTermsVersion;
  String? lastRecoveryEmail;

  @override
  Stream<GuestAccount?> get authStateChanges => _changes.stream;
  void publish(GuestAccount? value) {
    account = value;
    _changes.add(value);
  }

  Future<void> dispose() => _changes.close();
  @override
  Future<GuestAccount?> restoreSession() async => account;

  @override
  Future<GuestAccount?> refreshAccount() async {
    refreshAccountCalls += 1;
    return account;
  }

  @override
  Future<CodeChallenge> signUpEmail(
    String name,
    String email,
    String password,
    String phone,
    String termsVersion,
  ) async {
    signUpEmailCalls += 1;
    await signUpEmailBarrier;
    lastName = name;
    lastPhone = phone;
    lastTermsVersion = termsVersion;
    lastEmail = email;
    lastPassword = password;
    return challenge ??
        CodeChallenge(
          channel: VerificationChannel.emailSignup,
          target: email,
          resendAt: DateTime.utc(2026),
        );
  }

  @override
  Future<CodeChallenge> requestEmailVerification(String email) async {
    requestEmailVerificationCalls += 1;
    await requestEmailVerificationBarrier;
    lastEmail = email;
    if (rateLimit case final limit?) throw limit;
    return challenge ??
        CodeChallenge(
          channel: VerificationChannel.emailSignup,
          target: email,
          resendAt: DateTime.utc(2026),
        );
  }

  @override
  Future<GuestAccount> verifyEmailCode(String email, String code) async {
    if (verifyEmailError case final error?) throw error;
    return account!;
  }

  @override
  Future<GuestAccount> signInEmail(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    if (signInEmailError case final error?) throw error;
    return account!;
  }

  @override
  Future<CodeChallenge> requestRecovery(String email) async {
    requestRecoveryCalls += 1;
    await requestRecoveryBarrier;
    lastRecoveryEmail = email;
    if (requestRecoveryError case final error?) throw error;
    return challenge ??
        CodeChallenge(
          channel: VerificationChannel.emailRecovery,
          target: email,
          resendAt: DateTime.utc(2026),
        );
  }

  @override
  Future<void> verifyRecovery(String email, String code) async {}
  @override
  Future<GuestAccount> setNewPassword(String password) async {
    setNewPasswordCalls += 1;
    await setNewPasswordBarrier;
    return account!;
  }

  @override
  Future<void> signOut() async {
    publish(null);
  }
}
