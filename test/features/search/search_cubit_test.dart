import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/date_only.dart';
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
}
