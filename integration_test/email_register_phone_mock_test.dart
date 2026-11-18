import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';
import 'package:on_air/features/booking/presentation/dates_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../test/helpers/mock_app.dart';
import '../test/helpers/pump_until_found.dart';

/// S005 US6 end-to-end (T072): email registration completes through the
/// WhatsApp step, legacy accounts never see it, and the change-number
/// route reuses the same step.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('ar'));

  /// Home → booking auth gate → the login screen.
  Future<void> openLoginFromApartment(WidgetTester tester) async {
    pinHostTestView(tester, physicalSize: const Size(800, 1600));
    await openBookingLoginFromHome(tester);
  }

  /// The email registration form, submitted to the code screen.
  Future<void> registerByEmail(WidgetTester tester) async {
    await openLoginFromApartment(tester);
    final registrationForm = find.byWidgetPredicate(
      (widget) => widget is LoginScreen && widget.registration,
    );
    final nameField = find.descendant(
      of: registrationForm,
      matching: find.byKey(const ValueKey('email-name-field')),
    );
    final emailField = find.descendant(
      of: registrationForm,
      matching: find.byKey(const ValueKey('email-field')),
    );
    final passwordField = find.descendant(
      of: registrationForm,
      matching: find.byKey(const ValueKey('password-field')),
    );
    await tapAndWait(
      tester,
      find.text(l10n.authCreateAccount),
      nameField,
    );
    await tester.enterText(nameField, 'زائر بالبريد');
    await pumpUntilFound(tester, emailField);
    await tester.enterText(emailField, 'register@onair.test');
    await tapVisible(tester, passwordField, dismissKeyboard: true);
    await tester.enterText(passwordField, 'Password123!');
    await tester.pump();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('email-terms-checkbox')),
      dismissKeyboard: true,
    );
    await tester.pump();
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('email-submit-button')),
      find.byKey(const ValueKey('otp-field')),
    );
  }

  testWidgets(
    '(a) email registration finishes through «أكّد رقمك» with the number only',
    (tester) async {
      final auth = await bootMockApp(tester);
      await registerByEmail(tester);

      await tester.enterText(
        find.byKey(const ValueKey('otp-field')),
        MockBackend.verificationCode,
      );
      // The incomplete account is forced to «أكّد رقمك» — number only: the
      // email form already collected the name and the terms.
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('confirm-phone-field')),
      );
      expect(
        find.byKey(const ValueKey('confirm-phone-name-field')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('confirm-phone-terms')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const ValueKey('confirm-phone-field')),
        '01012345678',
      );
      await tester.pump();
      await tapAndWait(
        tester,
        find.byKey(const ValueKey('confirm-phone-continue')),
        find.byKey(const ValueKey('whatsapp-otp-field')),
        dismissKeyboard: true,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('whatsapp-otp-field')),
          matching: find.byType(TextField),
        ),
        MockBackend.verificationCode,
      );
      await pumpUntilFound(tester, find.byType(DatesScreen));

      expect(auth.account!.status, AccountStatus.active);
      expect(auth.account!.phone, '+201012345678');
      expect(auth.account!.phoneVerified, isTrue);
    },
  );

  testWidgets('(b) the legacy user signs in with no «أكّد رقمك»', (
    tester,
  ) async {
    final auth = await bootMockApp(tester);
    await openLoginFromApartment(tester);

    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'legacy@onair.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      MockAuthRepository.legacyPassword,
    );
    await tester.pump();
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('email-submit-button')),
      find.byType(DatesScreen),
      dismissKeyboard: true,
    );

    // An active legacy account: the WhatsApp step never opens.
    expect(
      find.byKey(const ValueKey('confirm-phone-field')),
      findsNothing,
    );
    expect(auth.account!.id, 'mock-guest-legacy');
    expect(auth.account!.status, AccountStatus.active);
    expect(auth.account!.phone, '+201012340000');
  });

  testWidgets('(c) the change-number route reuses the WhatsApp step', (
    tester,
  ) async {
    final auth = await bootMockApp(tester);
    await openLoginFromApartment(tester);
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'legacy@onair.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      MockAuthRepository.legacyPassword,
    );
    await tester.pump();
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('email-submit-button')),
      find.byType(DatesScreen),
      dismissKeyboard: true,
    );

    // The account change entry (Phase 10 adds the row; the route exists
    // since T070).
    final context = tester.element(find.byType(DatesScreen));
    unawaited(GoRouter.of(context).push(AppRoutes.accountPhone));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('confirm-phone-field')),
    );
    expect(
      find.byKey(const ValueKey('confirm-phone-name-field')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-field')),
      '01098765432',
    );
    await tester.pump();
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('confirm-phone-continue')),
      find.byKey(const ValueKey('whatsapp-otp-field')),
      dismissKeyboard: true,
    );
    // The server-masked NEW number rides the subtitle (§4.2).
    expect(find.textContaining('••• 432'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('whatsapp-otp-field')),
        matching: find.byType(TextField),
      ),
      MockBackend.verificationCode,
    );
    await pumpUntilFound(tester, find.text(l10n.phoneChanged));

    expect(auth.account!.phone, '+201098765432');
    expect(auth.account!.status, AccountStatus.active);
  });
}
