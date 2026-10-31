import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/notifications/presentation/notification_texts.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  test('every type key has its own title and body (Appendix A)', () {
    final texts = {
      'booking.request_received': (
        l10n.notifBookingRequestReceivedTitle,
        l10n.notifBookingRequestReceivedBody,
      ),
      'booking.confirmed': (
        l10n.notifBookingConfirmedTitle,
        l10n.notifBookingConfirmedBody,
      ),
      'booking.rejected': (
        l10n.notifBookingRejectedTitle,
        l10n.notifBookingRejectedBody,
      ),
      'booking.expired': (
        l10n.notifBookingExpiredTitle,
        l10n.notifBookingExpiredBody,
      ),
      'booking.payment_conflict': (
        l10n.notifBookingPaymentConflictTitle,
        l10n.notifBookingPaymentConflictBody,
      ),
      'booking.cancelled_by_guest': (
        l10n.notifBookingCancelledByGuestTitle,
        l10n.notifBookingCancelledByGuestBody,
      ),
      'booking.cancelled_by_platform': (
        l10n.notifBookingCancelledByPlatformTitle,
        l10n.notifBookingCancelledByPlatformBody,
      ),
      'booking.replacement_offered': (
        l10n.notifBookingReplacementOfferedTitle,
        l10n.notifBookingReplacementOfferedBody,
      ),
      'booking.no_show_recorded': (
        l10n.notifBookingNoShowRecordedTitle,
        l10n.notifBookingNoShowRecordedBody,
      ),
      'booking.reopened': (
        l10n.notifBookingReopenedTitle,
        l10n.notifBookingReopenedBody,
      ),
      'payment.failed': (
        l10n.notifPaymentFailedTitle,
        l10n.notifPaymentFailedBody,
      ),
      'payment.remaining_due': (
        l10n.notifPaymentRemainingDueTitle,
        l10n.notifPaymentRemainingDueBody,
      ),
      'payment.remaining_paid': (
        l10n.notifPaymentRemainingPaidTitle,
        l10n.notifPaymentRemainingPaidBody,
      ),
      'cash.confirmation_requested': (
        l10n.notifCashConfirmationRequestedTitle,
        l10n.notifCashConfirmationRequestedBody,
      ),
      'cash.payment_confirmed': (
        l10n.notifCashPaymentConfirmedTitle,
        l10n.notifCashPaymentConfirmedBody,
      ),
      'stay.checkin_reminder': (
        l10n.notifStayCheckinReminderTitle,
        l10n.notifStayCheckinReminderBody,
      ),
      'stay.checkout_reminder': (
        l10n.notifStayCheckoutReminderTitle,
        l10n.notifStayCheckoutReminderBody,
      ),
      'stay.host_handover_confirmed': (
        l10n.notifStayHostHandoverConfirmedTitle,
        l10n.notifStayHostHandoverConfirmedBody,
      ),
      'stay.checked_in': (
        l10n.notifStayCheckedInTitle,
        l10n.notifStayCheckedInBody,
      ),
      'stay.completed': (
        l10n.notifStayCompletedTitle,
        l10n.notifStayCompletedBody,
      ),
      'damage.claim_opened': (
        l10n.notifDamageClaimOpenedTitle,
        l10n.notifDamageClaimOpenedBody,
      ),
      'damage.resolved': (
        l10n.notifDamageResolvedTitle,
        l10n.notifDamageResolvedBody,
      ),
      'refund.requested': (
        l10n.notifRefundRequestedTitle,
        l10n.notifRefundRequestedBody,
      ),
      'refund.executed': (
        l10n.notifRefundExecutedTitle,
        l10n.notifRefundExecutedBody,
      ),
      'refund.verified': (
        l10n.notifRefundVerifiedTitle,
        l10n.notifRefundVerifiedBody,
      ),
      'support.staff_replied': (
        l10n.notifSupportStaffRepliedTitle,
        l10n.notifSupportStaffRepliedBody,
      ),
      'support.case_resolved': (
        l10n.notifSupportCaseResolvedTitle,
        l10n.notifSupportCaseResolvedBody,
      ),
      'review.approved': (
        l10n.notifReviewApprovedTitle,
        l10n.notifReviewApprovedBody,
      ),
      'review.rejected': (
        l10n.notifReviewRejectedTitle,
        l10n.notifReviewRejectedBody,
      ),
      'account.phone_changed': (
        l10n.notifAccountPhoneChangedTitle,
        l10n.notifAccountPhoneChangedBody,
      ),
      'account.password_changed': (
        l10n.notifAccountPasswordChangedTitle,
        l10n.notifAccountPasswordChangedBody,
      ),
    };
    expect(texts, hasLength(31));
    for (final entry in texts.entries) {
      final text = notificationText(entry.key, l10n);
      expect(text.title, entry.value.$1, reason: '${entry.key} title');
      expect(text.body, entry.value.$2, reason: '${entry.key} body');
    }
  });

  test('an unknown type gets the generic pair', () {
    final text = notificationText('something.new', l10n);
    expect(text.title, l10n.notifGenericTitle);
    expect(text.body, l10n.notifGenericBody);
  });
}
