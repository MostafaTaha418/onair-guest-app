import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/booking_journey.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/pump_until_found.dart';

void main() {
  testWidgets('cancelling from the details returns to a cancelled booking', (
    tester,
  ) async {
    const bookingId = 'b0000000-0000-4000-8000-000000000023';
    final l10n = lookupAppLocalizations(const Locale('ar'));
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
      MockBackend.termsVersion,
    );
    await auth.verifyEmailCode(
      'guest@mock.onair.test',
      MockBackend.verificationCode,
    );
    // The WhatsApp step activates the mock account (S005 US6); the journey
    // seeds the confirmed number directly.
    auth.activatePhone(
      userId: auth.account!.id,
      phoneE164: '+201000000001',
    );

    await bootApp(tester, backend, auth);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(
      AppRoutes.bookingDetails(bookingId),
    );

    // 1. The details screen offers the cancellation action.
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('action-request_cancellation')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('action-request_cancellation')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('action-request_cancellation')),
    );

    // 2. The preview screen with the free-cancellation sentence.
    await pumpUntilFound(tester, find.byKey(const ValueKey('cancel-confirm')));
    expect(
      find.text(
        l10n.cancelReasonFree(
          MoneyFormatter().format(Money(450000)),
        ),
      ),
      findsOneWidget,
    );

    // 3. Confirm through the dialog.
    await tester.tap(find.byKey(const ValueKey('cancel-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancelDialogConfirm));
    await tester.pumpAndSettle();
    expect(backend.stay.cancels, 1);

    // 4. Back on the details: cancelled, with a requested refund.
    await pumpUntilFound(tester, find.text(l10n.bookingMsgCancelledByGuest));
    expect(find.text(l10n.bookingStatusCancelled), findsWidgets);
    expect(find.text(l10n.refundChipRequested), findsOneWidget);

    // 5. The refund advances only step by step (AC-042).
    await backend.stay.advanceRefund(bookingId);
    await tester.pumpAndSettle();
    expect(find.text(l10n.refundChipInProgress), findsOneWidget);
    expect(find.text(l10n.refundChipDone), findsNothing);

    await backend.stay.advanceRefund(bookingId);
    await tester.pumpAndSettle();
    expect(find.text(l10n.refundChipDone), findsNothing);

    await backend.stay.advanceRefund(bookingId);
    await tester.pumpAndSettle();
    expect(find.text(l10n.refundChipDone), findsOneWidget);
  });
}
