import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/router/routes.dart';

void main() {
  const id = 'b0000000-0000-4000-8000-000000000020';
  const pay = 'c0000000-0000-4000-8000-000000000099';
  const claim = 'e0000000-0000-4000-8000-000000000001';

  test('G3 linkable routes are registered and account gated', () {
    for (final path in [
      '/bookings/$id/cash-confirm',
      '/bookings/$id/receipts/$pay',
      '/damage-claims/$claim',
    ]) {
      expect(AppRoutes.isRegisteredLocation(path), isTrue, reason: path);
      expect(AppRoutes.requiresAccount(path), isTrue, reason: path);
      expect(AppRoutes.isLinkablePath(path), isTrue, reason: path);
    }
  });

  test('cancellation is registered but never linkable', () {
    const path = '/bookings/$id/cancel';
    expect(AppRoutes.isRegisteredLocation(path), isTrue);
    expect(AppRoutes.requiresAccount(path), isTrue);
    expect(AppRoutes.isLinkablePath(path), isFalse);
  });

  test('rejects a non-uuid in every identifier position', () {
    for (final path in [
      '/bookings/not-a-uuid/cash-confirm',
      '/bookings/not-a-uuid/receipts/$pay',
      '/bookings/$id/receipts/not-a-uuid',
      '/bookings/not-a-uuid/cancel',
      '/bookings/not-a-uuid/damage-claim/$claim',
      '/bookings/$id/damage-claim/not-a-uuid',
      '/damage-claims/not-a-uuid',
    ]) {
      expect(AppRoutes.isRegisteredLocation(path), isFalse, reason: path);
    }
  });

  test('builders return exact G3 locations', () {
    expect(
      AppRoutes.remainingPayment(id),
      '/bookings/$id/remaining-payment',
    );
    expect(AppRoutes.cashConfirm(id), '/bookings/$id/cash-confirm');
    expect(AppRoutes.receipt(id, pay), '/bookings/$id/receipts/$pay');
    expect(AppRoutes.cancelBooking(id), '/bookings/$id/cancel');
    expect(
      AppRoutes.damageClaim(id, claim),
      '/bookings/$id/damage-claim/$claim',
    );
    expect(AppRoutes.damageClaimResolver(claim), '/damage-claims/$claim');
    expect(
      AppRoutes.bookingDetailsFocus(id, 'offer'),
      '/bookings/$id?focus=offer',
    );
  });
}
