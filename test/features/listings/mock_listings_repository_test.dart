import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';
import 'package:on_air/features/listings/domain/results_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CairoTime.initialize();

  late MockListingsRepository repo;
  late List<Map<String, dynamic>> propertyList;
  late Map<String, dynamic> reviewsJson;
  late Map<String, String> fixtureIds; // _fixture_name -> id
  late DateOnly today;

  setUpAll(() {
    final raw =
        jsonDecode(
              File(
                'lib/features/listings/data/fixtures/properties.json',
              ).readAsStringSync(),
            )
            as List<dynamic>;
    propertyList = [
      for (final item in raw) Map<String, dynamic>.from(item as Map),
    ];
    fixtureIds = {
      for (final property in propertyList)
        property['_fixture_name'] as String: property['id'] as String,
    };
    reviewsJson =
        jsonDecode(
              File(
                'lib/features/listings/data/fixtures/reviews.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    repo = MockListingsRepository(
      loader: (path) => File(path).readAsString(),
      latency: Duration.zero,
    );
    today = CairoTime.today();
  });

  Future<ResultsPage> searchAll() =>
      repo.searchProperties(const PropertySearchParams());

  String unpublishedId() =>
      propertyList.firstWhere((json) => json['_published'] == false)['id']
          as String;

  test(
    '(a) a search with no criteria never returns unpublished apartments',
    () async {
      final unpublished = propertyList
          .where((json) => json['_published'] == false)
          .map((json) => json['id'] as String)
          .toSet();
      expect(unpublished, isNotEmpty);

      // Page through everything.
      final seen = <String>{};
      String? cursor;
      var guard = 0;
      while (guard++ < 30) {
        final page = await repo.searchProperties(
          const PropertySearchParams(),
          cursor: cursor,
        );
        seen.addAll(page.items.map((card) => card.id));
        cursor = page.nextCursor;
        if (cursor == null) break;
      }
      expect(seen.intersection(unpublished), isEmpty);
      expect(seen, isNotEmpty);
    },
  );

  test('(b) AC-012: dates covering a busy night exclude prop-busy', () async {
    final busyId = fixtureIds['prop-busy']!;
    // booked +10, held +12, blocked +14 (Appendix B offsets).
    for (final offset in [10, 12, 14]) {
      final stay = StayRange(
        today.addDays(offset - 1),
        today.addDays(offset + 1),
      );
      final page = await repo.searchProperties(
        PropertySearchParams(stay: stay),
      );
      expect(
        page.items.map((card) => card.id),
        isNot(contains(busyId)),
        reason: 'night today+$offset must exclude the apartment',
      );
    }

    // A free range next to the busy nights still returns it.
    final freeStay = StayRange(today.addDays(1), today.addDays(5));
    final freePage = await repo.searchProperties(
      PropertySearchParams(stay: freeStay),
    );
    expect(freePage.items.map((card) => card.id), contains(busyId));
  });

  test('(c) unknown and unpublished IDs both give NOT_FOUND', () async {
    for (final id in [
      unpublishedId(),
      'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    ]) {
      await expectLater(
        repo.property(id),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.error.code,
            'code',
            ErrorCode.notFound,
          ),
        ),
      );
    }
  });

  test(
    '(d) pagination: pages of 20, stable total, null cursor at the end',
    () async {
      final page = await searchAll();
      expect(page.items, hasLength(20));
      expect(page.nextCursor, isNotNull);
      expect(page.totalCount, greaterThan(20));

      final totals = <int>{page.totalCount};
      var seen = page.items.length;
      var cursor = page.nextCursor;
      var guard = 0;
      while (cursor != null && guard++ < 30) {
        final next = await repo.searchProperties(
          const PropertySearchParams(),
          cursor: cursor,
        );
        totals.add(next.totalCount);
        seen += next.items.length;
        cursor = next.nextCursor;
      }
      expect(cursor, isNull);
      expect(totals, hasLength(1));
      expect(seen, page.totalCount);
    },
  );

  test('(e) countProperties matches totalCount', () async {
    final page = await searchAll();
    expect(
      await repo.countProperties(const PropertySearchParams()),
      page.totalCount,
    );
  });

  test('(f) price filters apply to the final nightly price', () async {
    final page = await repo.searchProperties(
      PropertySearchParams(priceMax: Money(100000)),
    );
    expect(page.items, isNotEmpty);
    for (final card in page.items) {
      expect(card.nightlyPrice.amountMinor, lessThanOrEqualTo(100000));
    }
    // The percent-deposit fixture is priced above the cap.
    expect(
      page.items.map((card) => card.id),
      isNot(contains(fixtureIds['prop-deposit-percent'])),
    );

    final minPage = await repo.searchProperties(
      PropertySearchParams(priceMin: Money(150000)),
    );
    for (final card in minPage.items) {
      expect(card.nightlyPrice.amountMinor, greaterThanOrEqualTo(150000));
    }
  });

  test('(f) amenity filters require every requested key', () async {
    final page = await repo.searchProperties(
      const PropertySearchParams(amenityKeys: {'wifi', 'ac'}),
    );
    expect(page.items, isNotEmpty);
    for (final card in page.items) {
      final fixture = propertyList.firstWhere((json) => json['id'] == card.id);
      final keys = (fixture['_amenity_keys'] as List).toSet();
      expect(keys, containsAll(['wifi', 'ac']));
    }
    final single = await repo.countProperties(
      const PropertySearchParams(amenityKeys: {'wifi'}),
    );
    final both = await repo.countProperties(
      const PropertySearchParams(amenityKeys: {'wifi', 'ac'}),
    );
    expect(both, lessThanOrEqualTo(single));
  });

  test('(f) property types match any requested key', () async {
    final page = await repo.searchProperties(
      const PropertySearchParams(propertyTypes: {'villa', 'chalet'}),
    );
    expect(page.items, isNotEmpty);
    for (final card in page.items) {
      expect(card.propertyType, anyOf('villa', 'chalet'));
    }
  });

  test('(f) guests filters on maxGuests', () async {
    final page = await repo.searchProperties(
      const PropertySearchParams(guests: 6),
    );
    expect(page.items, isNotEmpty);
    for (final card in page.items) {
      final fixture = propertyList.firstWhere((json) => json['id'] == card.id);
      expect(fixture['max_guests'] as int, greaterThanOrEqualTo(6));
    }
  });

  test('(g) price sorts order by the nightly price', () async {
    final asc = await repo.searchProperties(
      const PropertySearchParams(sort: SearchSort.priceAsc),
    );
    final ascPrices = asc.items.map((card) => card.nightlyPrice.amountMinor);
    expect(
      ascPrices.toList(),
      ascPrices.toList()..sort(),
    );

    final desc = await repo.searchProperties(
      const PropertySearchParams(sort: SearchSort.priceDesc),
    );
    final descPrices = desc.items
        .map((card) => card.nightlyPrice.amountMinor)
        .toList();
    expect(descPrices, descPrices.toList()..sort((a, b) => b.compareTo(a)));
  });

  test('(g) the default sort is newest first', () async {
    final page = await searchAll();
    final expected =
        propertyList.where((json) => json['_published'] == true).toList()..sort(
          (a, b) => (b['_created_at'] as String).compareTo(
            a['_created_at'] as String,
          ),
        );
    expect(
      page.items.map((card) => card.id).take(5),
      expected.map((json) => json['id'] as String).take(5),
    );
  });

  test('(h) location search is Arabic-normalised', () async {
    final plain = await repo.searchLocations('التجمع');
    final decorated = await repo.searchLocations('التجمّع');
    expect(plain, isNotEmpty);
    expect(
      plain.map((s) => s.id).toSet(),
      decorated.map((s) => s.id).toSet(),
    );

    final oneChar = await repo.searchLocations('ت');
    expect(oneChar, isEmpty);
  });

  test(
    '(i) unavailableNights returns exactly the busy nights in the window',
    () async {
      final busyId = fixtureIds['prop-busy']!;
      final nights = await repo.unavailableNights(
        busyId,
        today.addDays(1),
        today.addDays(20),
      );
      expect(nights, {
        today.addDays(10),
        today.addDays(12),
        today.addDays(14),
      });

      // Nights outside the window are not reported.
      final narrow = await repo.unavailableNights(
        busyId,
        today.addDays(11),
        today.addDays(13),
      );
      expect(narrow, {today.addDays(12)});

      expect(
        await repo.unavailableNights(
          fixtureIds['prop-deposit-percent']!,
          today.addDays(1),
          today.addDays(20),
        ),
        isEmpty,
      );
    },
  );

  test('(j) reviews return only approved entries, newest first', () async {
    final id = fixtureIds['prop-deposit-percent']!;
    final page = await repo.reviews(id);
    expect(page.items, hasLength(20));
    expect(page.nextCursor, isNotNull);

    final fixtureReviews =
        (reviewsJson[id] as List)
            .cast<Map<dynamic, dynamic>>()
            .where((review) => review['status'] == 'approved')
            .toList()
          ..sort(
            (a, b) => (b['created_on'] as String).compareTo(
              a['created_on'] as String,
            ),
          );
    expect(fixtureReviews.length, greaterThanOrEqualTo(25));

    final dates = page.items.map((review) => review.createdOn.toString());
    expect(dates.toList(), dates.toList()..sort((a, b) => b.compareTo(a)));
    for (final review in page.items) {
      expect(review.reviewerShortName, isNotEmpty);
    }

    // Page to the end.
    final rest = await repo.reviews(id, cursor: page.nextCursor);
    expect(page.items.length + rest.items.length, fixtureReviews.length);
    expect(rest.nextCursor, isNull);

    // Short names only: the fixture never carries a full name field.
    for (final review in page.items) {
      expect(
        review.reviewerShortName.split(' ').last.endsWith('.'),
        isTrue,
        reason: 'short names end with the abbreviated last name',
      );
    }
  });
}
