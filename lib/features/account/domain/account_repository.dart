import 'package:on_air/features/account/domain/active_session.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';

/// What `common_request_account_deletion` returned (contracts U5).
final class DeletionRequest {
  const DeletionRequest({required this.challengeId, required this.maskedEmail});

  factory DeletionRequest.fromJson(Map<String, dynamic> json) =>
      DeletionRequest(
        challengeId: json['challenge_id'] as String,
        maskedEmail: json['masked_email'] as String? ?? '',
      );

  final String challengeId;
  final String maskedEmail;
}

/// The account surface that grows across G4's stories (T068): the deletion
/// pair first, then profile (US5), sessions and preferences (US6/US7).
/// Every method throws `AppFailure`; the blocker refusal comes through
/// [DeletionBlockedException].
abstract interface class AccountRepository {
  /// `common_request_account_deletion()` — refuses with
  /// [DeletionBlockedException] while anything is still running.
  Future<DeletionRequest> requestDeletion();

  /// Node `POST /v1/otp/send` for the deletion challenge; returns the
  /// server's send window for the resend countdown.
  Future<SendWindow> sendDeletionCode(String challengeId);

  /// `common_confirm_account_deletion(p_challenge_id, p_code)` — the
  /// session is over when this returns.
  Future<void> confirmDeletion(String challengeId, String code);

  /// `common_update_profile(p_full_name, p_locale)` (contracts U7, task
  /// T076): a null parameter leaves the field unchanged. The name is
  /// trimmed 2–80 characters server-side; the locale is `ar|en`.
  Future<void> updateProfile({String? fullName, String? locale});

  Future<List<ActiveSession>> listSessions();
  Future<void> endSession(String id);
  Future<void> endOtherSessions();
  Future<void> changePassword({required String current, required String next});
  Future<void> heartbeat();
}
