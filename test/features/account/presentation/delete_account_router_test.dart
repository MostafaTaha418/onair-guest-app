import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/mock_backend.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/mock_app.dart';

/// Review 10: after the deletion confirms, the sign-out flips the router
/// to SignedOut while the screen is still on /account/delete (an
/// account-gated route). This exercises the REAL router with its
/// redirect rules — the deletion must land on home with the one-shot
/// «حسابك اتحذف» notice, never on the login screen.
void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));

  testWidgets('deleting an account lands on home with the notice, not login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = MockAuthRepository();
    addTearDown(auth.dispose);
    await auth.signInEmail(
      'legacy@onair.test',
      MockAuthRepository.legacyPassword,
    );
    await bootMockApp(tester, auth: auth);

    GoRouter.of(
      tester.element(find.byKey(const ValueKey('home-search-box'))),
    ).go(AppRoutes.accountDelete);
    await tester.pumpAndSettle();
    expect(find.text(l10n.deleteWhatGoes), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('delete-understand')));
    await tester.pump();
    await tester.tap(find.text(l10n.deleteCta));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.deleteUnderstand).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('delete-otp-field')), findsOneWidget);

    // The 6th digit auto-confirms; bounded pumps keep a possible wrong
    // landing (login with its ticking countdown) from timing out.
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('delete-otp-field')),
        matching: find.byType(TextField),
      ),
      MockBackend.verificationCode,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    final homeContext = tester.element(
      find.byKey(const ValueKey('home-scroll')),
    );
    expect(
      GoRouter.of(homeContext).routerDelegate.currentConfiguration.uri.path,
      AppRoutes.home,
    );
    expect(find.text(l10n.deleteDone), findsOneWidget);
  });
}
