import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

void main() {
  testWidgets('renders the leading and the action side by side', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OnAirTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              BottomActionBar(
                leading: const Text('السعر'),
                action: TextButton(
                  onPressed: () {},
                  child: const Text('احجز الآن'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('السعر'), findsOneWidget);
    expect(find.text('احجز الآن'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('احجز الآن')).dx >
          tester.getTopLeft(find.text('السعر')).dx,
      isTrue,
      reason: 'the action sits at the end of the row',
    );
  });
}
