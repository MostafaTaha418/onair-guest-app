import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/design_system/components/on_air_confirm_sheet.dart';
import 'package:on_air/features/account/presentation/account_screen.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../test/helpers/mock_app.dart';
import '../test/helpers/pump_until_found.dart';

/// T067 (US4): the deletion journey on a device runner — the blocked
/// account sees the reasons; a normal account goes code → visitor home
/// with the «حسابك اتحذف» snackbar shown once (not again after a
/// restart); `/bookings` then asks for sign-in. Mock mode only.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('ar'));

  /// Sign in through the real login screen with the mock email accounts.
  Future<void> signIn(WidgetTester tester, String email) async {
    final context = tester.element(
      find.byKey(const ValueKey('home-search-box')),
    );
    GoRouter.of(context).go(AppRoutes.login);
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.byKey(const ValueKey('email-field')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('password-field')));
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      email,
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      MockAuthRepository.legacyPassword,
    );
    await tester.pump();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('email-submit-button')),
      dismissKeyboard: true,
    );
    await pumpUntilAbsent(tester, find.byKey(const ValueKey('email-field')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('home-search-box')));
  }

  /// Account tab → the temporary danger row → the deletion explain step,
  /// checkbox armed and confirmed.
  Future<void> openDeleteFlow(
    WidgetTester tester, {
    required Finder destination,
  }) async {
    final context = tester.element(
      find.byKey(const ValueKey('home-search-box')),
    );
    GoRouter.of(context).go(AppRoutes.account);
    await pumpUntilFound(tester, find.byType(AccountScreen));
    final deleteRow = find.byKey(const ValueKey('account-delete-row'));
    if (!tester.any(deleteRow)) {
      await tester.scrollUntilVisible(
        deleteRow,
        240,
        scrollable: find
            .descendant(
              of: find.byType(AccountScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }
    await tapAndWait(
      tester,
      deleteRow,
      find.text(l10n.deleteWhatGoes),
    );
    await tapVisible(tester, find.byKey(const ValueKey('delete-understand')));
    await tester.pump();
    await tapAndWait(
      tester,
      find.text(l10n.deleteCta),
      find.byType(OnAirConfirmSheet),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tapAndWait(
      tester,
      find.descendant(
        of: find.byType(OnAirConfirmSheet),
        matching: find.text(l10n.deleteUnderstand),
      ),
      destination,
    );
  }

  testWidgets('the blocked account sees its blockers, not the code step', (
    tester,
  ) async {
    await bootMockApp(tester);
    await signIn(tester, 'blocked@onair.test');
    await openDeleteFlow(
      tester,
      destination: find.text(l10n.deleteBlockedTitle),
    );

    // The blocker refusal renders instead of the OTP field.
    await pumpUntilFound(tester, find.text(l10n.deleteBlockedTitle));
    expect(
      find.text(l10n.deleteBlockerBooking('OA-BLOCKED')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('delete-otp-field')), findsNothing);
    await tapAndWait(
      tester,
      find.text(l10n.whatsappContactSupport),
      find.byKey(const ValueKey('home-scroll')),
    );
  });

  testWidgets('a normal account deletes and lands on the visitor home', (
    tester,
  ) async {
    await bootMockApp(tester);
    await signIn(tester, 'legacy@onair.test');
    await openDeleteFlow(
      tester,
      destination: find.byKey(const ValueKey('delete-otp-field')),
    );
    expect(find.text(l10n.deleteCodeSent('l***@o***.test')), findsOneWidget);

    // The 6-digit code completes the field: the confirm fires on its own.
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('delete-otp-field')),
        matching: find.byType(TextField),
      ),
      MockBackend.verificationCode,
    );
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.byKey(const ValueKey('home-scroll')));
    expect(find.text(l10n.deleteDone), findsOneWidget);

    // The restart carries no extra: the snackbar is one-shot.
    await bootMockApp(tester);
    await pumpUntilFound(tester, find.byKey(const ValueKey('home-scroll')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(l10n.deleteDone), findsNothing);

    // The account is gone: account-gated routes ask for sign-in again.
    final context = tester.element(
      find.byKey(const ValueKey('home-search-box')),
    );
    GoRouter.of(context).go(AppRoutes.bookings);
    await pumpUntilFound(tester, find.byKey(const ValueKey('email-field')));
  });
}
