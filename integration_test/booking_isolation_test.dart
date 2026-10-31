import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';

import 'helpers/staging.dart';

/// T104: one guest never sees another guest's booking (SC-007, AC-007). A
/// foreign id gives the same neutral NOT_FOUND as a missing one, and no tab
/// lists it. Skips in mock mode and until the Staging seed carries the
/// foreign booking.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a foreign booking is invisible to another guest', (
    tester,
  ) async {
    if (!skipUnlessStaging()) return;
    final foreignId = seedValue('FOREIGN_BOOKING');
    // bootStaging signs the seeded guest (A) in; the foreign booking belongs
    // to guest B.
    final harness = await bootStaging();

    // AC-007: the same NOT_FOUND as a missing booking.
    await expectLater(
      harness.bookings.getBooking(foreignId),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.error.code,
          'code',
          ErrorCode.notFound,
        ),
      ),
    );

    // SC-007: no tab lists it.
    for (final tab in BookingTab.values) {
      final page = await harness.bookings.listBookings(tab);
      expect(
        page.items.where((booking) => booking.id == foreignId),
        isEmpty,
        reason: 'tab ${tab.wire} leaked a foreign booking',
      );
    }
  });
}
