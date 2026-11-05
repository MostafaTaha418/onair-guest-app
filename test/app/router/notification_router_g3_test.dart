import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/notification_router.dart';

void main() {
  const id = 'b0000000-0000-4000-8000-000000000020';
  const pay = 'c0000000-0000-4000-8000-000000000099';
  const claim = 'e0000000-0000-4000-8000-000000000001';

  test('routes every G3 notification target', () {
    expect(
      NotificationRouter.locationFor('payment.remaining_due', 'booking', id),
      '/bookings/$id/remaining-payment',
    );
    expect(
      NotificationRouter.locationFor(
        'cash.confirmation_requested',
        'booking',
        id,
      ),
      '/bookings/$id/cash-confirm',
    );
    expect(
      NotificationRouter.locationFor(
        'cash.payment_confirmed',
        'payment',
        pay,
        params: {'booking_id': id},
      ),
      '/bookings/$id/receipts/$pay',
    );
    expect(
      NotificationRouter.locationFor('cash.payment_confirmed', '', pay),
      '/bookings',
    );
    expect(
      NotificationRouter.locationFor(
        'damage.claim_opened',
        'damage_claim',
        claim,
      ),
      '/damage-claims/$claim',
    );
    expect(
      NotificationRouter.locationFor('damage.resolved', '', claim),
      '/damage-claims/$claim',
    );
    expect(
      NotificationRouter.locationFor(
        'booking.replacement_offered',
        'booking',
        id,
      ),
      '/bookings/$id?focus=offer',
    );
    expect(
      NotificationRouter.locationFor('refund.verified', 'booking', id),
      '/bookings/$id?focus=payments',
    );
    expect(
      NotificationRouter.locationFor('stay.completed', 'booking', id),
      '/bookings/$id',
    );
    expect(
      NotificationRouter.locationFor(
        'damage.claim_opened',
        'damage_claim',
        'not-a-uuid',
      ),
      '/bookings',
    );
  });
}
