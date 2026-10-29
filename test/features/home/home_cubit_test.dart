import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/home/presentation/home_cubit.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';

ListingCard _card(String title) => ListingCard(
  id: '550e8400-e29b-41d4-a716-446655440000',
  title: title,
  propertyType: 'apartment',
  areaName: 'التجمع الخامس',
  cityName: 'القاهرة الجديدة',
  cover: null,
  nightlyPrice: Money(150000),
  ratingAvg: 4.6,
  reviewCount: 12,
  stay: null,
);

HomeFeed _feed({
  String referenceVersion = 'v1',
  FeedSection<List<ListingCard>>? suggested,
  bool withBooking = false,
}) => HomeFeed(
  referenceVersion: referenceVersion,
  areas: const FeedSectionReady([
    AreaTile(
      locationId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      name: 'التجمع الخامس',
      listingCount: 42,
      image: null,
    ),
  ]),
  suggested: suggested ?? FeedSectionReady([_card('شقة مقترحة')]),
  newest: const FeedSectionReady([]),
  upcomingBooking: withBooking
      ? FeedSectionReady(
          UpcomingBookingCard(
            bookingId: 'b-1',
            propertyTitle: 'شقة محجوزة',
            checkIn: DateOnly(2026, 11, 20),
            checkOut: DateOnly(2026, 11, 23),
            status: 'confirmed',
          ),
        )
      : const FeedSectionReady<UpcomingBookingCard?>(null),
  fetchedAt: DateTime.utc(2026, 10, 28, 10),
);

void main() {
  late FakeListingsRepository listings;
  late FakeConnectivity connectivity;
  late FakeAuthRepository auth;
  late Directory directory;
  late JsonFileCache cache;
  late HomeFeedCache homeCache;
  late ReferenceDataCache reference;

  setUp(() {
    listings = FakeListingsRepository();
    connectivity = FakeConnectivity();
    auth = FakeAuthRepository();
    directory = Directory.systemTemp.createTempSync('on_air_home_cubit_test');
    cache = JsonFileCache(
      directory: directory,
      fileName: 'discovery_cache.json',
      schema: 1,
    );
    homeCache = HomeFeedCache(cache);
    reference = ReferenceDataCache(listings, cache);
  });

  tearDown(() {
    connectivity.dispose();
    unawaited(auth.dispose());
    directory.deleteSync(recursive: true);
  });

  GuestAccount guestAccount() => GuestAccount(
    id: 'guest',
    phone: '+201012345678',
    phoneVerified: true,
    fullName: 'زائر',
    acceptedTermsVersion: 'v1',
    acceptedTermsAt: DateTime.utc(2026),
  );

  Future<AuthCubit> newAuthCubit({bool signedIn = false}) async {
    if (signedIn) auth.account = guestAccount();
    final cubit = AuthCubit(auth, currentTermsVersion: 'v1');
    await cubit.restore();
    return cubit;
  }

  Future<HomeCubit> buildCubit({AuthCubit? authCubit}) async {
    final cubit = HomeCubit(
      repo: listings,
      cache: homeCache,
      reference: reference,
      connectivity: connectivity.createCubit(),
      auth: authCubit ?? await newAuthCubit(),
    );
    return cubit;
  }

  test('with a cache the first state shows it and refreshes', () async {
    final cached = _feed();
    await homeCache.save(cached);
    final fresh = _feed(
      referenceVersion: 'v2',
      suggested: FeedSectionReady([
        _card('شقة جديدة'),
      ]),
    );
    listings.homeFeedResponses.add(fresh);
    final cubit = await buildCubit();
    final states = <HomeState>[];
    cubit.stream.listen(states.add);
    addTearDown(cubit.close);

    await cubit.start();

    expect(states.first.feed, cached);
    expect(states.first.refreshing, isTrue);
    expect(states.last.feed, fresh);
    expect(states.last.refreshing, isFalse);
    // The fresh public sections are saved for the next launch.
    expect((await homeCache.load())!.referenceVersion, 'v2');
  });

  test('without a cache every section starts loading', () async {
    listings.homeFeedResponses.add(_feed());
    final cubit = await buildCubit();
    final states = <HomeState>[];
    cubit.stream.listen(states.add);
    addTearDown(cubit.close);

    await cubit.start();

    expect(states.first.feed, isNull);
    expect(states.first.sectionLoading, {
      for (final id in HomeSectionId.values) id: true,
    });
    expect(states.last.feed, isNotNull);
    expect(
      states.last.sectionLoading.values.any((loading) => loading),
      isFalse,
    );
  });

  test('a failed section stays failed while the others render', () async {
    listings.homeFeedResponses.add(
      _feed(
        suggested: const FeedSectionFailed<List<ListingCard>>(
          'INTERNAL',
          'req-1',
        ),
      ),
    );
    final cubit = await buildCubit();
    addTearDown(cubit.close);

    await cubit.start();

    final feed = cubit.state.feed!;
    expect(feed.suggested, isA<FeedSectionFailed<List<ListingCard>>>());
    expect(feed.areas, isA<FeedSectionReady<List<AreaTile>>>());
    expect(feed.newest, isA<FeedSectionReady<List<ListingCard>>>());
  });

  test('retrySection replaces only that section', () async {
    listings.homeFeedResponses.add(_feed());
    final cubit = await buildCubit();
    addTearDown(cubit.close);
    await cubit.start();
    final originalAreas = cubit.state.feed!.areas;
    listings.homeFeedResponses.add(
      _feed(suggested: FeedSectionReady([_card('شقة بديلة')])),
    );

    await cubit.retrySection(HomeSectionId.suggested);

    final feed = cubit.state.feed!;
    expect(
      feed.suggested,
      FeedSectionReady([_card('شقة بديلة')]),
    );
    expect(feed.areas, originalAreas);
    expect(
      listings.calls.where((call) => call.startsWith('homeFeed()')),
      hasLength(2),
    );
  });

  test('refresh reloads everything', () async {
    listings.homeFeedResponses.add(_feed());
    final cubit = await buildCubit();
    addTearDown(cubit.close);
    await cubit.start();
    listings.homeFeedResponses.add(
      _feed(
        referenceVersion: 'v3',
        suggested: FeedSectionReady([
          _card('شقة بعد التحديث'),
        ]),
      ),
    );

    await cubit.refresh();

    expect(cubit.state.feed!.referenceVersion, 'v3');
    expect(cubit.state.refreshing, isFalse);
  });

  test('SignedOut clears the upcoming booking immediately', () async {
    final guestCubit = await newAuthCubit(signedIn: true);
    listings.homeFeedResponses.add(_feed(withBooking: true));
    final cubit = HomeCubit(
      repo: listings,
      cache: homeCache,
      reference: reference,
      connectivity: connectivity.createCubit(),
      auth: guestCubit,
    );
    addTearDown(cubit.close);
    addTearDown(guestCubit.close);
    await cubit.start();
    expect(
      (cubit.state.feed!.upcomingBooking as FeedSectionReady).value,
      isNotNull,
    );

    auth.publish(null);
    await Future<void>.delayed(Duration.zero);

    expect(
      (cubit.state.feed!.upcomingBooking as FeedSectionReady).value,
      isNull,
    );
  });

  test('a new reference version refreshes the reference data', () async {
    listings.homeFeedResponses.add(_feed(referenceVersion: 'v2'));
    listings.referenceDataResponses.add(_emptyReference('v2'));
    final cubit = await buildCubit();
    addTearDown(cubit.close);

    await cubit.start();

    expect(
      listings.calls.any((call) => call.startsWith('referenceData()')),
      isTrue,
      reason: 'the cached version is not v2, so the reference is refetched',
    );
  });

  test('offline with a cache keeps the cache and flags offline', () async {
    await homeCache.save(_feed());
    // Subscribe before going offline: a broadcast event added before a
    // listener subscribes is never delivered to it.
    final cubit = await buildCubit();
    addTearDown(cubit.close);
    connectivity.goOffline();
    await Future<void>.delayed(Duration.zero);
    listings.homeFeedResponses.add(AppFailure(ErrorMapper.noResponse()));

    await cubit.start();

    expect(cubit.state.offline, isTrue);
    expect(cubit.state.feed, _feed());
    expect(cubit.state.fatalError, isNull);
  });
}

ReferenceData _emptyReference(String version) => ReferenceData(
  version: version,
  amenities: const [],
  propertyTypes: const [],
  priceMin: Money(50000),
  priceMax: Money(1500000),
  priceStep: Money(5000),
);
