import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/data/supabase_listings_repository.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

void main() {
  final recorded = <(String, Map<String, dynamic>)>[];

  /// Returns canned RPC responses in the shapes of
  /// `specs/002-guest-discovery/contracts/supabase-discovery.md`.
  Future<dynamic> fakeRpc(String function, Map<String, dynamic> params) async {
    recorded.add((function, params));
    return switch (function) {
      'guest_search_properties' => {
        'items': <Map<String, dynamic>>[
          const {
            'id': '00000000-0000-4000-8000-000000000001',
            'title': 'شقة',
            'property_type': 'apartment',
            'area_name': 'التجمع الخامس',
            'city_name': 'القاهرة الجديدة',
            'nightly_price_minor': 150000,
            'currency': 'EGP',
            'rating_avg': 4.5,
            'review_count': 3,
          },
        ],
        'next_cursor': null,
        'total_count': 1,
      },
      'guest_home_feed' => {
        'reference_version': 'v1',
        'areas': {
          'status': 'ready',
          'items': <Map<String, dynamic>>[],
        },
        'suggested': {
          'status': 'ready',
          'items': <Map<String, dynamic>>[],
        },
        'newest': {
          'status': 'ready',
          'items': <Map<String, dynamic>>[],
        },
        'upcoming_booking': {'status': 'ready', 'item': null},
      },
      'guest_get_property' => {
        'id': '00000000-0000-4000-8000-000000000001',
        'title': 'شقة',
        'description': 'وصف',
        'property_type': 'apartment',
        'governorate_name': 'القاهرة',
        'city_name': 'القاهرة الجديدة',
        'area_name': 'التجمع الخامس',
        'address_text': null,
        'images': <Map<String, dynamic>>[],
        'bedrooms': 3,
        'bathrooms': 2,
        'max_guests': 6,
        'amenities': <Map<String, dynamic>>[],
        'rules': {
          'check_in_time': '14:00',
          'check_out_time': '12:00',
          'visitors_allowed': true,
          'max_visitors': null,
          'house_rules': null,
        },
        'policy': {
          'deposit_type': 'percent',
          'deposit_percent_bp': 2500,
          'deposit_amount_minor': null,
          'free_cancellation_hours': 72,
        },
        'nightly_price_minor': 150000,
        'currency': 'EGP',
        'rating_avg': null,
        'review_count': 0,
        'latest_reviews': <Map<String, dynamic>>[],
        'terms_version': 'sha256:abc',
      },
      'guest_get_property_unavailable_dates' => <String>[
        '2026-11-02',
        '2026-11-03',
      ],
      'guest_list_property_reviews' => {
        'items': <Map<String, dynamic>>[
          const {
            'id': '00000000-0000-4000-8000-0000000000aa',
            'rating': 5,
            'comment': 'جميل',
            'created_on': '2026-09-14',
            'reviewer_short_name': 'أحمد م.',
          },
        ],
        'next_cursor': null,
      },
      'guest_search_locations' => <Map<String, dynamic>>[
        const {
          'id': '00000000-0000-4000-8000-0000000000bb',
          'level': 'area',
          'name': 'التجمع الخامس',
          'parent_label': 'القاهرة الجديدة',
          'listing_count': 42,
        },
      ],
      'guest_get_reference_data' => {
        'version': 'v1',
        'amenities': <Map<String, dynamic>>[],
        'property_types': <Map<String, dynamic>>[],
        'price_bounds': {'min_minor': 50000, 'max_minor': 1500000},
        'price_step_minor': 5000,
      },
      _ => throw StateError('Unexpected function $function'),
    };
  }

  late SupabaseListingsRepository repo;

  setUp(() {
    recorded.clear();
    repo = SupabaseListingsRepository(rpc: fakeRpc);
  });

  test(
    'searchProperties calls guest_search_properties with p_* parameters',
    () async {
      final page = await repo.searchProperties(
        PropertySearchParams(
          locationId: '00000000-0000-4000-8000-0000000000cc',
          stay: StayRange(DateOnly(2026, 11, 20), DateOnly(2026, 11, 23)),
          guests: 4,
          priceMin: Money(50000),
          amenityKeys: const {'wifi'},
          sort: SearchSort.priceAsc,
        ),
      );

      expect(page.items, hasLength(1));
      expect(page.totalCount, 1);
      final (function, params) = recorded.single;
      expect(function, 'guest_search_properties');
      expect(params['p_location_id'], '00000000-0000-4000-8000-0000000000cc');
      expect(params['p_check_in'], '2026-11-20');
      expect(params['p_check_out'], '2026-11-23');
      expect(params['p_guests'], 4);
      expect(params['p_price_min_minor'], 50000);
      expect(params['p_amenity_keys'], ['wifi']);
      expect(params['p_sort'], 'price_asc');
      expect(params['p_limit'], 20);
      // Null values are left out.
      expect(params.containsKey('p_price_max_minor'), isFalse);
      expect(params.containsKey('p_cursor'), isFalse);
    },
  );

  test('a follow-up page sends the cursor', () async {
    await repo.searchProperties(
      const PropertySearchParams(),
      cursor: 'cursor-1',
    );
    expect(recorded.single.$2['p_cursor'], 'cursor-1');
  });

  test('countProperties sends p_limit 0 and returns total_count', () async {
    final count = await repo.countProperties(
      const PropertySearchParams(propertyTypes: {'apartment'}),
    );
    expect(count, 1);
    final (function, params) = recorded.single;
    expect(function, 'guest_search_properties');
    expect(params['p_limit'], 0);
    expect(params['p_property_types'], ['apartment']);
  });

  test('homeFeed calls guest_home_feed', () async {
    final feed = await repo.homeFeed();
    expect(recorded.single.$1, 'guest_home_feed');
    expect(feed.referenceVersion, 'v1');
  });

  test('property calls guest_get_property with the id and locale', () async {
    final details = await repo.property('00000000-0000-4000-8000-000000000001');
    expect(recorded.single.$1, 'guest_get_property');
    expect(
      recorded.single.$2['p_property_id'],
      '00000000-0000-4000-8000-000000000001',
    );
    expect(recorded.single.$2['p_locale'], 'ar');
    expect(details.policy.depositType, DepositType.percent);
  });

  test(
    'unavailableNights calls guest_get_property_unavailable_dates',
    () async {
      final nights = await repo.unavailableNights(
        '00000000-0000-4000-8000-000000000001',
        DateOnly(2026, 11, 1),
        DateOnly(2026, 11, 10),
      );
      expect(recorded.single.$1, 'guest_get_property_unavailable_dates');
      expect(recorded.single.$2['p_from'], '2026-11-01');
      expect(recorded.single.$2['p_to'], '2026-11-10');
      expect(nights, {DateOnly(2026, 11, 2), DateOnly(2026, 11, 3)});
    },
  );

  test('reviews calls guest_list_property_reviews with pagination', () async {
    final page = await repo.reviews(
      '00000000-0000-4000-8000-000000000001',
      cursor: 'c9',
      limit: 10,
    );
    expect(page.items, hasLength(1));
    final (function, params) = recorded.single;
    expect(function, 'guest_list_property_reviews');
    expect(params['p_cursor'], 'c9');
    expect(params['p_limit'], 10);
  });

  test('searchLocations calls guest_search_locations', () async {
    final suggestions = await repo.searchLocations('التجمع');
    expect(recorded.single.$1, 'guest_search_locations');
    expect(recorded.single.$2['p_query'], 'التجمع');
    expect(suggestions.single.listingCount, 42);
  });

  test('referenceData calls guest_get_reference_data', () async {
    final data = await repo.referenceData();
    expect(recorded.single.$1, 'guest_get_reference_data');
    expect(data.priceStep, Money(5000));
  });

  group('error mapping', () {
    Future<dynamic> failingRpc(
      String function,
      Map<String, dynamic> params,
    ) => throw const PostgrestException(message: 'NOT_FOUND', code: 'P0001');

    Future<dynamic> socketRpc(
      String function,
      Map<String, dynamic> params,
    ) => throw const SocketException('down');

    Future<dynamic> httpRpc(
      String function,
      Map<String, dynamic> params,
    ) => throw http.ClientException('closed');

    Future<dynamic> otherRpc(
      String function,
      Map<String, dynamic> params,
    ) => throw StateError('boom');

    test('PostgrestException NOT_FOUND becomes notFound', () async {
      final repo = SupabaseListingsRepository(rpc: failingRpc);
      await expectLater(
        repo.property('00000000-0000-4000-8000-000000000001'),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.notFound,
          ),
        ),
      );
    });

    test('transport errors become network', () async {
      for (final rpc in [socketRpc, httpRpc]) {
        final repo = SupabaseListingsRepository(rpc: rpc);
        await expectLater(
          repo.homeFeed(),
          throwsA(
            isA<AppFailure>().having(
              (failure) => failure.error.code,
              'code',
              ErrorCode.network,
            ),
          ),
        );
      }
    });

    test('any other exception becomes internal', () async {
      final repo = SupabaseListingsRepository(rpc: otherRpc);
      await expectLater(
        repo.homeFeed(),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.internal,
          ),
        ),
      );
    });
  });

  group('malformed responses', () {
    const propertyId = '00000000-0000-4000-8000-000000000001';
    final nightsRange = (
      DateOnly(2026, 11, 1),
      DateOnly(2026, 11, 10),
    );

    /// A payload of the wrong shape per function: a string where a map is
    /// expected, a map where a list is expected, and a string where an int
    /// or a date is expected.
    Future<dynamic> wrongTypeRpc(
      String function,
      Map<String, dynamic> params,
    ) async => switch (function) {
      'guest_search_locations' => <String, dynamic>{},
      'guest_get_property_unavailable_dates' => <Object?>['not-a-date'],
      'guest_search_properties' => <String, dynamic>{
        'items': <Object?>[],
        'next_cursor': null,
        'total_count': 'many',
      },
      _ => 'not-a-map',
    };

    test('a null response is an AppFailure for every method', () async {
      final repo = SupabaseListingsRepository(
        rpc: (function, params) async => null,
      );
      const params = PropertySearchParams();
      await expectLater(repo.homeFeed(), throwsA(isA<AppFailure>()));
      await expectLater(
        repo.searchProperties(params),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(
        repo.countProperties(params),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(repo.searchLocations('q'), throwsA(isA<AppFailure>()));
      await expectLater(repo.referenceData(), throwsA(isA<AppFailure>()));
      // An empty answer is NOT_FOUND so existence is never revealed.
      await expectLater(
        repo.property(propertyId),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.notFound,
          ),
        ),
      );
      await expectLater(
        repo.unavailableNights(propertyId, nightsRange.$1, nightsRange.$2),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(repo.reviews(propertyId), throwsA(isA<AppFailure>()));
    });

    test(
      'a wrong payload type is an internal AppFailure for every method',
      () async {
        final repo = SupabaseListingsRepository(rpc: wrongTypeRpc);
        const params = PropertySearchParams();
        for (final call in <Future<Object?> Function()>[
          repo.homeFeed,
          () => repo.searchProperties(params),
          () => repo.countProperties(params),
          () => repo.searchLocations('q'),
          repo.referenceData,
          () => repo.property(propertyId),
          () => repo.unavailableNights(
            propertyId,
            nightsRange.$1,
            nightsRange.$2,
          ),
          () => repo.reviews(propertyId),
        ]) {
          await expectLater(
            call(),
            throwsA(
              isA<AppFailure>().having(
                (failure) => failure.error.code,
                'code',
                ErrorCode.internal,
              ),
            ),
            reason: 'parsing must happen inside the guard',
          );
        }
      },
    );
  });
}
