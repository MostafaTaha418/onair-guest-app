import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/brand/on_air_logo.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/on_air_colors.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _app(Widget child, {String locale = 'en', ThemeMode? mode}) =>
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: OnAirTheme.light,
      darkTheme: OnAirTheme.dark,
      themeMode: mode ?? ThemeMode.light,
      home: Scaffold(body: Center(child: child)),
    );

Size _size(WidgetTester tester) => tester.getSize(
  find.descendant(
    of: find.byType(OnAirLogo),
    matching: find.byType(CustomPaint),
  ),
);

void _expectColor(WidgetTester tester, Color color) => expect(
  tester.renderObject(
    find.descendant(
      of: find.byType(OnAirLogo),
      matching: find.byType(CustomPaint),
    ),
  ),
  paints..path(color: color),
);

void main() {
  testWidgets('mark keeps the 50:65 brand proportions', (tester) async {
    await tester.pumpWidget(_app(const OnAirLogo.mark(height: 65)));
    expect(_size(tester), const Size(50, 65));
  });

  testWidgets('lockup follows the app language', (tester) async {
    await tester.pumpWidget(_app(const OnAirLogo.lockup(height: 89.405)));
    expect(_size(tester).width, closeTo(330.95, 0.01));

    await tester.pumpWidget(
      _app(const OnAirLogo.lockup(height: 132.7), locale: 'ar'),
    );
    await tester.pumpAndSettle();
    expect(_size(tester).width, closeTo(400.95, 0.01));
  });

  testWidgets('wordmark uses one type size across languages', (tester) async {
    await tester.pumpWidget(_app(const OnAirLogo.wordmark(size: 100)));
    final latin = _size(tester);
    await tester.pumpWidget(
      _app(const OnAirLogo.wordmark(size: 100), locale: 'ar'),
    );
    await tester.pumpAndSettle();
    final arabic = _size(tester);
    // Same em; Arabic carries dots and descenders so its box is taller.
    expect(latin.height, lessThan(100));
    expect(arabic.height, greaterThan(latin.height));
  });

  testWidgets('colour follows the theme unless one is given', (tester) async {
    await tester.pumpWidget(_app(const OnAirLogo.mark()));
    _expectColor(tester, OnAirColors.light['logo']);

    await tester.pumpWidget(_app(const OnAirLogo.mark(), mode: ThemeMode.dark));
    await tester.pumpAndSettle();
    _expectColor(tester, OnAirColors.dark['logo']);

    await tester.pumpWidget(
      _app(const OnAirLogo.mark(color: Color(0xFF123456))),
    );
    _expectColor(tester, const Color(0xFF123456));
  });

  testWidgets('screen readers hear the brand name', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const OnAirLogo.lockup()));
    expect(find.bySemanticsLabel(OnAirLogo.brandName), findsOneWidget);
    semantics.dispose();
  });
}
