import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';

/// What the verification screen shows, computed only from the server's
/// `status` and `payment_state` (data-model §6). Link parameters are never
/// an input (FR-016).
enum VerificationOutcome { success, conflict, failed, waiting }

VerificationOutcome verificationOutcomeFor(BookingDetails details) =>
    switch (details.status) {
      // Any owner decision — including a rejection — ends the wait; the
      // booking details screen explains the outcome.
      BookingStatus.awaitingOwner ||
      BookingStatus.confirmed ||
      BookingStatus.checkedIn ||
      BookingStatus.completed ||
      BookingStatus.rejected ||
      BookingStatus.expired ||
      BookingStatus.cancelled ||
      BookingStatus.noShow => VerificationOutcome.success,
      BookingStatus.paymentConflict => VerificationOutcome.conflict,
      BookingStatus.paymentPending =>
        details.paymentState == PaymentState.failed
            ? VerificationOutcome.failed
            : VerificationOutcome.waiting,
      BookingStatus.paymentVerifying ||
      BookingStatus.unknown => VerificationOutcome.waiting,
      // The attempt was never completed and nothing is charged: a restart.
      BookingStatus.abandoned => VerificationOutcome.failed,
    };
