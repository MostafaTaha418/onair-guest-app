import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/components/area_card.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:on_air/features/search/presentation/results_screen.dart';
import 'package:on_air/features/search/presentation/search_screen.dart';

import '../../helpers/fake_listings_repository.dart';
import '../test_app_harness.dart';

/// Enough newest cards for the Home scroll-position test to actually
/// scroll; queued several times because a signed-in start also refetches.
FakeListingsRepository _scrollableListings() =>
    FakeListingsRepository()
      ..homeFeedResponses.addAll([_feed(), _feed(), _feed()]);

HomeFeed _feed() => HomeFeed(
  referenceVersion: 'mock-ref-1',
  areas: const FeedSectionReady([]),
  suggested: const FeedSectionReady([]),
  newest: FeedSectionReady([
    for (var index = 0; index < 12; index++)
      ListingCard(
        id: '550e8400-e29b-41d4-a716-${index.toString().padLeft(12, '0')}',
        title: 'شقة $index',
        propertyType: 'apartment',
        areaName: 'التجمع الخامس',
        cityName: 'القاهرة الجديدة',
        cover: null,
        nightlyPrice: Money(150000),
        ratingAvg: null,
        reviewCount: 0,
        stay: null,
      ),
  ]),
  upcomingBooking: const FeedSectionReady<UpcomingBookingCard?>(null),
  fetchedAt: DateTime.utc(2026, 10, 28, 10),
);

HomeFeed _areasFeed() {
  final base = _feed();
  return HomeFeed(
    referenceVersion: base.referenceVersion,
    areas: FeedSectionReady([
      for (var index = 0; index < 6; index++)
        AreaTile(
          locationId:
              '550e8400-e29b-41d4-a716-${index.toString().padLeft(12, '0')}',
          name: 'منطقة $index',
          listingCount: index + 1,
          image: null,
        ),
    ]),
    suggested: base.suggested,
    newest: base.newest,
    upcomingBooking: base.upcomingBooking,
    fetchedAt: base.fetchedAt,
  );
}

void main() {
  testWidgets('available today previews five and View all loads every match', (
    tester,
  ) async {
    final todayCards = [
      for (var index = 0; index < 6; index++)
        ListingCard(
          id: '550e8400-e29b-41d4-a716-${index.toString().padLeft(12, '0')}',
          title: 'متاح رقم $index',
          propertyType: 'apartment',
          areaName: 'رأس البر',
          cityName: 'دمياط',
          cover: null,
          nightlyPrice: Money(150000),
          ratingAvg: null,
          reviewCount: 0,
          stay: null,
        ),
    ];
    final page = ResultsPage(
      items: todayCards,
      nextCursor: null,
      totalCount: todayCards.length,
    );
    final listings = FakeListingsRepository()
      ..homeFeedResponses.add(_feed())
      ..searchResponses.addAll([page, page]);
    await pumpVisitorApp(tester, listingsRepository: listings);
    expect(find.text('متاح رقم 5', skipOffstage: false), findsNothing);
    final seeAll = find.text('عرض الكل').first;
    await tester.ensureVisible(seeAll);
    await tester.tap(seeAll);
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(find.byType(ListView).last);
    expect(list.childrenDelegate.estimatedChildCount, 6);
    expect(listings.searchParams.last.stay!.checkIn, CairoTime.today());
  });

  testWidgets('areas show five on Home and all six in a narrow grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final listings = FakeListingsRepository()
      ..homeFeedResponses.addAll([_areasFeed(), _areasFeed()]);
    await pumpVisitorApp(tester, listingsRepository: listings);
    final homeAreas = tester.widget<ListView>(
      find
          .ancestor(
            of: find.byType(AreaCard).first,
            matching: find.byType(ListView),
          )
          .first,
    );
    expect(homeAreas.childrenDelegate.estimatedChildCount, 5);
    await tester.tap(find.text('عرض الكل').first);
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.childrenDelegate.estimatedChildCount, 6);
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home search and filters open separate destinations', (
    tester,
  ) async {
    await pumpVisitorApp(tester);
    await tester.tap(find.byKey(const ValueKey('home-search-box')));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-search')), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OnAirPrimaryButton).last);
    await tester.pumpAndSettle();
    expect(find.byType(ResultsScreen), findsOneWidget);
    expect(find.byType(SearchScreen), findsNothing);
  });

  testWidgets('newest View all requests newest sorted results', (tester) async {
    final listings = _scrollableListings();
    listings.searchResponses.addAll([
      const ResultsPage(items: [], nextCursor: null, totalCount: 0),
      const ResultsPage(items: [], nextCursor: null, totalCount: 0),
    ]);
    await pumpVisitorApp(tester, listingsRepository: listings);
    final seeAll = find.text('عرض الكل').last;
    await tester.ensureVisible(seeAll);
    await tester.tap(seeAll);
    await tester.pumpAndSettle();
    expect(listings.searchParams.last.sort, SearchSort.newest);
    expect(find.text('أحدث الشقق'), findsOneWidget);
  });

  testWidgets('compact phone keeps the home controls and tabs visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpVisitorApp(tester);

    expect(find.byKey(const ValueKey('home-brand-lockup')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-favorites-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-filter-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-notifications')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('four tabs are RTL, highlight selection, and keep Home scroll', (
    tester,
  ) async {
    await pumpSignedInApp(tester, listingsRepository: _scrollableListings());
    const tabs = ['home', 'bookings', 'notifications', 'account'];
    expect(find.byKey(const ValueKey('nav-search')), findsNothing);
    for (final name in tabs) {
      expect(find.byKey(ValueKey('nav-$name')), findsOneWidget);
    }
    expect(
      tester.getCenter(find.byKey(const ValueKey('nav-home'))).dx,
      greaterThan(
        tester.getCenter(find.byKey(const ValueKey('nav-account'))).dx,
      ),
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('nav-home')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.drag(
      find.byKey(const ValueKey('home-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    // The Home content also hosts horizontal section lists; the scroll
    // position that must survive tab switches is the vertical one.
    final homeScrollable = find.descendant(
      of: find.byKey(const ValueKey('home-scroll')),
      matching: find.byType(Scrollable),
    );
    ScrollableState verticalScrollable() => tester
        .stateList<ScrollableState>(homeScrollable)
        .firstWhere((scrollable) => scrollable.widget.axis == Axis.vertical);
    final before = verticalScrollable().position.pixels;
    expect(before, greaterThan(0));

    for (final name in tabs.skip(1)) {
      await tester.tap(find.byKey(ValueKey('nav-$name')));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byKey(ValueKey('nav-$name')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
    }
    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    expect(verticalScrollable().position.pixels, before);
  });

  testWidgets('visitor can cancel members-only sign-in back to the origin', (
    tester,
  ) async {
    await pumpVisitorApp(tester);

    await tester.tap(find.byKey(const ValueKey('nav-bookings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close-login-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('close-login-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('nav-home')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('home favorites opens sign-in for a visitor', (tester) async {
    await pumpVisitorApp(tester);
    expect(find.byKey(const ValueKey('nav-favorites')), findsNothing);
    expect(find.byKey(const ValueKey('nav-notifications')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-favorites-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close-login-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('close-login-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-favorites-button')), findsOneWidget);
  });

  testWidgets('home favorites opens its page for a signed-in guest', (
    tester,
  ) async {
    await pumpSignedInApp(tester);
    await tester.tap(find.byKey(const ValueKey('home-favorites-button')));
    await tester.pumpAndSettle();
    expect(find.text('المفضلة'), findsWidgets);
    expect(find.byKey(const ValueKey('nav-favorites')), findsNothing);
  });

  testWidgets('a visitor tapping a card heart is sent to sign-in', (
    tester,
  ) async {
    await pumpVisitorApp(tester, listingsRepository: _scrollableListings());
    await tester.drag(
      find.byKey(const ValueKey('home-scroll')),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    final heart = find.byTooltip('إضافة إلى المفضلة').first;
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close-login-button')), findsOneWidget);
  });

  testWidgets('a signed-in guest saves a card and sees it in favorites', (
    tester,
  ) async {
    await pumpSignedInApp(tester, listingsRepository: _scrollableListings());
    await tester.drag(
      find.byKey(const ValueKey('home-scroll')),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    final heart = find.byTooltip('إضافة إلى المفضلة').first;
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(find.byTooltip('إزالة من المفضلة'), findsWidgets);

    await tester.drag(
      find.byKey(const ValueKey('home-scroll')),
      const Offset(0, 900),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-favorites-button')));
    await tester.pumpAndSettle();
    expect(find.text('شقة 0'), findsWidgets);
    expect(find.byTooltip('إزالة من المفضلة'), findsWidgets);
  });
}
