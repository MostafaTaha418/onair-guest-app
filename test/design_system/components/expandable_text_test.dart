import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/expandable_text.dart';

void main() {
  Future<void> pumpText(WidgetTester tester, String text) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: ExpandableText(
              text: text,
              moreLabel: 'عرض المزيد',
              lessLabel: 'عرض أقل',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a short text shows no toggle', (tester) async {
    await pumpText(tester, 'نص قصير');

    expect(find.text('عرض المزيد'), findsNothing);
    expect(find.text('نص قصير'), findsOneWidget);
  });

  testWidgets('an overflowing text shows the toggle and expands', (
    tester,
  ) async {
    final long = 'هذا نص طويل جداً ' * 20;
    await pumpText(tester, long);

    expect(find.text('عرض المزيد'), findsOneWidget);

    await tester.tap(find.text('عرض المزيد'));
    await tester.pump();

    expect(find.text('عرض أقل'), findsOneWidget);
    expect(find.text('عرض المزيد'), findsNothing);

    await tester.tap(find.text('عرض أقل'));
    await tester.pump();

    expect(find.text('عرض المزيد'), findsOneWidget);
  });
}
