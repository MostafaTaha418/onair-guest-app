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
import 'package:on_air/features/bookings/presentation/widgets/booking_card.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../test/helpers/mock_app.dart';
import '../test/helpers/pump_until_found.dart';

/// S005 US1 end-to-end journey (T037): mock mode only — the native Google
/// sheet is replaced by the mock repository's canned scenarios.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('ar'));

  /// Home → first apartment → «احجز الآن» → the login screen's Google row.
  Future<void> openLoginFromApartment(WidgetTester tester) async {
    // Device runners report an arbitrary window; pin a tall one so every
    // step stays hit-testable (device-CI rule).
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

  testWidgets(
    '(a) a complete Google user signs in and returns to the booking entry',
    (tester) async {
      final auth = await bootMockApp(tester);
      auth.scenario = MockSocialScenario.completeUser;
      await openLoginFromApartment(tester);

      await tester.tap(find.byKey(const ValueKey('social-google-button')));
      await tester.pumpAndSettle();

      expect(find.byType(DatesScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('social-google-button')),
        findsNothing,
      );
      expect(auth.account!.status, AccountStatus.active);
    },
  );

  testWidgets(
    '(b) a cancelled Google sheet stays on the login screen with no error',
    (tester) async {
      final auth = await bootMockApp(tester);
      auth.scenario = MockSocialScenario.cancel;
      await openLoginFromApartment(tester);

      await tester.tap(find.byKey(const ValueKey('social-google-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('social-google-button')),
        findsOneWidget,
      );
      expect(find.text(l10n.authSocialFailed), findsNothing);
    },
  );

  testWidgets(
    '(c) a double-tap on Google reaches the repository exactly once',
    (tester) async {
      final auth = await bootMockApp(tester);
      await openLoginFromApartment(tester);

      final button = find.byKey(const ValueKey('social-google-button'));
      await tester.tap(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(auth.socialSignInCalls, 1);
    },
  );

  testWidgets(
    '(d) a new Google user finishes registration with the WhatsApp code',
    (tester) async {
      final auth = await bootMockApp(tester);
      auth.scenario = MockSocialScenario.newUser;
      await openLoginFromApartment(tester);

      // The incomplete account is sent to «أكّد رقمك» (T047).
      await tester.tap(find.byKey(const ValueKey('social-google-button')));
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('confirm-phone-field')),
      );
      // The provider name pre-fills the name field (T046); the terms are
      // still required.
      await tester.enterText(
        find.byKey(const ValueKey('confirm-phone-field')),
        '01012345678',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-phone-terms')));
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

  testWidgets(
    '(e) a wrong code, then an app restart, keeps the account phoneless',
    (tester) async {
      final auth = MockAuthRepository();
      var backend = await bootMockApp(tester, auth: auth);
      backend.scenario = MockSocialScenario.newUser;
      await openLoginFromApartment(tester);

      await tester.tap(find.byKey(const ValueKey('social-google-button')));
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('confirm-phone-field')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('confirm-phone-field')),
        '01012345678',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-phone-terms')));
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
        '000000',
      );
      await tester.tap(find.byKey(const ValueKey('whatsapp-confirm')));
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('whatsapp-code-error')),
      );
      expect(auth.account!.phone, isNull);

      // A fresh app over the SAME mock backend: the session survives as an
      // incomplete account with no phone (quickstart V3).
      backend = await bootMockApp(tester, auth: auth);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('confirm-phone-field')),
      );
      final phoneField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('confirm-phone-field')),
          matching: find.byType(TextField),
        ),
      );
      expect(phoneField.controller!.text, isEmpty);
      expect(auth.account!.phone, isNull);
      expect(auth.account!.status, AccountStatus.incomplete);
    },
  );

  testWidgets(
    '(f) the legacy user signs in with no «أكّد رقمك» and sees the bookings',
    (tester) async {
      final auth = await bootMockApp(tester);
      auth.scenario = MockSocialScenario.legacyUser;
      await openLoginFromApartment(tester);

      // Google joins the seeded legacy account directly (V13, FR-039): the
      // booking entry opens, never «أكّد رقمك».
      await tester.tap(find.byKey(const ValueKey('social-google-button')));
      await pumpUntilFound(tester, find.byType(DatesScreen));
      expect(
        find.byKey(const ValueKey('confirm-phone-field')),
        findsNothing,
      );
      expect(auth.account!.id, 'mock-guest-legacy');
      expect(auth.account!.status, AccountStatus.active);

      // My Bookings shows the mock bookings for that account.
      GoRouter.of(
        tester.element(find.byType(DatesScreen)),
      ).go(AppRoutes.bookings);
      await pumpUntilFound(tester, find.byType(BookingCard));
      expect(
        find.byKey(const ValueKey('confirm-phone-field')),
        findsNothing,
      );
    },
  );
}
