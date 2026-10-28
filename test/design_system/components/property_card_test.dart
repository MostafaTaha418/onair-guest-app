import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/rating_badge.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

Future<void> pumpCard(WidgetTester tester, PropertyCard card) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OnAirTheme.light,
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SizedBox(width: 300, child: card),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the rating is hidden when ratingText is null', (tester) async {
    await pumpCard(
      tester,
      PropertyCard(
        title: 'شقة 3 غرف بإطلالة',
        subtitle: 'التجمع الخامس • القاهرة الجديدة',
        imageVariants: const [],
        priceText: 'EGP 1,500.00',
        onTap: () {},
      ),
    );
    expect(find.byType(RatingBadge), findsNothing);
    expect(find.text('شقة 3 غرف بإطلالة'), findsOneWidget);
  });

  testWidgets('the rating shows when provided', (tester) async {
    await pumpCard(
      tester,
      PropertyCard(
        title: 'شقة 3 غرف بإطلالة',
        subtitle: 'التجمع الخامس • القاهرة الجديدة',
        imageVariants: const [],
        priceText: 'EGP 1,500.00',
        ratingText: '4.6',
        ratingSemantics: 'التقييم 4.6 من 5، 12 تقييم',
        onTap: () {},
      ),
    );
    expect(find.byType(RatingBadge), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
  });

  testWidgets('the stay total renders as the price caption', (tester) async {
    await pumpCard(
      tester,
      PropertyCard(
        title: 'شقة',
        subtitle: 'الرحاب • القاهرة الجديدة',
        imageVariants: const [],
        priceText: 'EGP 1,200.00',
        stayTotalText: 'إجمالي 3 ليالي: EGP 3,600.00',
        onTap: () {},
      ),
    );
    expect(find.text('إجمالي 3 ليالي: EGP 3,600.00'), findsOneWidget);
  });

  testWidgets('onTap fires when the card is tapped', (tester) async {
    var taps = 0;
    await pumpCard(
      tester,
      PropertyCard(
        title: 'شقة',
        subtitle: 'الرحاب • القاهرة الجديدة',
        imageVariants: const [],
        priceText: 'EGP 1,200.00',
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.text('شقة'));
    await tester.pump();
    expect(taps, 1);
  });
}
