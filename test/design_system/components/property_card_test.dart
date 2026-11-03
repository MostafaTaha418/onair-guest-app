import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/rating_badge.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Future<void> pumpCard(
  WidgetTester tester,
  PropertyCard card, {
  TextDirection direction = TextDirection.rtl,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OnAirTheme.light,
      locale: direction == TextDirection.rtl
          ? const Locale('ar')
          : const Locale('en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Directionality(
          textDirection: direction,
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

  testWidgets('price and title mirror between English and Arabic', (
    tester,
  ) async {
    PropertyCard card() => PropertyCard(
      title: 'شقة',
      subtitle: 'رأس البر',
      imageVariants: const [],
      priceText: '950 EGP',
      onTap: () {},
    );
    await pumpCard(tester, card());
    final rtlEdge = tester.getTopLeft(find.byType(PropertyCard)).dx + 16;
    expect(tester.getTopLeft(find.text('950 EGP')).dx, closeTo(rtlEdge, 1));
    expect(
      tester.getTopLeft(find.text('شقة')).dx,
      greaterThan(tester.getTopLeft(find.text('950 EGP')).dx),
    );
    await pumpCard(tester, card(), direction: TextDirection.ltr);
    final ltrEdge = tester.getTopRight(find.byType(PropertyCard)).dx - 16;
    expect(tester.getTopRight(find.text('950 EGP')).dx, closeTo(ltrEdge, 1));
    expect(
      tester.getTopLeft(find.text('شقة')).dx,
      lessThan(tester.getTopLeft(find.text('950 EGP')).dx),
    );
  });

  testWidgets('offer badge appears only with offer data', (tester) async {
    PropertyCard card({String? offer}) => PropertyCard(
      title: 'شقة',
      subtitle: 'رأس البر',
      imageVariants: const [],
      priceText: '950 EGP',
      availabilityLabel: 'متاح من اليوم',
      offerLabel: offer,
      onTap: () {},
    );
    await pumpCard(tester, card());
    expect(find.text('متاح من اليوم'), findsOneWidget);
    expect(find.text('خصم'), findsNothing);
    await pumpCard(tester, card(offer: 'خصم'));
    expect(find.text('خصم'), findsOneWidget);
  });
}
