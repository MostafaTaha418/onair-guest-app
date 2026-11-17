import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/account/presentation/account_screen.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../test/helpers/mock_app.dart';
import '../test/helpers/pump_until_found.dart';

/// T079 (US5): profile and device settings on the full mock app. The same
/// auth repository and SharedPreferences instance are reused across the
/// second boot to model a process restart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final ar = lookupAppLocalizations(const Locale('ar'));
  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> signIn(WidgetTester tester) async {
    final context = tester.element(
      find.byKey(const ValueKey('home-search-box')),
    );
    GoRouter.of(context).go(AppRoutes.login);
    await pumpUntilFound(tester, find.byKey(const ValueKey('email-field')));
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'legacy@onair.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      MockAuthRepository.legacyPassword,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('home-search-box')));
  }

  Future<void> openAccount(WidgetTester tester) async {
    final context = tester.element(
      find.byKey(const ValueKey('home-search-box')),
    );
    GoRouter.of(context).go(AppRoutes.account);
    await pumpUntilFound(tester, find.byType(AccountScreen));
  }

  testWidgets('name, language and appearance persist; sign-out is public', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = await bootMockApp(tester);
    await signIn(tester);
    await openAccount(tester);

    // Edit the profile through the real repository and refresh AuthCubit.
    await tester.tap(find.byKey(const ValueKey('account-edit-name')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('edit-name-field')));
    await tester.enterText(
      find.byKey(const ValueKey('edit-name-field')),
      'Mona Ibrahim',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('edit-name-save')));
    await pumpUntilFound(tester, find.text('Mona Ibrahim'));
    expect(find.text('MI'), findsOneWidget);

    // Locale applies immediately and flips the app to LTR.
    final language = find.byKey(const ValueKey('account-language-row'));
    await tester.ensureVisible(language);
    await tester.tap(language);
    await pumpUntilFound(tester, find.text(ar.settingsLanguageEnglish));
    await tester.tap(find.text(ar.settingsLanguageEnglish));
    await pumpUntilFound(tester, find.text(en.account));
    expect(
      Directionality.of(tester.element(find.byType(AccountScreen))),
      TextDirection.ltr,
    );

    // Appearance also applies immediately.
    final appearance = find.byKey(const ValueKey('account-appearance-row'));
    await tester.ensureVisible(appearance);
    await tester.tap(appearance);
    await pumpUntilFound(tester, find.text(en.settingsThemeDark));
    await tester.tap(find.text(en.settingsThemeDark));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AccountScreen))).brightness,
      Brightness.dark,
    );

    // A fresh app State reads the same profile and preferences.
    await bootMockApp(tester, auth: auth, resetPreferences: false);
    await pumpUntilFound(tester, find.byKey(const ValueKey('home-search-box')));
    await openAccount(tester);
    expect(find.text('Mona Ibrahim'), findsOneWidget);
    expect(find.text('MI'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AccountScreen))),
      TextDirection.ltr,
    );
    expect(
      Theme.of(tester.element(find.byType(AccountScreen))).brightness,
      Brightness.dark,
    );

    // Sign-out is confirmed once; /account then renders the visitor variant.
    final signOut = find.byKey(const ValueKey('account-sign-out-row'));
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await pumpUntilFound(tester, find.text(en.accountSignOutConfirm));
    await tester.tap(find.text(en.accountSignOut).last);
    await pumpUntilFound(tester, find.byKey(const ValueKey('home-search-box')));
    await openAccount(tester);
    expect(find.byKey(const ValueKey('visitor-sign-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-security-row')), findsNothing);
  });
}
