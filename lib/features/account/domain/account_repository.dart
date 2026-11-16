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
}
