import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';

void main() {
  final today = DateOnly(2026, 11, 1);

  SearchCriteria fromQuery(
    Map<String, String> query, {
    DateOnly? asOf,
  }) => SearchCriteria.fromQuery(query, today: asOf ?? today);

  group('key mapping', () {
    test('parses every documented key', () {
      final criteria = fromQuery({
        'loc': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        'in': '2026-11-20',
        'out': '2026-11-23',
        'g': '3',
        'pmin': '50000',
        'pmax': '150000',
        'bed': '2',
        'bath': '1',
        'am': 'wifi,ac',
        'type': 'apartment,villa',
        'sort': 'price_asc',
      });
      expect(
        criteria.locationId,
        'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      );
      expect(criteria.stay, isNotNull);
      expect(criteria.stay!.nights, 3);
      expect(criteria.guests, 3);
      expect(criteria.priceMin, Money(50000));
      expect(criteria.priceMax, Money(150000));
      expect(criteria.minBedrooms, 2);
      expect(criteria.minBathrooms, 1);
      expect(criteria.amenityKeys, {'wifi', 'ac'});
      expect(criteria.propertyTypes, {'apartment', 'villa'});
      expect(criteria.sort, SearchSort.priceAsc);
      expect(criteria.datesDropped, isFalse);
    });

    test('loc accepts UUID v4 only', () {
      expect(
        fromQuery({'loc': '00000000-0000-1000-8000-000000000001'}).locationId,
        isNull,
        reason: 'version nibble is not 4',
      );
      expect(fromQuery({'loc': 'not-a-uuid'}).locationId, isNull);
    });

    test('g must be 1-50', () {
      expect(fromQuery({'g': '0'}).guests, isNull);
      expect(fromQuery({'g': '51'}).guests, isNull);
      expect(fromQuery({'g': '-1'}).guests, isNull);
      expect(fromQuery({'g': 'abc'}).guests, isNull);
      expect(fromQuery({'g': '50'}).guests, 50);
    });

    test('pmin/pmax must be >= 0 and are swapped when min > max', () {
      final negative = fromQuery({'pmin': '-5'});
      expect(negative.priceMin, isNull);
      expect(negative.priceMax, isNull);

      final swapped = fromQuery({'pmin': '150000', 'pmax': '50000'});
      expect(swapped.priceMin, Money(50000));
      expect(swapped.priceMax, Money(150000));
    });

    test('bed/bath must be 0-20; zero means any and is dropped', () {
      expect(fromQuery({'bed': '21'}).minBedrooms, isNull);
      expect(fromQuery({'bed': '0'}).minBedrooms, isNull);
      expect(fromQuery({'bath': '20'}).minBathrooms, 20);
    });

    test('am and type keep only valid keys, capped at 30', () {
      final filtered = fromQuery({'am': 'wifi,BAD KEY,ac,_x'});
      expect(filtered.amenityKeys, {'wifi', 'ac', '_x'});

      final tooMany = fromQuery({
        'am': [for (var index = 0; index < 35; index++) 'a$index'].join(','),
      });
      expect(tooMany.amenityKeys, hasLength(30));
    });
  });

  group('bad values drop only their own field', () {
    test('an invalid guests value keeps the rest', () {
      final criteria = fromQuery({'g': 'abc', 'bed': '2', 'am': 'wifi'});
      expect(criteria.guests, isNull);
      expect(criteria.minBedrooms, 2);
      expect(criteria.amenityKeys, {'wifi'});
    });
  });

  group('bad dates', () {
    test('past dates drop both and set datesDropped', () {
      final criteria = fromQuery({'in': '2026-10-31', 'out': '2026-11-03'});
      expect(criteria.stay, isNull);
      expect(criteria.datesDropped, isTrue);
    });

    test('inverted dates drop both and set datesDropped', () {
      final criteria = fromQuery({'in': '2026-11-23', 'out': '2026-11-20'});
      expect(criteria.stay, isNull);
      expect(criteria.datesDropped, isTrue);
    });

    test('a check-in without check-out drops both', () {
      final criteria = fromQuery({'in': '2026-11-20'});
      expect(criteria.stay, isNull);
      expect(criteria.datesDropped, isTrue);
    });

    test('check-in equal to today is valid', () {
      final criteria = fromQuery({'in': '2026-11-01', 'out': '2026-11-04'});
      expect(criteria.stay, isNotNull);
      expect(criteria.datesDropped, isFalse);
    });
  });

  test('unknown keys are ignored', () {
    final criteria = fromQuery({'evil': '1', 'g': '2'});
    expect(criteria.guests, 2);
    expect(criteria.toQuery().containsKey('evil'), isFalse);
  });

  group('canonical output', () {
    test('keys are sorted and empty fields are left out', () {
      final criteria = fromQuery({
        'sort': 'newest',
        'g': '2',
        'am': 'wifi',
      });
      expect(
        criteria.toQuery().keys.toList(),
        ['am', 'g', 'sort'],
      );
    });

    test('round-trips: fromQuery(toQuery(x)) == x', () {
      final criteria = fromQuery({
        'loc': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        'in': '2026-11-20',
        'out': '2026-11-23',
        'g': '4',
        'pmin': '50000',
        'pmax': '100000',
        'bed': '2',
        'bath': '1',
        'am': 'wifi,ac',
        'type': 'apartment',
        'sort': 'price_desc',
      });
      expect(
        SearchCriteria.fromQuery(criteria.toQuery(), today: today),
        criteria,
      );
    });

    test('locationLabel is never written to the query', () {
      final criteria = const SearchCriteria(
        locationId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      ).copyWith(locationLabel: 'التجمع الخامس');
      expect(criteria.toQuery().containsKey('locationLabel'), isFalse);
      expect(criteria.toQuery().containsKey('label'), isFalse);
    });
  });

  test('empty criteria has no fields and is valid', () {
    const empty = SearchCriteria.empty;
    expect(empty.locationId, isNull);
    expect(empty.stay, isNull);
    expect(empty.guests, isNull);
    expect(empty.priceMin, isNull);
    expect(empty.priceMax, isNull);
    expect(empty.minBedrooms, isNull);
    expect(empty.minBathrooms, isNull);
    expect(empty.amenityKeys, isEmpty);
    expect(empty.propertyTypes, isEmpty);
    expect(empty.sort, isNull);
    expect(empty.toQuery(), isEmpty);
    expect(empty.activeFilterChips, isEmpty);
  });

  group('activeFilterChips', () {
    test('lists price, bedrooms, bathrooms, amenities, and types', () {
      final criteria = fromQuery({
        'pmin': '50000',
        'pmax': '100000',
        'bed': '2',
        'bath': '1',
        'am': 'wifi,ac',
        'type': 'apartment',
        'loc': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        'in': '2026-11-20',
        'out': '2026-11-23',
        'g': '3',
      });
      final kinds = criteria.activeFilterChips.map((chip) => chip.kind);
      expect(
        kinds,
        [
          FilterChipKind.price,
          FilterChipKind.bedrooms,
          FilterChipKind.bathrooms,
          FilterChipKind.amenity,
          FilterChipKind.amenity,
          FilterChipKind.type,
        ],
      );
      expect(
        criteria.activeFilterChips
            .where((chip) => chip.kind == FilterChipKind.amenity)
            .map((chip) => chip.key),
        containsAll(['wifi', 'ac']),
      );
    });

    test('withoutChip removes exactly one filter', () {
      final criteria = fromQuery({'am': 'wifi,ac', 'bed': '2'});
      final wifiChip = criteria.activeFilterChips.firstWhere(
        (chip) => chip.key == 'wifi',
      );
      final without = criteria.withoutChip(wifiChip);
      expect(without.amenityKeys, {'ac'});
      expect(without.minBedrooms, 2);

      final bedChip = without.activeFilterChips.firstWhere(
        (chip) => chip.kind == FilterChipKind.bedrooms,
      );
      expect(without.withoutChip(bedChip).minBedrooms, isNull);

      final price = fromQuery({'pmin': '1', 'pmax': '2'});
      final priceChip = price.activeFilterChips.single;
      final noPrice = price.withoutChip(priceChip);
      expect(noPrice.priceMin, isNull);
      expect(noPrice.priceMax, isNull);
    });
  });

  group('copyWith', () {
    test('a new stay clears datesDropped; other edits keep it', () {
      final dropped = fromQuery({'in': '2026-10-31', 'out': '2026-11-03'});
      expect(dropped.datesDropped, isTrue);
      expect(
        dropped
            .copyWith(
              stay: StayRange(DateOnly(2026, 11, 20), DateOnly(2026, 11, 23)),
            )
            .datesDropped,
        isFalse,
      );
      expect(dropped.copyWith(guests: 3).datesDropped, isTrue);
    });
  });

  test('toParams returns the matching search parameters', () {
    final criteria = fromQuery({
      'loc': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      'in': '2026-11-20',
      'out': '2026-11-23',
      'g': '2',
      'pmin': '50000',
      'am': 'wifi',
      'sort': 'price_asc',
    });
    final params = criteria.toParams();
    expect(params, isA<PropertySearchParams>());
    expect(params.locationId, criteria.locationId);
    expect(params.stay, criteria.stay);
    expect(params.guests, 2);
    expect(params.priceMin, Money(50000));
    expect(params.priceMax, isNull);
    expect(params.amenityKeys, {'wifi'});
    expect(params.sort, SearchSort.priceAsc);
  });
}
