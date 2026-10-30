import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/filter_chip_bar.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

void main() {
  testWidgets('renders nothing when the chip list is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OnAirTheme.light,
        home: const Scaffold(body: FilterChipBar(chips: [])),
      ),
    );
    expect(find.byType(InputChip), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('renders one chip per entry with its remove tooltip', (
    tester,
  ) async {
    final removed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: OnAirTheme.light,
        home: Scaffold(
          body: FilterChipBar(
            chips: [
              (
                label: 'واي فاي',
                removeTooltip: 'شيل فلتر واي فاي',
                onRemove: () => removed.add('wifi'),
              ),
              (
                label: '2+ غرف',
                removeTooltip: 'شيل فلتر 2+ غرف',
                onRemove: () => removed.add('bed'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(InputChip), findsNWidgets(2));
    expect(find.text('واي فاي'), findsOneWidget);

    await tester.tap(find.byTooltip('شيل فلتر واي فاي'));
    expect(removed, ['wifi']);
  });
}
