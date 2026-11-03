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

  for (final (name, theme) in [
    ('light', OnAirTheme.light),
    ('dark', OnAirTheme.dark),
  ]) {
    testWidgets('listing count stays readable in $name mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: AreaCard(
              title: 'التجمع الخامس',
              countLabel: '42 شقة',
              imageVariants: const [],
              onTap: () {},
            ),
          ),
        ),
      );

      final label = find.text('42 شقة');
      final foreground = tester.widget<Text>(label).style!.color!;
      final badge = tester.widget<Container>(
        find.ancestor(of: label, matching: find.byType(Container)).first,
      );
      final background = (badge.decoration! as BoxDecoration).color!;
      final lighter =
          foreground.computeLuminance() > background.computeLuminance()
          ? foreground
          : background;
      final darker = identical(lighter, foreground) ? background : foreground;
      final contrast =
          (lighter.computeLuminance() + 0.05) /
          (darker.computeLuminance() + 0.05);

      expect(contrast, greaterThanOrEqualTo(4.5));
    });
  }
}
