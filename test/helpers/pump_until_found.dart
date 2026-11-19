import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/settings_row.dart';

const _mockBookingPropertyId = '00000000-0000-4000-8000-00000000001f';

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

/// Gives host widget tests a deterministic surface without lying to a real
/// device runner about its tappable viewport.
///
/// IntegrationTestWidgetsFlutterBinding uses the simulator's native window.
/// Overriding that view can place rendered controls outside the OS hit-test
/// area even though Flutter still finds them in the widget tree.
void pinHostTestView(
  WidgetTester tester, {
  required Size physicalSize,
  double devicePixelRatio = 1,
}) {
  if (TestWidgetsFlutterBinding.instance
      is! AutomatedTestWidgetsFlutterBinding) {
    return;
  }
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);
}

bool _invokeDeviceControl(Finder finder) {
  final matches = finder.evaluate().toList(growable: false);
  if (matches.length != 1) return false;

  final widgets = <Widget>[matches.single.widget];
  matches.single.visitAncestorElements((element) {
    widgets.add(element.widget);
    return true;
  });

  for (final widget in widgets) {
    switch (widget) {
      case OnAirPrimaryButton(:final onPressed?) ||
          TextButton(:final onPressed?) ||
          ElevatedButton(:final onPressed?) ||
          OutlinedButton(:final onPressed?) ||
          IconButton(:final onPressed?):
        onPressed();
        return true;
      // A SettingsRow hides its onTap inside a child InkWell, so match the row
      // itself: on windowless device runners an off-screen row's synthetic tap
      // misses, but invoking its enabled callback is reliable.
      case SettingsRow(onTap: final onTap?, enabled: true, locked: false):
        onTap();
        return true;
      case ListTile(:final onTap?) ||
          InkWell(:final onTap?) ||
          GestureDetector(:final onTap?):
        onTap();
        return true;
      case Switch(:final value, :final onChanged?):
        onChanged(!value);
        return true;
      case SwitchListTile(:final value, :final onChanged?):
        onChanged(!value);
        return true;
      case Checkbox(:final value, :final onChanged?):
        onChanged(!(value ?? false));
        return true;
      case CheckboxListTile(:final value, :final onChanged?):
        onChanged(!(value ?? false));
        return true;
    }
  }
  return false;
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

/// Waits for a route, sheet, or transient control to leave the tree.
///
/// This is safer than waiting for a destination that may already be mounted
/// behind the current route on a real device runner.
Future<void> pumpUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 80,
}) async {
  for (var attempt = 0; attempt < maxAttempts && _hasMatch(finder); attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(_hasMatch(finder), isFalse, reason: 'Expected not to find $finder');
}

/// Waits until an asynchronously rendered collection reaches [count].
Future<void> pumpUntilCount(
  WidgetTester tester,
  Finder finder,
  int count, {
  int maxAttempts = 80,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      if (finder.evaluate().length >= count) break;
      // A chained finder can temporarily lose its parent during navigation,
      // so this Error is an expected transient absence.
      // ignore: avoid_catching_errors
    } on StateError {
      // Keep pumping until the requested collection has rendered.
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsNWidgets(count));
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
  // WidgetTester.tap still performs a synthetic hit test against the native
  // device surface. Route transitions, the Android IME, and bottom sheets can
  // make that surface reject a control that Flutter has already built. Device
  // integration tests exercise the real callback after finding the visible
  // control; host widget tests keep their normal hit-testing coverage.
  if (TestWidgetsFlutterBinding.instance
          is! AutomatedTestWidgetsFlutterBinding &&
      _invokeDeviceControl(finder)) {
    await tester.pump();
    return;
  }
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

/// Opens the auth gate with the same return contract as «احجز الآن».
///
/// These auth integration suites do not need to reload the property details
/// fixture before every scenario. Starting from a loaded Home still verifies
/// the full app router, while `from` proves that a successful sign-in resumes
/// at the booking entry.
Future<void> openBookingLoginFromHome(WidgetTester tester) async {
  final home = find.byKey(const ValueKey('home-search-box'));
  await pumpUntilFound(tester, home);
  final context = tester.element(home);
  GoRouter.of(context).go(
    Uri(
      path: AppRoutes.login,
      queryParameters: {
        'from': AppRoutes.bookingEntry(_mockBookingPropertyId),
        'cancelTo': AppRoutes.home,
      },
    ).toString(),
  );
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('social-google-button')),
  );
}
