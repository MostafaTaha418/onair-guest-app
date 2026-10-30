import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

void main() {
  Future<void> pumpImage(
    WidgetTester tester, {
    required List<ImageVariant> variants,
    String? heroTag,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OnAirTheme.light,
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 200,
              height: 120,
              child: OnAirNetworkImage(variants: variants, heroTag: heroTag),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('empty variants show only the placeholder', (tester) async {
    await pumpImage(tester, variants: const []);
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(ColoredBox), findsWidgets);
    expect(
      find.byIcon(Icons.image_not_supported_outlined),
      findsNothing,
    );
  });

  testWidgets('the hero tag is applied', (tester) async {
    await pumpImage(tester, variants: const [], heroTag: 'listing-1');
    expect(find.byType(Hero), findsOneWidget);
    expect(
      tester.widget<Hero>(find.byType(Hero)).tag,
      'listing-1',
    );
  });

  testWidgets('no hero is created without a tag', (tester) async {
    await pumpImage(tester, variants: const []);
    expect(find.byType(Hero), findsNothing);
  });
}
