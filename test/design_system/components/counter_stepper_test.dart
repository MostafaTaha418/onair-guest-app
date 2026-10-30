import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/counter_stepper.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

Future<void> pumpStepper(
  WidgetTester tester, {
  required int value,
  required int min,
  required int max,
  required ValueChanged<int> onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OnAirTheme.light,
      home: Scaffold(
        body: Center(
          child: CounterStepper(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            label: 'عدد الضيوف',
            decrementTooltip: 'قلّل',
            incrementTooltip: 'زوّد',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the minus button is disabled at the minimum', (tester) async {
    var value = 1;
    await pumpStepper(
      tester,
      value: value,
      min: 1,
      max: 50,
      onChanged: (next) => value = next,
    );
    Finder iconButton(String tooltip) => find
        .ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        )
        .first;
    expect(tester.widget<IconButton>(iconButton('قلّل')).onPressed, isNull);

    await tester.tap(iconButton('زوّد'));
    expect(value, 2);
  });

  testWidgets('the plus button is disabled at the maximum', (tester) async {
    var value = 50;
    await pumpStepper(
      tester,
      value: value,
      min: 1,
      max: 50,
      onChanged: (next) => value = next,
    );
    Finder iconButton(String tooltip) => find
        .ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        )
        .first;
    expect(
      tester.widget<IconButton>(iconButton('زوّد')).onPressed,
      isNull,
    );
    await tester.tap(iconButton('قلّل'));
    expect(value, 49);
  });

  testWidgets('the value is readable in the semantics', (tester) async {
    await pumpStepper(
      tester,
      value: 3,
      min: 1,
      max: 50,
      onChanged: (_) {},
    );
    final semantics = tester.getSemantics(find.text('3'));
    expect(semantics.value, '3');
    // The label merges with the rendered value for screen readers.
    expect(semantics.label, contains('عدد الضيوف'));
  });
}
