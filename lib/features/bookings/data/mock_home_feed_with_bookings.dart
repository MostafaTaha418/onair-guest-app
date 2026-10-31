import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/listings/domain/results_page.dart';

/// Mock mode only (FR-026): fills the Home feed's `upcoming_booking` from
/// the mock booking server, so the Home card shows the guest's nearest
/// upcoming confirmed booking exactly like the real backend's home feed.
final class MockHomeFeedWithBookings implements ListingsRepository {
  const MockHomeFeedWithBookings({required this.inner, required this.server});

  final ListingsRepository inner;
  final MockBookingServer server;

  ListingsRepository get _inner => inner;
  MockBookingServer get _server => server;

  @override
  Future<HomeFeed> homeFeed() async {
    final feed = await _inner.homeFeed();
    if (feed.upcomingBooking is! FeedSectionReady<UpcomingBookingCard?>) {
      return feed;
    }
    final page = await _server.listBookings(BookingTab.current);
    for (final booking in page.items) {
      if (booking.status == BookingStatus.confirmed ||
          booking.status == BookingStatus.checkedIn) {
        // The server order is already nearest first: the first confirmed
        // booking is the one the real backend would pick.
        return HomeFeed(
          referenceVersion: feed.referenceVersion,
          areas: feed.areas,
          suggested: feed.suggested,
          newest: feed.newest,
          upcomingBooking: FeedSectionReady(
            UpcomingBookingCard(
              bookingId: booking.id,
              propertyTitle: booking.title,
              checkIn: booking.stay.checkIn,
              checkOut: booking.stay.checkOut,
              status: booking.status.wire,
            ),
          ),
          fetchedAt: feed.fetchedAt,
        );
      }
    }
    return feed;
  }

  @override
  Future<ResultsPage> searchProperties(
    PropertySearchParams params, {
    String? cursor,
    int limit = 20,
  }) => _inner.searchProperties(params, cursor: cursor, limit: limit);

  @override
  Future<int> countProperties(PropertySearchParams params) =>
      _inner.countProperties(params);

  @override
  Future<List<LocationSuggestion>> searchLocations(String query) =>
      _inner.searchLocations(query);

  @override
  Future<ReferenceData> referenceData() => _inner.referenceData();

  @override
  Future<PropertyDetails> property(String id) => _inner.property(id);

  @override
  Future<Set<DateOnly>> unavailableNights(
    String id,
    DateOnly from,
    DateOnly to,
  ) => _inner.unavailableNights(id, from, to);

  @override
  Future<ReviewsPage> reviews(String id, {String? cursor, int limit = 20}) =>
      _inner.reviews(id, cursor: cursor, limit: limit);
}
