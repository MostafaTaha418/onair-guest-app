import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/area_card.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/home/presentation/home_cubit.dart';
import 'package:on_air/features/home/presentation/home_screen.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';

void main() {
  late FakeListingsRepository listings;
  late FakeConnectivity connectivity;
  late FakeAuthRepository auth;
  late Directory directory;
  late JsonFileCache cache;

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  setUp(() {
    listings = FakeListingsRepository();
    connectivity = FakeConnectivity();
    auth = FakeAuthRepository();
    directory = Directory.systemTemp.createTempSync('on_air_home_screen');
    cache = JsonFileCache(
      directory: directory,
      fileName: 'discovery_cache.json',
      schema: 1,
    );
  });

  tearDown(() {
    connectivity.dispose();
    unawaited(auth.dispose());
    directory.deleteSync(recursive: true);
  });

  final l10n = lookupAppLocalizations(const Locale('ar'));

  ListingCard card(String id, String title) => ListingCard(
    id: id,
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

  HomeFeed feed({
    bool withBooking = false,
    FeedSection<List<ListingCard>>? suggested,
  }) => HomeFeed(
    referenceVersion: 'mock-ref-1',
    areas: const FeedSectionReady([
      AreaTile(
        locationId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        name: 'التجمع الخامس',
        listingCount: 42,
        image: null,
      ),
    ]),
    suggested: suggested ?? FeedSectionReady([card('p1', 'شقة مقترحة')]),
    newest: FeedSectionReady([card('p2', 'شقة أحدث')]),
    upcomingBooking: withBooking
        ? FeedSectionReady(
            UpcomingBookingCard(
              bookingId: 'b1',
              propertyTitle: 'شقة محجوزة',
              checkIn: DateOnly(2026, 11, 20),
              checkOut: DateOnly(2026, 11, 23),
              status: 'confirmed',
            ),
          )
        : const FeedSectionReady<UpcomingBookingCard?>(null),
    fetchedAt: DateTime.utc(2026, 10, 28, 10),
  );

  Future<void> pumpHome(
    WidgetTester tester, {
    required bool signedIn,
    HomeFeed? cachedFeed,
    bool offline = false,
  }) async {
    if (cachedFeed != null) {
      await HomeFeedCache(cache).save(cachedFeed);
    }
    if (signedIn) {
      auth.account = GuestAccount(
        id: 'guest',
        phone: '+201012345678',
        phoneVerified: true,
        fullName: 'زائر تجريبي',
        acceptedTermsVersion: 'v1',
        acceptedTermsAt: DateTime.utc(2026),
      );
    }
    final authCubit = AuthCubit(auth, currentTermsVersion: 'v1');
    unawaited(authCubit.restore());
    addTearDown(authCubit.close);
    final connectivityCubit = connectivity.createCubit();
    addTearDown(connectivityCubit.close);
    // The cubit must be subscribed before the offline event is broadcast;
    // pump so the fake-async timers (checkConnectivity, the event) fire.
    if (offline) {
      connectivity.goOffline();
      await tester.pump(const Duration(milliseconds: 50));
    }
    // A tall surface keeps every section on screen for taps and lookups.
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, _) => BlocProvider<HomeCubit>(
            create: (context) {
              final cubit = HomeCubit(
                repo: listings,
                cache: HomeFeedCache(cache),
                reference: ReferenceDataCache(listings, cache),
                connectivity: connectivityCubit,
                auth: authCubit,
              );
              unawaited(cubit.start());
              return cubit;
            },
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.searchResults,
          builder: (_, state) =>
              Text('results:${state.uri.queryParameters['loc']}'),
        ),
        GoRoute(
          path: '/property/:id',
          builder: (_, state) => Text('property:${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/bookings/:id',
          builder: (_, state) => Text('booking:${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ListingsRepository>.value(value: listings),
          RepositoryProvider<JsonFileCache>.value(value: cache),
          RepositoryProvider<ReferenceDataCache>.value(
            value: ReferenceDataCache(listings, cache),
          ),
          RepositoryProvider<HomeFeedCache>.value(value: HomeFeedCache(cache)),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
          ],
          // The global offline banner, exactly as app.dart renders it.
          child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivityState) => MaterialApp.router(
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: OnAirTheme.light,
              routerConfig: router,
              builder: (context, child) => Stack(
                children: [
                  ?child,
                  if (!connectivityState.isOnline)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: OfflineBanner(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('every section shows a skeleton while loading', (tester) async {
    final pending = Completer<HomeFeed>();
    listings.homeFeedResponses.add(pending.future);
    await pumpHome(tester, signedIn: false);

    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(AreaCard), findsNothing);

    pending.complete(feed());
    await tester.pump();
    await tester.pump();
    expect(find.byType(SkeletonBox), findsNothing);
  });

  testWidgets('a failed section shows retry while the others render', (
    tester,
  ) async {
    listings.homeFeedResponses.add(
      feed(
        suggested: const FeedSectionFailed<List<ListingCard>>('INTERNAL', null),
      ),
    );
    await pumpHome(tester, signedIn: false);

    expect(find.text(l10n.retry), findsOneWidget);
    expect(find.text('التجمع الخامس'), findsOneWidget);
    expect(find.text('شقة أحدث'), findsOneWidget);
  });

  testWidgets('the area tap opens the results for that location', (
    tester,
  ) async {
    listings.homeFeedResponses.add(feed());
    await pumpHome(tester, signedIn: false);

    await tester.tap(find.text('التجمع الخامس'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('results:f47ac10b-58cc-4372-a567-0e02b2c3d479'),
      findsOneWidget,
    );
  });

  testWidgets('the card tap pushes the property route', (tester) async {
    listings.homeFeedResponses.add(feed());
    await pumpHome(tester, signedIn: false);

    await tester.tap(find.text('شقة مقترحة'));
    await tester.pump();
    await tester.pump();

    expect(find.text('property:p1'), findsOneWidget);
  });

  testWidgets('the greeting shows the name only when signed in', (
    tester,
  ) async {
    listings.homeFeedResponses.addAll([feed(), feed()]);
    await pumpHome(tester, signedIn: true);

    expect(find.text(l10n.homeHello), findsOneWidget);
    expect(find.text('زائر تجريبي'), findsOneWidget);
  });

  testWidgets('the visitor greeting has no name', (tester) async {
    listings.homeFeedResponses.add(feed());
    await pumpHome(tester, signedIn: false);

    expect(find.text(l10n.homeHello), findsOneWidget);
    expect(find.text('زائر تجريبي'), findsNothing);
  });

  testWidgets('the upcoming card shows only for a signed-in guest with data', (
    tester,
  ) async {
    listings.homeFeedResponses.addAll([
      feed(withBooking: true),
      feed(withBooking: true),
    ]);
    await pumpHome(tester, signedIn: true);

    expect(find.text('شقة محجوزة'), findsOneWidget);
    expect(find.text(l10n.homeUpcomingConfirmed), findsOneWidget);
  });

  testWidgets('a cached feed plus an offline fake render within one frame', (
    tester,
  ) async {
    // SC-004: the cache is on disk and the network is gone; the content
    // and the offline banner are there right after the first pump.
    await HomeFeedCache(cache).save(feed());
    listings.homeFeedResponses.add(AppFailure(ErrorMapper.noResponse()));
    await pumpHome(
      tester,
      signedIn: false,
      cachedFeed: feed(),
      offline: true,
    );

    expect(find.text('شقة مقترحة'), findsOneWidget);
    expect(find.text(l10n.offline), findsOneWidget);
    expect(find.byType(SkeletonBox), findsNothing);
  });

  testWidgets('the empty state shows when every section is empty', (
    tester,
  ) async {
    listings.homeFeedResponses.add(
      HomeFeed(
        referenceVersion: 'mock-ref-1',
        areas: const FeedSectionReady(<AreaTile>[]),
        suggested: const FeedSectionReady(<ListingCard>[]),
        newest: const FeedSectionReady(<ListingCard>[]),
        upcomingBooking: const FeedSectionReady<UpcomingBookingCard?>(null),
        fetchedAt: DateTime.utc(2026, 10, 28, 10),
      ),
    );
    await pumpHome(tester, signedIn: false);

    expect(find.text(l10n.homeEmpty), findsOneWidget);
    expect(find.text(l10n.homeEmptyAction), findsOneWidget);
  });
}
