import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';

HomeFeed _feed({bool withBooking = false}) => HomeFeed(
  referenceVersion: 'mock-ref-1',
  areas: const FeedSectionReady([
    AreaTile(
      locationId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      name: 'التجمع الخامس',
      listingCount: 42,
      image: null,
    ),
  ]),
  suggested: FeedSectionReady([
    ListingCard(
      id: '550e8400-e29b-41d4-a716-446655440000',
      title: 'شقة 3 غرف بإطلالة',
      propertyType: 'apartment',
      areaName: 'التجمع الخامس',
      cityName: 'القاهرة الجديدة',
      cover: null,
      nightlyPrice: Money(150000),
      ratingAvg: 4.6,
      reviewCount: 12,
      stay: null,
    ),
  ]),
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
  late Directory directory;
  late JsonFileCache cache;
  late HomeFeedCache homeCache;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('on_air_home_cache_test');
    cache = JsonFileCache(
      directory: directory,
      fileName: 'discovery_cache.json',
      schema: 1,
    );
    homeCache = HomeFeedCache(cache);
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  test('save then load returns the public sections', () async {
    await homeCache.save(_feed());

    final loaded = await homeCache.load();

    expect(loaded, isNotNull);
    expect(loaded!.referenceVersion, 'mock-ref-1');
    expect(loaded.areas, _feed().areas);
    expect(loaded.suggested, _feed().suggested);
    expect(loaded.newest, _feed().newest);
    expect(loaded.fetchedAt, _feed().fetchedAt);
  });

  test('the loaded cache never carries an upcoming booking', () async {
    await homeCache.save(_feed(withBooking: true));

    final loaded = await homeCache.load();

    expect(
      loaded!.upcomingBooking,
      isA<FeedSectionReady<UpcomingBookingCard?>>(),
    );
    expect(
      (loaded.upcomingBooking as FeedSectionReady<UpcomingBookingCard?>).value,
      isNull,
    );
  });

  test('the file content never contains the booking data', () async {
    await homeCache.save(_feed(withBooking: true));

    final raw = File(
      '${directory.path}/discovery_cache.json',
    ).readAsStringSync();

    expect(raw.contains('upcoming_booking'), isFalse);
    expect(raw.contains('b-1'), isFalse);
  });

  test('the reference key in the same file is kept after save', () async {
    await cache.write({
      'reference': {'version': 'v1'},
    });

    await homeCache.save(_feed());

    final document = await cache.read();
    expect(document, isNotNull);
    expect(document!['reference'], {'version': 'v1'});
    expect(document['home'], isNotNull);
  });

  test('load returns null when nothing is cached', () async {
    expect(await homeCache.load(), isNull);
  });
}
