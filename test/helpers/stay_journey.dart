import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'booking_journey.dart';
import 'fake_booking_backend.dart';
import 'pump_until_found.dart';

Future<void> runRemainingPaymentJourney(WidgetTester tester) async {
  const bookingId = 'b0000000-0000-4000-8000-000000000020';
  final l10n = lookupAppLocalizations(const Locale('ar'));
  if (TestWidgetsFlutterBinding.instance
      is AutomatedTestWidgetsFlutterBinding) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  CairoTime.initialize();
  SharedPreferences.setMockInitialValues({});

  final backend = FakeBookingBackend(
    includeG3Fixtures: true,
    actionRegistry: BookingActionRegistry.g3(),
  );
  addTearDown(backend.dispose);
  final auth = MockAuthRepository();
  addTearDown(auth.dispose);
  await auth.signUpEmail(
    'مستأجر تجريبي',
    'guest@mock.onair.test',
    'Password123!',
    '01000000001',
    MockBackend.termsVersion,
  );
  await auth.verifyEmailCode(
    'guest@mock.onair.test',
    MockBackend.verificationCode,
  );

  await bootApp(tester, backend, auth);
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.bookingDetails(bookingId));
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('primary-pay_remaining')),
  );

  await tester.tap(find.byKey(const ValueKey('primary-pay_remaining')));
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('remaining-pay')),
  );
  await tester.tap(find.byKey(const ValueKey('remaining-pay')));
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('mock-pay-success')),
  );
  await tester.tap(find.byKey(const ValueKey('mock-pay-success')));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await pumpUntilFound(tester, find.text(l10n.remainingPaidTitle));

  await tester.tap(find.text(l10n.paymentViewBooking));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  expect(
    find.byKey(const ValueKey('primary-pay_remaining')),
    findsNothing,
  );
}
