import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/area_card.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

void main() {
  testWidgets('renders the area name and the listing count', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: OnAirTheme.light,
        home: Scaffold(
          body: Center(
            child: AreaCard(
              title: 'التجمع الخامس',
              countLabel: '42 شقة',
              imageVariants: const [],
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('التجمع الخامس'), findsOneWidget);
    expect(find.text('42 شقة'), findsOneWidget);

    await tester.tap(find.text('التجمع الخامس'));
    expect(tapped, isTrue);
  });
}
