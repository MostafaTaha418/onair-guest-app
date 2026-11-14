import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
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

  /// Home → first apartment → «احجز الآن» → the login screen.
  Future<void> openLoginFromApartment(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpUntilFound(tester, find.byType(PropertyCard));
    await tester.tap(find.byType(PropertyCard).first);
    await pumpUntilFound(tester, find.text(l10n.bookNow));
    await tester.tap(find.text(l10n.bookNow));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('social-google-button')),
    );
  }

  /// The email registration form, submitted to the code screen.
  Future<void> registerByEmail(WidgetTester tester) async {
    await openLoginFromApartment(tester);
    await tester.ensureVisible(find.text(l10n.authCreateAccount));
    await tester.pump();
    await tester.tap(find.text(l10n.authCreateAccount));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('email-name-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-name-field')),
      'زائر بالبريد',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'register@onair.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'Password123!',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-terms-checkbox')),
    );
    await tester.tap(find.byKey(const ValueKey('email-terms-checkbox')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('otp-field')));
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
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('verify-code-button')));
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
      await tester.tap(find.byKey(const ValueKey('confirm-phone-continue')));
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('whatsapp-otp-field')),
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('whatsapp-otp-field')),
          matching: find.byType(TextField),
        ),
        MockBackend.verificationCode,
      );
      await tester.tap(find.byKey(const ValueKey('whatsapp-confirm')));
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
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await pumpUntilFound(tester, find.byType(DatesScreen));

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
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await pumpUntilFound(tester, find.byType(DatesScreen));

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
    await tester.tap(find.byKey(const ValueKey('confirm-phone-continue')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('whatsapp-otp-field')),
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
    await tester.tap(find.byKey(const ValueKey('whatsapp-confirm')));
    await pumpUntilFound(tester, find.text(l10n.phoneChanged));

    expect(auth.account!.phone, '+201098765432');
    expect(auth.account!.status, AccountStatus.active);
  });
}
