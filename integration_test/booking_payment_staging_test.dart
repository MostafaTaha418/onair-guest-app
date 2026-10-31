import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';

import 'helpers/staging.dart';

/// T102: the real Kashier round trip against Staging (AC-023, AC-015,
/// AC-016). Skips in mock mode and until the Kashier test account exists.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('one attempt key opens one booking, and the charged amount '
      'equals the quote', (tester) async {
    if (!skipUnlessStaging()) return;
    final propertyId = seedValue('DEPOSIT_PROPERTY');
    final harness = await bootStaging();

    // The quote pins every amount; the app never sends one (Constitution III).
    final today = CairoTime.today();
    final quote = await harness.flow.quote(
      propertyId: propertyId,
      stay: StayRange(today.addDays(14), today.addDays(17)),
      guests: 2,
      termsHash: (await harness.listings.property(propertyId)).termsVersion,
    );

    // AC-023: the same attempt key twice returns the same booking.
    const attemptKey = 'staging-test-attempt-key';
    final first = await harness.flow.startPayment(
      quoteId: quote.quoteId,
      termsHash: quote.termsHash,
      attemptKey: attemptKey,
    );
    final second = await harness.flow.startPayment(
      quoteId: quote.quoteId,
      termsHash: quote.termsHash,
      attemptKey: attemptKey,
    );
    expect(second.bookingId, first.bookingId);

    // The skip reason and manual card instructions must reach the console
    // of a device run.
    // ignore: avoid_print
    print(
      'Open the Kashier page and complete the test card for booking '
      '${first.bookingId} (or run the provider test automation): '
      '${first.paymentUrl}',
    );

    // AC-015: success arrives only when the server says so — poll until the
    // booking leaves payment_verifying (the tester completes the card in
    // parallel; 15 minutes is the practical upper bound for a manual run).
    var details = await harness.bookings.getBooking(first.bookingId);
    final deadline = DateTime.now().toUtc().add(
      const Duration(minutes: 15),
    );
    while (details.status == BookingStatus.paymentVerifying ||
        details.status == BookingStatus.paymentPending) {
      if (DateTime.now().toUtc().isAfter(deadline)) {
        fail('the booking never left payment_verifying within 15 minutes');
      }
      await Future<void>.delayed(const Duration(seconds: 15));
      details = await harness.bookings.getBooking(first.bookingId);
    }
    expect(details.status, BookingStatus.confirmed);

    // AC-016: the charged amount is exactly the quote's pay-now.
    expect(details.paid.amountMinor, quote.payNow.amountMinor);
  });
}
