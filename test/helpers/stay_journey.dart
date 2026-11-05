import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
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

/// The US3 stay-acknowledgement journey: check in on booking `…021`, the
/// mock owner confirms the handover, then the guest checks out and the
/// mock owner confirms receiving the apartment.
Future<void> runStayAckJourney(WidgetTester tester) async {
  const booking21 = 'b0000000-0000-4000-8000-000000000021';
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
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(
    AppRoutes.bookingDetails(booking21),
  );

  // 1. The guest confirms receiving the apartment.
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('primary-confirm_checkin')),
  );
  await tester.tap(find.byKey(const ValueKey('primary-confirm_checkin')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.checkinSheetConfirm));
  await tester.pumpAndSettle();
  expect(backend.stay.checkIns, 1);

  // 2. The mock owner confirms the handover; the signal refreshes details.
  await backend.stay.ownerConfirmsHandover(booking21);
  await pumpUntilFound(tester, find.text(l10n.bookingStatusCheckedIn));

  // 3. The guest confirms leaving.
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('primary-confirm_checkout')),
  );
  await tester.tap(find.byKey(const ValueKey('primary-confirm_checkout')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.checkoutSheetConfirm));
  await tester.pumpAndSettle();
  expect(backend.stay.checkOuts, 1);

  // 4. The mock owner confirms receiving the apartment.
  await backend.stay.ownerConfirmsCheckout(booking21);
  await pumpUntilFound(tester, find.text(l10n.bookingStatusCompleted));
}

/// The US4 cancellation journey (the Independent Test): the three policy
/// sentences, a terms change that asks the guest again, and the refund
/// stages reaching «تم رد المبلغ» only after the final check.
Future<void> runCancellationJourney(WidgetTester tester) async {
  const booking23 = 'b0000000-0000-4000-8000-000000000023';
  const booking24 = 'b0000000-0000-4000-8000-000000000024';
  const booking21 = 'b0000000-0000-4000-8000-000000000021';
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
  // 1. The free case on …023.
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(
    AppRoutes.bookingDetails(booking23),
  );
  await pumpUntilFound(tester, find.text('OA-G3023'));
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('action-request_cancellation')),
  );
  await tester.tap(find.byKey(const ValueKey('action-request_cancellation')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('cancel-confirm')));
  expect(
    find.text(
      l10n.cancelReasonFree(
        MoneyFormatter().format(Money(450000)),
      ),
    ),
    findsOneWidget,
  );
  await tester.tap(find.text(l10n.cancelKeep));
  await tester.pumpAndSettle();

  // 2. The no-refund case on …024 (push: the details page element is
  // reused for the same route pattern).
  unawaited(
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(
      AppRoutes.bookingDetails(booking24),
    ),
  );
  await pumpUntilFound(tester, find.text('OA-G3024'));
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('action-request_cancellation')),
  );
  await tester.tap(find.byKey(const ValueKey('action-request_cancellation')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('cancel-confirm')));
  expect(find.text(l10n.cancelReasonNoRefund), findsOneWidget);
  await tester.tap(find.text(l10n.cancelKeep));
  await tester.pumpAndSettle();

  // 3. The deposit-lost case on …021: the mock changes the terms once, so
  // the first confirm is rejected and the guest must confirm again.
  unawaited(
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(
      AppRoutes.bookingDetails(booking21),
    ),
  );
  await pumpUntilFound(tester, find.text('OA-G3021'));
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('action-request_cancellation')),
  );
  await tester.tap(find.byKey(const ValueKey('action-request_cancellation')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('cancel-confirm')));
  expect(
    find.text(
      l10n.cancelReasonDepositLost(
        MoneyFormatter().format(Money(270000)),
        MoneyFormatter().format(Money(90000)),
        formatCairoDayMonthTime(DateTime.parse('2026-10-29T10:00:00Z')),
      ),
    ),
    findsOneWidget,
  );

  backend.stay.forceTermsChangeOnce(booking21);
  await tester.tap(find.byKey(const ValueKey('cancel-confirm')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.cancelDialogConfirm));
  await pumpUntilFound(tester, find.text(l10n.cancellationTermsChanged));
  expect(
    find.text(
      l10n.cancelDialogBody(MoneyFormatter().format(Money(260000))),
    ),
    findsNothing,
  );

  await tester.tap(find.byKey(const ValueKey('cancel-confirm')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.cancelDialogConfirm));
  await pumpUntilFound(tester, find.text(l10n.bookingMsgCancelledByGuest));
  // The mock counts the rejected terms-changed attempt too.
  expect(backend.stay.cancels, 2);
  // The chip and the stage tracker both render the requested stage.
  expect(find.text(l10n.refundChipRequested), findsWidgets);

  // 4. The refund advances one stage per mock tool call.
  for (var stage = 0; stage < 2; stage++) {
    await backend.stay.advanceRefund(booking21);
    await tester.pumpAndSettle();
  }
  expect(find.text(l10n.refundChipInProgress), findsWidgets);
  expect(find.text(l10n.refundChipDone), findsNothing);

  await backend.stay.advanceRefund(booking21);
  await tester.pumpAndSettle();
  expect(find.text(l10n.refundChipDone), findsWidgets);
}
