import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app_harness.dart';

void main() {
  testWidgets('English device locale still renders Arabic RTL', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    await pumpVisitorApp(tester);
    expect(find.text('الرئيسية'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('الرئيسية').first)),
      TextDirection.rtl,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('ar'),
    );
  });

  testWidgets('system dark mode and text scaling update the visitor shell', (
    tester,
  ) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    await pumpVisitorApp(tester);
    final context = tester.element(find.byKey(const ValueKey('home-scroll')));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(MediaQuery.textScalerOf(context).scale(20), 26);
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    await tester.pumpAndSettle();
    expect(Theme.of(context).brightness, Brightness.light);
  });
}
