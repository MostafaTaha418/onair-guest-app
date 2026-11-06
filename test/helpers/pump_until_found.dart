import 'package:flutter_test/flutter_test.dart';

/// Waits for async mock data or route transitions on slower device runners.
///
/// The default covers the slowest observed iOS runner (~15 s of real time
/// for a home-page load); failures still stop after 20 s.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 80,
}) async {
  for (
    var attempt = 0;
    attempt < maxAttempts && !tester.any(finder);
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsWidgets);
}
