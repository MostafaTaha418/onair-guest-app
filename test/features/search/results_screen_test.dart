import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/share/share_service.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';
import 'package:on_air/features/search/presentation/results_screen.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_share_service.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('ar'));

ListingCard _card(String id, {bool withStay = false}) => ListingCard.fromJson({
  'id': id,
  'title': 'شقة $id',
  'property_type': 'apartment',
  'area_name': 'التجمع الخامس',
  'city_name': 'القاهرة الجديدة',
  'nightly_price_minor': 150000,
  'currency': 'EGP',
  'review_count': 3,
  'rating_avg': 4.5,
  if (withStay) 'stay': {'nights': 3, 'stay_total_minor': 450000},
});

void main() {
  late FakeConnectivity connectivity;
  late FakeListingsRepository listings;
  final today = DateOnly(2026, 11, 1);
  late SearchCubit cubit;

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    connectivity = FakeConnectivity();
    listings = FakeListingsRepository();
    cubit = SearchCubit(
      repo: listings,
      lastSearch: LastSearchStore(),
      connectivity: connectivity.createCubit(),
      today: () => today,
    );
  });

  tearDown(() {
    connectivity.dispose();
    unawaited(cubit.close());
  });

  Future<void> pumpHost(WidgetTester tester, {FakeShareService? share}) async {
    // A tall phone-sized window so list items beyond the first are built.
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final referenceCache = ReferenceDataCache(
      listings,
      JsonFileCache(
        directory: Directory.systemTemp.createTempSync('results_test'),
        fileName: 'x.json',
        schema: 1,
      ),
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => context.push('/search/results'),
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/search/results',
          builder: (_, _) => const ResultsScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ListingsRepository>.value(value: listings),
          RepositoryProvider<ReferenceDataCache>.value(value: referenceCache),
          RepositoryProvider<ShareService>.value(
            value: share ?? FakeShareService(),
          ),
          RepositoryProvider<ShareLinks>.value(
            value: const ShareLinks(linkDomain: 'on-air.website'),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ConnectivityCubit>.value(
              value: connectivity.createCubit(),
            ),
            BlocProvider<SearchCubit>.value(value: cubit),
          ],
          child: MaterialApp.router(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            // Skeletons pulse forever; freeze them so pumpAndSettle works.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openResults(WidgetTester tester) async {
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('loading shows skeletons', (tester) async {
    // A search whose response never arrives keeps the loading state up.
    listings.searchResponses.add(Completer<ResultsPage>().future);
    await pumpHost(tester);
    unawaited(cubit.search(SearchCriteria.empty));
    await openResults(tester);

    expect(find.byType(PropertyCardSkeleton), findsWidgets);
  });

  testWidgets('ready shows cards with the price, and the stay total only '
      'when dates are set', (tester) async {
    // The server sends stay totals only when the request carried dates.
    listings.searchResponses.add(
      ResultsPage(
        items: [_card('a', withStay: true), _card('b', withStay: true)],
        nextCursor: null,
        totalCount: 2,
      ),
    );
    await pumpHost(tester);
    unawaited(
      cubit.search(
        SearchCriteria.fromQuery(
          {'in': '2026-11-20', 'out': '2026-11-23'},
          today: today,
        ),
      ),
    );
    await openResults(tester);

    expect(find.byType(PropertyCard), findsNWidgets(2));
    expect(find.text(l10n.nightlyPrice('EGP 1,500.00')), findsNWidgets(2));
    expect(find.textContaining('إجمالي 3 ليالي'), findsNWidgets(2));

    // The same card without a stay section shows no total.
    listings.searchResponses.add(
      ResultsPage(items: [_card('c')], nextCursor: null, totalCount: 3),
    );
    await cubit.search(SearchCriteria.empty);
    await tester.pumpAndSettle();
    expect(find.byType(PropertyCard), findsOneWidget);
    expect(find.textContaining('إجمالي 3 ليالي'), findsNothing);
  });

  testWidgets('empty shows the empty message', (tester) async {
    listings.searchResponses.add(
      const ResultsPage(items: [], nextCursor: null, totalCount: 0),
    );
    await pumpHost(tester);
    unawaited(cubit.search(SearchCriteria.empty));
    await openResults(tester);

    expect(find.text(l10n.searchNoResults), findsOneWidget);
  });

  testWidgets('an error shows the message and the reference number', (
    tester,
  ) async {
    listings.searchResponses.add(
      const AppFailure(
        ApiError(
          code: ErrorCode.internal,
          messageKey: 'errorUnexpectedNoRef',
          requestId: 'REQ-7',
        ),
      ),
    );
    await pumpHost(tester);
    unawaited(cubit.search(SearchCriteria.empty));
    await openResults(tester);

    expect(find.textContaining('REQ-7'), findsOneWidget);
  });

  testWidgets('offline keeps the items and shows the banner', (tester) async {
    listings.searchResponses.add(
      ResultsPage(items: [_card('a')], nextCursor: 'c2', totalCount: 3),
    );
    await pumpHost(tester);
    unawaited(cubit.search(SearchCriteria.empty));
    await openResults(tester);
    expect(find.byType(PropertyCard), findsOneWidget);

    connectivity.goOffline();
    await tester.pumpAndSettle();
    expect(find.byType(PropertyCard), findsOneWidget);
    expect(find.text(l10n.offline), findsOneWidget);
  });

  testWidgets('removing a chip searches again', (tester) async {
    listings.searchResponses.add(
      ResultsPage(items: [_card('a')], nextCursor: null, totalCount: 1),
    );
    listings.searchResponses.add(
      ResultsPage(items: [_card('b')], nextCursor: null, totalCount: 1),
    );
    await pumpHost(tester);
    unawaited(
      cubit.search(SearchCriteria.fromQuery({'am': 'wifi'}, today: today)),
    );
    await openResults(tester);
    final callsAfterFirst = listings.calls.length;

    // The delete control carries the chip-remove tooltip with the chip's
    // label (the amenity key, since reference data is empty here).
    await tester.tap(find.byTooltip(l10n.filterChipRemove('wifi')).first);
    await tester.pumpAndSettle();

    expect(listings.calls.length, greaterThan(callsAfterFirst));
    expect(cubit.state.criteria.amenityKeys, isEmpty);
  });

  testWidgets('scrolling near the end calls loadMore once', (tester) async {
    listings.searchResponses.add(
      ResultsPage(
        items: [_card('a'), _card('b')],
        nextCursor: 'c2',
        totalCount: 4,
      ),
    );
    listings.searchResponses.add(
      ResultsPage(
        items: [_card('c'), _card('d')],
        nextCursor: null,
        totalCount: 4,
      ),
    );
    await pumpHost(tester);
    unawaited(cubit.search(SearchCriteria.empty));
    await openResults(tester);

    // Two cards overflow a phone-sized window; drag to the end.
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pump();
    await tester.drag(find.byType(PropertyCard).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(cubit.state.items, hasLength(4));
    expect(cubit.state.nextCursor, isNull);
  });

  testWidgets('datesDropped shows the banner', (tester) async {
    listings.searchResponses.add(
      const ResultsPage(items: [], nextCursor: null, totalCount: 5),
    );
    await pumpHost(tester);
    unawaited(cubit.openFromQuery({'in': '2026-10-01', 'out': '2026-10-05'}));
    await openResults(tester);

    expect(find.textContaining(l10n.searchDatesDropped), findsOneWidget);
  });

  testWidgets('the app bar share action shares the canonical search link', (
    tester,
  ) async {
    listings.searchResponses.add(
      const ResultsPage(items: [], nextCursor: null, totalCount: 1),
    );
    final share = FakeShareService();
    await pumpHost(tester, share: share);
    unawaited(cubit.search(const SearchCriteria(guests: 2)));
    await openResults(tester);

    await tester.tap(find.byTooltip(l10n.searchShare));
    await tester.pump();

    expect(share.shared, hasLength(1));
    expect(share.shared.single, startsWith('${l10n.shareSearchText}\n'));
    expect(
      share.shared.single,
      endsWith('https://on-air.website/search/results?g=2'),
    );
  });
}
