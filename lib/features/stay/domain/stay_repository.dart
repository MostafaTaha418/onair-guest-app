import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/features/stay/domain/damage_claim.dart';
import 'package:on_air/features/stay/domain/stay_results.dart';

abstract interface class StayRepository {
  Future<CancellationPreview> previewCancellation(String bookingId);

  Future<CancellationResult> cancelBooking({
    required String bookingId,
    required Money expectedRefund,
    required CancellationReason? reason,
    required String? reasonNote,
    required String idempotencyKey,
  });

  Future<String> confirmCheckIn(String bookingId);
  Future<String> confirmCheckOut(String bookingId);

  Future<CashRequest> startCashConfirmation({
    required String bookingId,
    required String collectorPhoneE164,
    required Money expectedAmount,
    required String idempotencyKey,
  });

  Future<void> sendCashCode(String challengeId);

  Future<CashReceipt> confirmCashPayment({
    required String paymentId,
    required String challengeId,
    required String code,
  });

  Future<DamageClaim> getDamageClaim(String claimId);

  Future<ClaimAnswerResult> respondDamageClaim({
    required String claimId,
    required ClaimDecision decision,
    required String? note,
    required String idempotencyKey,
  });

  Future<FileUrl> fileUrl(String attachmentId);

  Future<OfferAnswerResult> respondReplacementOffer({
    required String offerId,
    required bool accept,
    required String idempotencyKey,
  });
}
