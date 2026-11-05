import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
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

/// The US2 cash journey (both entries): a guest-started confirmation on
/// booking `…020` with a wrong phone, an unauthorized phone, a wrong code,
/// then the correct code and the reopened receipt; then the
/// collector-started entry on booking `…028`, which opens the code step
/// directly.
Future<void> runCashJourney(WidgetTester tester) async {
  const booking20 = 'b0000000-0000-4000-8000-000000000020';
  const booking28 = 'b0000000-0000-4000-8000-000000000028';
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
  // --- Guest-started entry on …020.
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(
    AppRoutes.bookingDetails(booking20),
  );
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('primary-pay_remaining')),
  );
  await tester.tap(find.byKey(const ValueKey('primary-pay_remaining')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('remaining-pay')));
  await tester.tap(find.text(l10n.remainingOptionCash));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('remaining-cash')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('cash-send')));

  // Too short: a field error, nothing sent.
  await tester.enterText(find.byType(TextField), '0100');
  await tester.tap(find.byKey(const ValueKey('cash-send')));
  await pumpUntilFound(tester, find.text(l10n.cashPhoneInvalid));
  expect(backend.stay.codesSent, 0);

  // Not the authorized collector.
  await tester.enterText(find.byType(TextField), '01099999999');
  await tester.tap(find.byKey(const ValueKey('cash-send')));
  await pumpUntilFound(tester, find.text(l10n.stayCollectorNotAuthorized));

  // The authorized phone reaches the code step.
  await tester.enterText(find.byType(TextField), '01000000001');
  await tester.tap(find.byKey(const ValueKey('cash-send')));
  await pumpUntilFound(tester, find.byType(OnAirOtpField));

  // A wrong code returns to the code step with an error.
  final otpField = find.descendant(
    of: find.byType(OnAirOtpField),
    matching: find.byType(TextField),
  );
  await tester.enterText(otpField, '000000');
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('cash-confirm')));
  await pumpUntilFound(tester, find.text(l10n.authOtpInvalid));

  // The correct code confirms and opens the receipt.
  await tester.enterText(otpField, '123456');
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('cash-confirm')));
  await pumpUntilFound(tester, find.text(l10n.receiptTitle));

  // Back to details: the cash line reopens the same receipt.
  await tester.tap(find.text(l10n.receiptBack));
  final cashLine = find.text(l10n.paymentMethodCash);
  await pumpUntilFound(tester, cashLine);
  await tester.ensureVisible(cashLine);
  await tester.pump();
  await tester.tap(cashLine);
  // The mock numbers the new receipt from the confirm counter: the wrong
  // code attempt counted, so the confirmed receipt is R-2026-100002.
  await pumpUntilFound(tester, find.text('R-2026-100002'));

  // --- Collector-started entry on …028: straight to the code step.
  final codesSentBefore = backend.stay.codesSent;
  // push (not go): the router reuses the details page element for the same
  // pattern, so a go() would keep showing the previous booking's state.
  unawaited(
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(
      AppRoutes.bookingDetails(booking28),
    ),
  );
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('primary-confirm_cash_payment')),
  );
  await tester.tap(find.byKey(const ValueKey('primary-confirm_cash_payment')));
  await pumpUntilFound(tester, find.byType(OnAirOtpField));
  expect(find.text(l10n.cashCodeSent('g***@mock.onair.test')), findsOneWidget);
  // The pending cash reuses the already-sent code: nothing new is sent.
  expect(backend.stay.codesSent, codesSentBefore);
}
