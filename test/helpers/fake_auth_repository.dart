import 'dart:async';

import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

final class FakeAuthRepository implements AuthRepository {
  final _changes = StreamController<GuestAccount?>.broadcast();
  GuestAccount? account;
  CodeChallenge? challenge;
  AuthRateLimited? rateLimit;
  Exception? requestPhoneError;
  Exception? verifyPhoneError;
  Exception? completeProfileError;
  Future<void>? requestPhoneBarrier;
  int requestPhoneCalls = 0;
  Future<void>? signUpEmailBarrier;
  Future<void>? requestRecoveryBarrier;
  Future<void>? setNewPasswordBarrier;
  int signUpEmailCalls = 0;
  int requestRecoveryCalls = 0;
  int setNewPasswordCalls = 0;
  String? lastRequestedPhone;
  String? lastEmail;
  String? lastPassword;
  String? lastName;
  String? lastPhone;
  String? lastTermsVersion;
  String? lastRecoveryEmail;
  Exception? signInEmailError;
  Exception? requestRecoveryError;

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
  Future<CodeChallenge> requestPhoneCode(String phone) async {
    requestPhoneCalls += 1;
    lastRequestedPhone = phone;
    await requestPhoneBarrier;
    if (requestPhoneError case final error?) throw error;
    if (rateLimit case final limit?) throw limit;
    return challenge ??
        CodeChallenge(
          channel: VerificationChannel.sms,
          target: phone,
          resendAt: DateTime.utc(2026),
        );
  }

  @override
  Future<GuestAccount> verifyPhoneCode(String phone, String code) async {
    if (verifyPhoneError case final error?) throw error;
    return account!;
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
    lastEmail = email;
    return challenge ??
        CodeChallenge(
          channel: VerificationChannel.emailSignup,
          target: email,
          resendAt: DateTime.utc(2026),
        );
  }

  @override
  Future<GuestAccount> verifyEmailCode(String email, String code) async =>
      account!;
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
  Future<GuestAccount> completeProfile(
    String name,
    String termsVersion,
  ) async {
    if (completeProfileError case final error?) throw error;
    return account!;
  }

  @override
  Future<void> signOut() async {
    publish(null);
  }
}
