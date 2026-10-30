import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';

ListingCard _card(String id) => ListingCard.fromJson({
  'id': id,
  'title': 'شقة $id',
  'property_type': 'apartment',
  'area_name': 'التجمع الخامس',
  'city_name': 'القاهرة الجديدة',
  'nightly_price_minor': 150000,
  'currency': 'EGP',
  'review_count': 3,
  'rating_avg': 4.5,
});

void main() {
  final today = DateOnly(2026, 11, 1);
  final criteria = SearchCriteria.fromQuery(
    {'g': '2', 'am': 'wifi,ac'},
    today: today,
  );

  late FakeConnectivity connectivity;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    connectivity = FakeConnectivity();
  });

  tearDown(() {
    connectivity.dispose();
  });

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Future<SearchCubit> newCubit(FakeListingsRepository repo) async {
    final cubit = SearchCubit(
      repo: repo,
      lastSearch: LastSearchStore(),
      connectivity: connectivity.createCubit(),
      today: () => today,
    );
    // Let the initial last-search restore settle.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  test('search emits loading then ready and saves the last search', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      ResultsPage(
        items: [_card('a'), _card('b')],
        nextCursor: 'c2',
        totalCount: 12,
      ),
    );
    final cubit = await newCubit(repo);
    final states = <SearchState>[];
    cubit.stream.listen(states.add);

    await cubit.search(criteria, label: 'التجمع الخامس');
    await settle();

    expect(states[0].status, ResultsStatus.loading);
    expect(states[1].status, ResultsStatus.ready);
    expect(states[1].items, hasLength(2));
    expect(states[1].totalCount, 12);
    expect(states[1].nextCursor, 'c2');
    expect(states[1].criteria, criteria);
    expect(states[1].locationLabel, 'التجمع الخامس');

    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('last_search_v1');
    expect(saved, isNotNull);
    expect(saved, contains('g=2'));
    expect(saved, contains('التجمع الخامس'));
    await cubit.close();
  });

  test('a search with zero results emits empty', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      const ResultsPage(items: [], nextCursor: null, totalCount: 0),
    );
    final cubit = await newCubit(repo);
    final states = <SearchState>[];
    cubit.stream.listen(states.add);

    await cubit.search(criteria);
    await settle();

    expect(states.last.status, ResultsStatus.empty);
    await cubit.close();
  });

  test('loadMore appends the next page', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      ResultsPage(items: [_card('a')], nextCursor: 'c2', totalCount: 3),
    );
    repo.searchResponses.add(
      ResultsPage(
        items: [_card('b'), _card('c')],
        nextCursor: null,
        totalCount: 3,
      ),
    );
    final cubit = await newCubit(repo);
    await cubit.search(criteria);

    await cubit.loadMore();
    await settle();

    expect(cubit.state.items, hasLength(3));
    expect(cubit.state.nextCursor, isNull);
    expect(cubit.state.loadingMore, isFalse);
    await cubit.close();
  });

  test(
    'loadMore continues the loaded criteria, not an un-searched edit',
    () async {
      final repo = FakeListingsRepository();
      repo.searchResponses
        ..add(ResultsPage(items: [_card('a')], nextCursor: 'c2', totalCount: 3))
        ..add(
          ResultsPage(items: [_card('b')], nextCursor: null, totalCount: 3),
        );
      final cubit = await newCubit(repo);
      await cubit.search(criteria);

      // An edit that was never searched (e.g. on the search screen).
      cubit.setCriteria(criteria.copyWith(guests: 7));
      await cubit.loadMore();
      await settle();

      expect(repo.searchParams, hasLength(2));
      expect(
        repo.searchParams.last,
        criteria.toParams(),
        reason: 'page 2 must belong to the list that is on screen',
      );
      expect(cubit.state.items, hasLength(2));
      await cubit.close();
    },
  );

  test('loadMore is ignored while loading, at the end, and offline', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      ResultsPage(items: [_card('a')], nextCursor: null, totalCount: 1),
    );
    final cubit = await newCubit(repo);
    await cubit.search(criteria);
    final callsBefore = repo.calls.length;

    // nextCursor is null: no more pages.
    await cubit.loadMore();
    await settle();
    expect(repo.calls, hasLength(callsBefore));

    // Offline: ignored.
    connectivity.goOffline();
    await Future<void>.delayed(Duration.zero);
    await cubit.loadMore();
    await settle();
    expect(repo.calls, hasLength(callsBefore));
    await cubit.close();
  });

  test('a validationFailed during loadMore resets to page 1', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      ResultsPage(items: [_card('a')], nextCursor: 'bad', totalCount: 5),
    );
    repo.searchResponses.add(
      const AppFailure(
        ApiError(
          code: ErrorCode.validationFailed,
          messageKey: 'errorValidationFailed',
        ),
      ),
    );
    repo.searchResponses.add(
      ResultsPage(
        items: [_card('x'), _card('y')],
        nextCursor: 'c2',
        totalCount: 5,
      ),
    );
    final cubit = await newCubit(repo);
    await cubit.search(criteria);
    final states = <SearchState>[];
    cubit.stream.listen(states.add);

    await cubit.loadMore();
    await settle();

    expect(states.last.status, ResultsStatus.ready);
    expect(states.last.items.map((card) => card.id), ['x', 'y']);
    expect(
      repo.calls.last,
      contains('cursor: null'),
      reason: 'the reset search starts from page 1',
    );
    await cubit.close();
  });

  test('removeChip searches again without that chip', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      const ResultsPage(items: [], nextCursor: null, totalCount: 0),
    );
    final cubit = await newCubit(repo);
    await cubit.search(criteria);
    expect(cubit.state.criteria.amenityKeys, {'wifi', 'ac'});

    final wifiChip = cubit.state.criteria.activeFilterChips.firstWhere(
      (chip) => chip.key == 'wifi',
    );
    await cubit.removeChip(wifiChip);
    await settle();

    expect(cubit.state.criteria.amenityKeys, {'ac'});
    expect(repo.calls, hasLength(2));
    await cubit.close();
  });

  test('openFromQuery parses the query and flags dropped dates', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      const ResultsPage(items: [], nextCursor: null, totalCount: 0),
    );
    final cubit = await newCubit(repo);

    await cubit.openFromQuery({
      'in': '2026-10-31',
      'out': '2026-11-03',
      'g': '2',
    });
    await settle();

    expect(cubit.state.criteria.stay, isNull);
    expect(cubit.state.criteria.guests, 2);
    expect(cubit.state.datesDropped, isTrue);
    expect(repo.calls, hasLength(1), reason: 'opening results searches');
    await cubit.close();
  });

  test('opening the same query twice does not search twice', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      const ResultsPage(items: [], nextCursor: null, totalCount: 0),
    );
    final cubit = await newCubit(repo);

    await cubit.openFromQuery({'g': '2'});
    await settle();
    await cubit.openFromQuery({'g': '2'});
    await settle();

    expect(repo.calls, hasLength(1));
    await cubit.close();
  });

  test('offline search emits offline without calling the repository', () async {
    final repo = FakeListingsRepository();
    final cubit = await newCubit(repo);
    final states = <SearchState>[];
    cubit.stream.listen(states.add);
    connectivity.goOffline();
    await Future<void>.delayed(Duration.zero);

    await cubit.search(criteria);
    await settle();

    expect(states.last.status, ResultsStatus.offline);
    expect(repo.calls, isEmpty);
    await cubit.close();
  });

  test('rememberScroll keeps the scroll offset in state', () async {
    final repo = FakeListingsRepository();
    final cubit = await newCubit(repo);

    cubit.rememberScroll(421.5);

    expect(cubit.state.scrollOffset, 421.5);
    await cubit.close();
  });

  test(
    'the initial state restores the last search without searching',
    () async {
      SharedPreferences.setMockInitialValues({
        'last_search_v1': '{"q":"g=2&am=wifi","label":"التجمع الخامس"}',
      });
      final repo = FakeListingsRepository();
      final cubit = SearchCubit(
        repo: repo,
        lastSearch: LastSearchStore(),
        connectivity: connectivity.createCubit(),
        today: () => today,
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.criteria.guests, 2);
      expect(cubit.state.criteria.amenityKeys, {'wifi'});
      expect(cubit.state.locationLabel, 'التجمع الخامس');
      expect(cubit.state.status, ResultsStatus.idle);
      expect(repo.calls, isEmpty);
      await cubit.close();
    },
  );

  test('the initial restore loses to an earlier openFromQuery', () async {
    SharedPreferences.setMockInitialValues({
      'last_search_v1': '{"q":"g=2&am=wifi","label":"التجمع الخامس"}',
    });
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      ResultsPage(items: [_card('a')], nextCursor: null, totalCount: 1),
    );
    final cubit = SearchCubit(
      repo: repo,
      lastSearch: LastSearchStore(),
      connectivity: connectivity.createCubit(),
      today: () => today,
    );
    // The link opens before the restore microtask runs.
    await cubit.openFromQuery({'g': '4'});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.criteria.guests, 4, reason: 'the link wins');
    expect(cubit.state.criteria.amenityKeys, isEmpty);
    await cubit.close();
  });

  test('a late response from a superseded search is ignored', () async {
    final first = Completer<ResultsPage>();
    final second = Completer<ResultsPage>();
    final repo = FakeListingsRepository();
    repo.searchResponses
      ..add(first.future)
      ..add(second.future);
    final cubit = await newCubit(repo);
    final pendingA = cubit.search(
      SearchCriteria.fromQuery({'am': 'wifi'}, today: today),
      label: 'A',
    );
    final pendingB = cubit.search(
      SearchCriteria.fromQuery({'am': 'ac'}, today: today),
      label: 'B',
    );

    second.complete(
      ResultsPage(items: [_card('b')], nextCursor: null, totalCount: 1),
    );
    await pendingB;
    await settle();
    expect(cubit.state.items.map((card) => card.id), ['b']);
    expect(cubit.state.locationLabel, 'B');

    first.complete(
      ResultsPage(
        items: [_card('a1'), _card('a2')],
        nextCursor: null,
        totalCount: 2,
      ),
    );
    await pendingA;
    await settle();
    expect(
      cubit.state.items.map((card) => card.id),
      ['b'],
      reason: 'the superseded response must not win',
    );
    expect(cubit.state.locationLabel, 'B');
    await cubit.close();
  });

  test('a page from a superseded loadMore is dropped', () async {
    final stale = Completer<ResultsPage>();
    final repo = FakeListingsRepository();
    repo.searchResponses
      ..add(ResultsPage(items: [_card('a')], nextCursor: 'c2', totalCount: 5))
      ..add(stale.future);
    final cubit = await newCubit(repo);
    await cubit.search(criteria);
    final pendingLoadMore = cubit.loadMore();
    expect(cubit.state.loadingMore, isTrue);

    repo.searchResponses.add(
      ResultsPage(items: [_card('x')], nextCursor: null, totalCount: 5),
    );
    final wifiChip = cubit.state.criteria.activeFilterChips.firstWhere(
      (chip) => chip.key == 'wifi',
    );
    await cubit.removeChip(wifiChip);
    await settle();
    expect(cubit.state.items.map((card) => card.id), ['x']);

    stale.complete(
      ResultsPage(
        items: [_card('b'), _card('c')],
        nextCursor: 'c9',
        totalCount: 5,
      ),
    );
    await pendingLoadMore;
    await settle();
    expect(
      cubit.state.items.map((card) => card.id),
      ['x'],
      reason: 'the stale page and cursor must not attach',
    );
    expect(cubit.state.nextCursor, isNull);
    await cubit.close();
  });

  test('openFromQuery keeps the label for the same query', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      ResultsPage(items: [_card('a')], nextCursor: null, totalCount: 1),
    );
    final cubit = await newCubit(repo);
    await cubit.search(criteria, label: 'التجمع الخامس');
    final callsAfterSearch = repo.calls.length;

    await cubit.openFromQuery(criteria.toQuery());
    await settle();

    expect(cubit.state.locationLabel, 'التجمع الخامس');
    expect(cubit.state.criteria, criteria);
    expect(
      repo.calls.length,
      callsAfterSearch,
      reason: 'the same query is not searched again',
    );
    await cubit.close();
  });

  test('a new query for the same location keeps the label', () async {
    const locationId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    final repo = FakeListingsRepository();
    repo.searchResponses
      ..add(const ResultsPage(items: [], nextCursor: null, totalCount: 0))
      ..add(ResultsPage(items: [_card('a')], nextCursor: null, totalCount: 1));
    final cubit = await newCubit(repo);
    await cubit.search(
      const SearchCriteria(locationId: locationId),
      label: 'X',
    );

    await cubit.openFromQuery({'loc': locationId, 'g': '3'});
    await settle();

    expect(cubit.state.locationLabel, 'X');
    expect(cubit.state.criteria.guests, 3);
    expect(cubit.state.criteria.locationId, locationId);
    expect(repo.calls, hasLength(2), reason: 'the new query is searched');
    await cubit.close();
  });

  test('openFromQuery syncs edited criteria without searching again', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      const ResultsPage(items: [], nextCursor: null, totalCount: 0),
    );
    final cubit = await newCubit(repo);
    await cubit.search(criteria);

    cubit.setCriteria(criteria.copyWith(guests: 4));
    await cubit.openFromQuery(criteria.toQuery());
    await settle();

    expect(
      cubit.state.criteria,
      criteria,
      reason: 'the link re-asserts its query',
    );
    expect(
      repo.calls,
      hasLength(1),
      reason: 'no new search for the same query',
    );
    await cubit.close();
  });

  test('a late response cannot overwrite an offline search', () async {
    final first = Completer<ResultsPage>();
    final repo = FakeListingsRepository();
    repo.searchResponses.add(first.future);
    final cubit = await newCubit(repo);
    final pendingA = cubit.search(
      SearchCriteria.fromQuery({'am': 'wifi'}, today: today),
    );
    connectivity.goOffline();
    await Future<void>.delayed(Duration.zero);

    await cubit.search(SearchCriteria.fromQuery({'am': 'ac'}, today: today));
    expect(cubit.state.status, ResultsStatus.offline);
    expect(cubit.state.criteria.amenityKeys, {'ac'});
    expect(
      cubit.state.items,
      isEmpty,
      reason: 'a new query offline shows no old items',
    );

    first.complete(
      ResultsPage(items: [_card('a')], nextCursor: null, totalCount: 1),
    );
    await pendingA;
    await settle();
    expect(cubit.state.status, ResultsStatus.offline);
    expect(cubit.state.criteria.amenityKeys, {'ac'});
    await cubit.close();
  });

  test(
    'an offline search for changed criteria clears the loaded items',
    () async {
      final repo = FakeListingsRepository();
      repo.searchResponses.add(
        ResultsPage(items: [_card('a')], nextCursor: null, totalCount: 1),
      );
      final cubit = await newCubit(repo);
      await cubit.search(criteria);
      expect(cubit.state.items, hasLength(1));

      connectivity.goOffline();
      await Future<void>.delayed(Duration.zero);

      // The dropped-dates banner's «اختر التواريخ» flow: setCriteria runs
      // before search, so state.criteria already holds the new criteria
      // when the offline branch compares.
      final withDates = criteria.copyWith(
        stay: StayRange(DateOnly(2026, 11, 20), DateOnly(2026, 11, 23)),
      );
      cubit.setCriteria(withDates);
      await cubit.search(withDates);

      expect(cubit.state.status, ResultsStatus.offline);
      expect(cubit.state.criteria, withDates);
      expect(
        cubit.state.items,
        isEmpty,
        reason: 'the loaded items belong to the old query, not this one',
      );
      await cubit.close();
    },
  );

  test('repeating the same search offline keeps the loaded items', () async {
    final repo = FakeListingsRepository();
    repo.searchResponses.add(
      ResultsPage(items: [_card('a')], nextCursor: null, totalCount: 1),
    );
    final cubit = await newCubit(repo);
    await cubit.search(criteria);
    expect(cubit.state.items, hasLength(1));

    connectivity.goOffline();
    await Future<void>.delayed(Duration.zero);

    await cubit.search(criteria);

    expect(cubit.state.status, ResultsStatus.offline);
    expect(
      cubit.state.items,
      hasLength(1),
      reason: 'the same query keeps its items under the offline banner',
    );
    await cubit.close();
  });

  test(
    're-opening the same query reverts an un-searched location edit',
    () async {
      const xId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
      const yId = 'c2a36820-388e-4a11-9d51-24285b2c4e80';
      final repo = FakeListingsRepository();
      repo.searchResponses.add(
        ResultsPage(items: [_card('a')], nextCursor: null, totalCount: 1),
      );
      final cubit = await newCubit(repo);
      const queryX = SearchCriteria(locationId: xId);
      await cubit.search(queryX, label: 'X');

      // The search screen changes the location without searching.
      cubit.setCriteria(
        queryX.copyWith(locationId: yId, locationLabel: 'Y'),
        label: 'Y',
      );
      expect(cubit.state.locationLabel, 'Y');

      await cubit.openFromQuery(queryX.toQuery());
      await settle();

      expect(cubit.state.criteria.locationId, xId);
      expect(
        cubit.state.locationLabel,
        'X',
        reason: 'the label of the results that are actually displayed',
      );
      expect(
        repo.calls,
        hasLength(1),
        reason: 'no new search for the same query',
      );
      await cubit.close();
    },
  );
}
