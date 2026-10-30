import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateOnly(2026, 11, 1);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save writes the canonical query plus the label', () async {
    final store = LastSearchStore();
    const criteria = SearchCriteria(
      locationId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      guests: 2,
    );
    await store.save(criteria, 'التجمع الخامس');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('last_search_v1'), isNotNull);

    final loaded = await store.load(today: today);
    expect(loaded, isNotNull);
    expect(loaded!.criteria, criteria);
    expect(loaded.label, 'التجمع الخامس');
  });

  test('load returns equal criteria and label', () async {
    final store = LastSearchStore();
    const criteria = SearchCriteria(
      guests: 4,
      amenityKeys: {'wifi'},
      sort: SearchSort.priceAsc,
    );
    await store.save(criteria, null);

    final loaded = await store.load(today: today);
    expect(loaded!.criteria, criteria);
    expect(loaded.label, isNull);
  });

  test('corrupt stored data returns null', () async {
    SharedPreferences.setMockInitialValues({'last_search_v1': '{not json'});
    final store = LastSearchStore();
    expect(await store.load(today: today), isNull);
  });

  test('dates that have since passed are dropped on load', () async {
    final store = LastSearchStore();
    final criteria = SearchCriteria.fromQuery(
      {'in': '2026-11-20', 'out': '2026-11-23'},
      today: today,
    );
    await store.save(criteria, null);

    // Loading against a later day drops the past stay.
    final loaded = await store.load(today: DateOnly(2026, 12, 1));
    expect(loaded!.criteria.stay, isNull);
    expect(loaded.criteria.datesDropped, isTrue);
  });
}
