import 'package:on_air/l10n/generated/app_localizations.dart';

/// One notification's display text: one title + one body per type, no
/// placeholders (Appendix A «Notification texts»).
typedef NotificationText = ({String title, String body});

/// The title and body for a notification [typeKey]; anything unknown gets
/// the generic pair.
NotificationText notificationText(String typeKey, AppLocalizations l10n) =>
    switch (typeKey) {
      'booking.request_received' => (
        title: l10n.notifBookingRequestReceivedTitle,
        body: l10n.notifBookingRequestReceivedBody,
      ),
      'booking.confirmed' => (
        title: l10n.notifBookingConfirmedTitle,
        body: l10n.notifBookingConfirmedBody,
      ),
      'booking.rejected' => (
        title: l10n.notifBookingRejectedTitle,
        body: l10n.notifBookingRejectedBody,
      ),
      'booking.expired' => (
        title: l10n.notifBookingExpiredTitle,
        body: l10n.notifBookingExpiredBody,
      ),
      'booking.payment_conflict' => (
        title: l10n.notifBookingPaymentConflictTitle,
        body: l10n.notifBookingPaymentConflictBody,
      ),
      'booking.cancelled_by_guest' => (
        title: l10n.notifBookingCancelledByGuestTitle,
        body: l10n.notifBookingCancelledByGuestBody,
      ),
      'booking.cancelled_by_platform' => (
        title: l10n.notifBookingCancelledByPlatformTitle,
        body: l10n.notifBookingCancelledByPlatformBody,
      ),
      'booking.replacement_offered' => (
        title: l10n.notifBookingReplacementOfferedTitle,
        body: l10n.notifBookingReplacementOfferedBody,
      ),
      'booking.no_show_recorded' => (
        title: l10n.notifBookingNoShowRecordedTitle,
        body: l10n.notifBookingNoShowRecordedBody,
      ),
      'booking.reopened' => (
        title: l10n.notifBookingReopenedTitle,
        body: l10n.notifBookingReopenedBody,
      ),
      'payment.failed' => (
        title: l10n.notifPaymentFailedTitle,
        body: l10n.notifPaymentFailedBody,
      ),
      'payment.remaining_due' => (
        title: l10n.notifPaymentRemainingDueTitle,
        body: l10n.notifPaymentRemainingDueBody,
      ),
      'payment.remaining_paid' => (
        title: l10n.notifPaymentRemainingPaidTitle,
        body: l10n.notifPaymentRemainingPaidBody,
      ),
      'cash.confirmation_requested' => (
        title: l10n.notifCashConfirmationRequestedTitle,
        body: l10n.notifCashConfirmationRequestedBody,
      ),
      'cash.payment_confirmed' => (
        title: l10n.notifCashPaymentConfirmedTitle,
        body: l10n.notifCashPaymentConfirmedBody,
      ),
      'stay.checkin_reminder' => (
        title: l10n.notifStayCheckinReminderTitle,
        body: l10n.notifStayCheckinReminderBody,
      ),
      'stay.checkout_reminder' => (
        title: l10n.notifStayCheckoutReminderTitle,
        body: l10n.notifStayCheckoutReminderBody,
      ),
      'stay.host_handover_confirmed' => (
        title: l10n.notifStayHostHandoverConfirmedTitle,
        body: l10n.notifStayHostHandoverConfirmedBody,
      ),
      'stay.checked_in' => (
        title: l10n.notifStayCheckedInTitle,
        body: l10n.notifStayCheckedInBody,
      ),
      'stay.completed' => (
        title: l10n.notifStayCompletedTitle,
        body: l10n.notifStayCompletedBody,
      ),
      'damage.claim_opened' => (
        title: l10n.notifDamageClaimOpenedTitle,
        body: l10n.notifDamageClaimOpenedBody,
      ),
      'damage.resolved' => (
        title: l10n.notifDamageResolvedTitle,
        body: l10n.notifDamageResolvedBody,
      ),
      'refund.requested' => (
        title: l10n.notifRefundRequestedTitle,
        body: l10n.notifRefundRequestedBody,
      ),
      'refund.executed' => (
        title: l10n.notifRefundExecutedTitle,
        body: l10n.notifRefundExecutedBody,
      ),
      'refund.verified' => (
        title: l10n.notifRefundVerifiedTitle,
        body: l10n.notifRefundVerifiedBody,
      ),
      'support.staff_replied' => (
        title: l10n.notifSupportStaffRepliedTitle,
        body: l10n.notifSupportStaffRepliedBody,
      ),
      'support.case_resolved' => (
        title: l10n.notifSupportCaseResolvedTitle,
        body: l10n.notifSupportCaseResolvedBody,
      ),
      'review.approved' => (
        title: l10n.notifReviewApprovedTitle,
        body: l10n.notifReviewApprovedBody,
      ),
      'review.rejected' => (
        title: l10n.notifReviewRejectedTitle,
        body: l10n.notifReviewRejectedBody,
      ),
      'account.phone_changed' => (
        title: l10n.notifAccountPhoneChangedTitle,
        body: l10n.notifAccountPhoneChangedBody,
      ),
      'account.password_changed' => (
        title: l10n.notifAccountPasswordChangedTitle,
        body: l10n.notifAccountPasswordChangedBody,
      ),
      _ => (title: l10n.notifGenericTitle, body: l10n.notifGenericBody),
    };
