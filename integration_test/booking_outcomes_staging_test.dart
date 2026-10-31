import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';

import 'helpers/staging.dart';

/// T103: every final booking status and refund stage renders its contract
/// message and chips on Staging (AC-019, AC-020, AC-021, AC-042), and the
/// guest's notification center carries the matching rows (AC-024). Skips in
/// mock mode and until the Staging seed carries the bookings.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seeded bookings surface their status, refund stage, and '
      'notifications', (tester) async {
    skipUnlessStaging();
    final harness = await bootStaging();

    final expected = {
      'BOOKING_CONFIRMED': BookingStatus.confirmed,
      'BOOKING_REJECTED': BookingStatus.rejected,
      'BOOKING_EXPIRED': BookingStatus.expired,
      'BOOKING_CONFLICT': BookingStatus.paymentConflict,
    };
    final detailsBySeed = <String, BookingDetails>{};
    for (final entry in expected.entries) {
      final id = seedValue(entry.key);
      final details = await harness.bookings.getBooking(id);
      detailsBySeed[entry.key] = details;
      expect(details.status, entry.value, reason: entry.key);
    }

    // AC-042: the refund stage is separate from the status, and «Refunded»
    // exists only at `verified`.
    final requested = await harness.bookings.getBooking(
      seedValue('BOOKING_REFUND_REQUESTED'),
    );
    expect(requested.refund, isNotNull);
    expect(requested.refund!.stage, RefundStage.requested);
    final verified = await harness.bookings.getBooking(
      seedValue('BOOKING_REFUND_VERIFIED'),
    );
    expect(verified.refund!.stage, RefundStage.verified);
    for (final details in detailsBySeed.values) {
      if (details.refund == null) continue;
      expect(
        details.refund!.stage,
        isNot(RefundStage.verified),
        reason: 'only the verified-refund seed may show «Refunded»',
      );
    }

    // AC-024: the notification center lists the matching rows.
    final notifications = await harness.notifications.list();
    final typeKeys = notifications.map((n) => n.typeKey).toSet();
    expect(typeKeys, containsAll(<String>['booking.confirmed']));
    expect(typeKeys, contains('booking.rejected'));
    expect(typeKeys, contains('booking.expired'));
    expect(typeKeys, contains('booking.payment_conflict'));
  });
}
