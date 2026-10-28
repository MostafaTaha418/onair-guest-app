import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/price_text.dart';
import 'package:on_air/design_system/components/rating_badge.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OnAirTheme.light,
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('RatingBadge shows the star and exposes the semantics label', (
    tester,
  ) async {
    await pump(
      tester,
      const RatingBadge(ratingText: '4.6', semanticsLabel: 'التقييم 4.6 من 5'),
    );
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
    final semantics = tester.getSemantics(find.text('4.6'));
    expect(semantics.label, 'التقييم 4.6 من 5');
  });

  testWidgets('PriceText shows the price and the optional caption', (
    tester,
  ) async {
    await pump(tester, const PriceText(price: 'EGP 1,500.00'));
    expect(find.text('EGP 1,500.00'), findsOneWidget);
    expect(find.byType(Column), findsOneWidget);

    await pump(
      tester,
      const PriceText(price: 'EGP 1,500.00', caption: 'إجمالي 3 ليالي'),
    );
    expect(find.text('EGP 1,500.00'), findsOneWidget);
    expect(find.text('إجمالي 3 ليالي'), findsOneWidget);
  });
}
