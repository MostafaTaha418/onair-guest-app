import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/routes.dart';

void main() {
  const uuid = 'b0000000-0000-4000-8000-000000000001';

  test('the G2 routes are registered and need an account', () {
    expect(AppRoutes.isRegisteredLocation('/notifications'), isTrue);
    expect(
      AppRoutes.isRegisteredLocation('/book/$uuid/verify'),
      isTrue,
    );
    expect(
      AppRoutes.isRegisteredLocation('/book/$uuid/summary'),
      isTrue,
    );
    expect(AppRoutes.requiresAccount('/notifications'), isTrue);
    expect(AppRoutes.requiresAccount('/book/$uuid/verify'), isTrue);
    expect(AppRoutes.requiresAccount('/book/$uuid/summary'), isTrue);
  });

  test('a non-uuid property id is not a registered booking route', () {
    expect(AppRoutes.isRegisteredLocation('/book/not-a-uuid/summary'), isFalse);
    expect(AppRoutes.isRegisteredLocation('/book/not-a-uuid/verify'), isFalse);
  });

  test('the booking flow routes stay non-linkable', () {
    expect(AppRoutes.isLinkablePath('/book/$uuid/summary'), isFalse);
    expect(AppRoutes.isLinkablePath('/book/$uuid/verify'), isFalse);
    expect(AppRoutes.isLinkablePath('/book/$uuid/dates'), isFalse);
    expect(AppRoutes.isLinkablePath(AppRoutes.paymentReturnPath), isTrue);
  });

  test('the builders produce the exact locations', () {
    expect(
      AppRoutes.bookingVerify(uuid, returnTo: 'dates'),
      '/book/$uuid/verify?returnTo=dates',
    );
    expect(
      AppRoutes.bookingSummary(uuid),
      '/book/$uuid/summary',
    );
    expect(
      AppRoutes.bookingDetails(uuid),
      '/bookings/$uuid',
    );
    expect(
      AppRoutes.paymentReturn(bookingId: uuid),
      '/payment/return?booking=$uuid',
    );
    expect(AppRoutes.paymentReturn(), '/payment/return');
    expect(
      AppRoutes.bookingsTab('past'),
      '/bookings?tab=past',
    );
  });

  test('isUuidV4 validates only v4 shapes', () {
    expect(AppRoutes.isUuidV4(uuid), isTrue);
    expect(AppRoutes.isUuidV4('not-a-uuid'), isFalse);
    // A v1 uuid is not accepted.
    expect(
      AppRoutes.isUuidV4('c0000000-1000-1000-8000-000000000001'),
      isFalse,
    );
  });
}
