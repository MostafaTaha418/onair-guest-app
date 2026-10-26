import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

final class AuthRateLimited implements Exception {
  const AuthRateLimited(this.until);

  /// Server-provided UTC deadline.
  final DateTime until;
}

final class AuthCodeRejected implements Exception {
  const AuthCodeRejected(this.code);
  final String code;
}

final class AuthRequestRejected implements Exception {
  const AuthRequestRejected(this.code);
  final String code;
}

final class ProfileTermsChanged implements Exception {
  const ProfileTermsChanged();
}

abstract interface class AuthRepository {
  Stream<GuestAccount?> get authStateChanges;

  Future<GuestAccount?> restoreSession();
  Future<CodeChallenge> requestPhoneCode(String phone);
  Future<GuestAccount> verifyPhoneCode(String phone, String code);
  Future<CodeChallenge> signUpEmail(String name, String email, String password);
  Future<GuestAccount> verifyEmailCode(String email, String code);
  Future<GuestAccount> signInEmail(String email, String password);
  Future<CodeChallenge> requestRecovery(String email);
  Future<void> verifyRecovery(String email, String code);
  Future<GuestAccount> setNewPassword(String password);
  Future<GuestAccount> completeProfile(String name, String termsVersion);
  Future<void> signOut();
}
