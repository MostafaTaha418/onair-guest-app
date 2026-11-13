import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/booking/presentation/dates_screen.dart';
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
}
