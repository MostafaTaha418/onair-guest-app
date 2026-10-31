import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/bookings/data/mock_home_feed_with_bookings.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';

import '../../../helpers/fake_booking_backend.dart';

void main() {
  late FakeBookingBackend backend;
  late MockHomeFeedWithBookings listings;

  setUp(() {
    backend = FakeBookingBackend();
    listings = MockHomeFeedWithBookings(
      inner: backend.listings,
      server: backend.server,
    );
  });

  tearDown(() {
    backend.dispose();
  });

  test(
    'the nearest confirmed fixture booking fills the upcoming card',
    () async {
      // The checked-in stay starting 2026-10-29 is the nearest of the
      // fixture's confirmed/checked-in bookings (server order, nearest
      // first).
      final feed = await listings.homeFeed();
      final upcoming = feed.upcomingBooking;
      expect(upcoming, isA<FeedSectionReady<UpcomingBookingCard?>>());
      final card = (upcoming as FeedSectionReady<UpcomingBookingCard?>).value;
      expect(card, isNotNull);
      expect(card!.bookingId, 'b0000000-0000-4000-8000-000000000004');
      expect(card.propertyTitle, 'شقة 3 غرف');
      expect(card.status, 'checked_in');
    },
  );

  test('without a confirmed booking the card stays empty', () async {
    // Warm the server's in-memory bookings; setStatus mutates them.
    await backend.server.listBookings(BookingTab.current);
    backend.server.setStatus(
      'b0000000-0000-4000-8000-000000000001',
      'cancelled',
    );
    backend.server.setStatus(
      'b0000000-0000-4000-8000-000000000004',
      'cancelled',
    );
    final feed = await listings.homeFeed();
    final upcoming = feed.upcomingBooking;
    expect(upcoming, isA<FeedSectionReady<UpcomingBookingCard?>>());
    expect((upcoming as FeedSectionReady<UpcomingBookingCard?>).value, isNull);
  });

  test('everything else still comes from the wrapped listings mock', () async {
    final feed = await listings.homeFeed();
    final raw = await backend.listings.homeFeed();
    expect(feed.suggested, raw.suggested);
    expect(feed.newest, raw.newest);
    expect(feed.areas, raw.areas);
    expect(feed.referenceVersion, raw.referenceVersion);
    expect(
      await listings.property('00000000-0000-4000-8000-00000000001f'),
      await backend.listings.property(
        '00000000-0000-4000-8000-00000000001f',
      ),
    );
  });
}
