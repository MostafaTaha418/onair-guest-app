import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';

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

void main() {
  testWidgets('five tabs are RTL, highlight selection, and keep Home scroll', (
    tester,
  ) async {
    await pumpSignedInApp(tester, listingsRepository: _scrollableListings());
    const tabs = ['home', 'search', 'bookings', 'favorites', 'account'];
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

    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-bookings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('close-login-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('close-login-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-search')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('nav-search')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });
}
