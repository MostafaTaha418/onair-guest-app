import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

bool _hasMatch(Finder finder) {
  try {
    return finder.evaluate().isNotEmpty;
    // Chained finders such as `find.byType(...).first` throw when their
    // parent disappears during a route transition, so this Error is expected.
    // ignore: avoid_catching_errors
  } on StateError {
    return false;
  }
}

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
    attempt < maxAttempts && !_hasMatch(finder);
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(_hasMatch(finder), isTrue, reason: 'Expected to find $finder');
}

/// Makes a control hit-testable on real simulators before tapping it.
///
/// iOS keeps the software keyboard open after [WidgetTester.enterText], which
/// can leave a visually built submit button outside the tappable viewport.
Future<void> tapVisible(
  WidgetTester tester,
  Finder finder, {
  bool dismissKeyboard = false,
}) async {
  if (dismissKeyboard) {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }
  await pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Taps a navigation control and waits for its destination, retrying only
/// while the original control is still present. This absorbs occasional
/// missed native-device taps without hiding a broken route transition.
Future<void> tapAndWait(
  WidgetTester tester,
  Finder finder,
  Finder destination, {
  bool dismissKeyboard = false,
  int tapAttempts = 3,
}) async {
  if (dismissKeyboard) {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }
  await pumpUntilFound(tester, finder);
  for (var tapAttempt = 0; tapAttempt < tapAttempts; tapAttempt++) {
    if (_hasMatch(destination)) return;
    if (!_hasMatch(finder)) break;
    await tapVisible(
      tester,
      finder,
    );
    for (
      var pumpAttempt = 0;
      pumpAttempt < 20 && !_hasMatch(destination);
      pumpAttempt++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
  await pumpUntilFound(tester, destination);
}
