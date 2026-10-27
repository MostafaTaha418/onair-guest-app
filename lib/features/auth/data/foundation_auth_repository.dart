import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

/// Visitor-mode adapter until the Supabase implementation is added in US2.
final class FoundationAuthRepository implements AuthRepository {
  @override
  Stream<GuestAccount?> get authStateChanges => const Stream.empty();
  @override
  Future<GuestAccount?> restoreSession() async => null;
  Never _notReady() => throw UnsupportedError('Auth feature is not installed');
  @override
  Future<CodeChallenge> requestPhoneCode(String phone) async => _notReady();
  @override
  Future<GuestAccount> verifyPhoneCode(String phone, String code) async =>
      _notReady();
  @override
  Future<CodeChallenge> signUpEmail(
    String name,
    String email,
    String password,
  ) async => _notReady();
  @override
  Future<CodeChallenge> requestEmailVerification(String email) async =>
      _notReady();
  @override
  Future<GuestAccount> verifyEmailCode(String email, String code) async =>
      _notReady();
  @override
  Future<GuestAccount> signInEmail(String email, String password) async =>
      _notReady();
  @override
  Future<CodeChallenge> requestRecovery(String email) async => _notReady();
  @override
  Future<void> verifyRecovery(String email, String code) async => _notReady();
  @override
  Future<GuestAccount> setNewPassword(String password) async => _notReady();
  @override
  Future<GuestAccount> completeProfile(
    String name,
    String termsVersion,
  ) async => _notReady();
  @override
  Future<void> signOut() async => _notReady();
}
