import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/listings/domain/results_page.dart';

/// Scriptable [ListingsRepository] for widget and Cubit tests.
///
/// Queue one response per expected call on the matching `*Responses` field:
/// a plain value, a `Future` (e.g. `completer.future` to control timing), or
/// an [AppFailure] to throw. Calls are recorded in [calls] with their
/// arguments. Methods without a queued response return an empty default.
final class FakeListingsRepository implements ListingsRepository {
  final List<String> calls = [];

  final List<Object> homeFeedResponses = [];
  final List<Object> searchResponses = [];
  final List<Object> countResponses = [];
  final List<Object> locationResponses = [];
  final List<Object> referenceDataResponses = [];
  final List<Object> propertyResponses = [];
  final List<Object> unavailableNightsResponses = [];
  final List<Object> reviewsResponses = [];

  Future<T> _next<T>(List<Object> responses, T fallback) async {
    final entry = responses.isEmpty ? fallback : responses.removeAt(0);
    if (entry is AppFailure) throw entry;
    if (entry is Future<T>) return entry;
    return entry as T;
  }

  @override
  Future<HomeFeed> homeFeed() async {
    calls.add('homeFeed()');
    return _next<HomeFeed>(homeFeedResponses, _emptyFeed());
  }

  @override
  Future<ResultsPage> searchProperties(
    PropertySearchParams params, {
    String? cursor,
    int limit = 20,
  }) async {
    calls.add(
      'searchProperties(cursor: $cursor, limit: $limit, params: $params)',
    );
    return _next<ResultsPage>(
      searchResponses,
      const ResultsPage(items: [], nextCursor: null, totalCount: 0),
    );
  }

  @override
  Future<int> countProperties(PropertySearchParams params) async {
    calls.add('countProperties(params: $params)');
    return _next<int>(countResponses, 0);
  }

  @override
  Future<List<LocationSuggestion>> searchLocations(String query) async {
    calls.add('searchLocations($query)');
    return _next<List<LocationSuggestion>>(locationResponses, const []);
  }

  @override
  Future<ReferenceData> referenceData() async {
    calls.add('referenceData()');
    return _next<ReferenceData>(referenceDataResponses, _emptyReference());
  }

  @override
  Future<PropertyDetails> property(String id) async {
    calls.add('property($id)');
    return _next<PropertyDetails>(propertyResponses, _emptyProperty(id));
  }

  @override
  Future<Set<DateOnly>> unavailableNights(
    String id,
    DateOnly from,
    DateOnly to,
  ) async {
    calls.add('unavailableNights($id, $from, $to)');
    return _next<Set<DateOnly>>(unavailableNightsResponses, const {});
  }

  @override
  Future<ReviewsPage> reviews(
    String id, {
    String? cursor,
    int limit = 20,
  }) async {
    calls.add('reviews($id, cursor: $cursor, limit: $limit)');
    return _next<ReviewsPage>(
      reviewsResponses,
      const ReviewsPage(items: [], nextCursor: null),
    );
  }
}

HomeFeed _emptyFeed() => HomeFeed(
  referenceVersion: 'test',
  areas: const FeedSectionReady(<AreaTile>[]),
  suggested: const FeedSectionReady(<ListingCard>[]),
  newest: const FeedSectionReady(<ListingCard>[]),
  upcomingBooking: const FeedSectionReady(null),
  fetchedAt: DateTime.utc(2026),
);

ReferenceData _emptyReference() => ReferenceData(
  version: 'test',
  amenities: const [],
  propertyTypes: const [],
  priceMin: Money(0),
  priceMax: Money(0),
  priceStep: Money(5000),
);

PropertyDetails _emptyProperty(String id) => PropertyDetails(
  id: id,
  title: 'شقة تجريبية',
  description: '',
  propertyType: 'apartment',
  areaName: '',
  cityName: '',
  governorateName: '',
  addressText: null,
  images: const [],
  areaSqm: null,
  bedrooms: 2,
  bathrooms: 1,
  maxGuests: 4,
  amenities: const [],
  rules: const StayRules(
    checkInTime: '14:00',
    checkOutTime: '12:00',
    visitorsAllowed: false,
    maxVisitors: null,
    houseRules: null,
  ),
  policy: const PolicySummary(
    depositType: DepositType.full,
    depositPercentBp: null,
    depositAmount: null,
    freeCancellationHours: 24,
  ),
  nightlyPrice: Money(100000),
  ratingAvg: null,
  reviewCount: 0,
  latestReviews: const [],
  termsVersion: 'test-v1',
);
