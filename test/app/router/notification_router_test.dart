import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/notification_router.dart';
import 'package:on_air/app/router/routes.dart';

const _uuid = 'b0000000-0000-4000-8000-000000000001';

/// Every booking-scoped row of contracts/app-routes-g2.md §4.
const _bookingScopedKeys = [
  'booking.request_received',
  'booking.confirmed',
  'booking.rejected',
  'booking.expired',
  'booking.payment_conflict',
  'booking.cancelled_by_guest',
  'booking.cancelled_by_platform',
  'booking.no_show_recorded',
  'booking.reopened',
  'booking.replacement_offered',
  'payment.failed',
  'payment.remaining_paid',
  'payment.remaining_due',
  'cash.payment_confirmed',
  'cash.confirmation_requested',
  'stay.checkin_reminder',
  'stay.checkout_reminder',
  'stay.host_handover_confirmed',
  'stay.checked_in',
  'stay.completed',
  'refund.requested',
  'refund.executed',
  'refund.verified',
  'damage.claim_opened',
  'damage.resolved',
  'review.approved',
  'review.rejected',
];

void main() {
  test('every booking-scoped type opens the booking', () {
    for (final typeKey in _bookingScopedKeys) {
      expect(
        NotificationRouter.locationFor(typeKey, 'booking', _uuid),
        AppRoutes.bookingDetails(_uuid),
        reason: typeKey,
      );
    }
  });

  test('support types open the support entry', () {
    expect(
      NotificationRouter.locationFor('support.staff_replied', '', _uuid),
      AppRoutes.supportNew,
    );
    expect(
      NotificationRouter.locationFor('support.case_resolved', '', _uuid),
      AppRoutes.supportNew,
    );
  });

  test('account types open the account screen', () {
    expect(
      NotificationRouter.locationFor('account.phone_changed', '', _uuid),
      AppRoutes.account,
    );
    expect(
      NotificationRouter.locationFor('account.password_changed', '', _uuid),
      AppRoutes.account,
    );
  });

  test('an unknown type falls back to the bookings tab', () {
    expect(
      NotificationRouter.locationFor('something.new', 'booking', _uuid),
      AppRoutes.bookings,
    );
  });

  test('an invalid booking id falls back to the bookings tab', () {
    expect(
      NotificationRouter.locationFor('booking.confirmed', 'booking', 'x'),
      AppRoutes.bookings,
    );
    expect(
      NotificationRouter.locationFor('payment.failed', 'booking', ''),
      AppRoutes.bookings,
    );
  });

  test('entityType is not used for routing in G2 (T083)', () {
    // Accepted for later phases: only the type prefix and the id decide.
    expect(
      NotificationRouter.locationFor('booking.confirmed', 'weird', _uuid),
      AppRoutes.bookingDetails(_uuid),
    );
  });
}
