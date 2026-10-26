import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_app_harness.dart';

void main() {
  testWidgets('five tabs are RTL, highlight selection, and keep Home scroll', (
    tester,
  ) async {
    await pumpVisitorApp(tester);
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
    final homeScrollable = find.descendant(
      of: find.byKey(const ValueKey('home-scroll')),
      matching: find.byType(Scrollable),
    );
    final before = tester
        .state<ScrollableState>(homeScrollable)
        .position
        .pixels;
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
    expect(
      tester.state<ScrollableState>(homeScrollable).position.pixels,
      before,
    );
  });
}
