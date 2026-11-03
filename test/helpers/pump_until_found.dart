import 'package:flutter_test/flutter_test.dart';

/// Waits for async mock data or route transitions on slower device runners.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40 && !tester.any(finder); attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsWidgets);
}
