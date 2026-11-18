import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/account/data/mock_account_server.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';
import 'package:on_air/features/account/presentation/account_screen.dart';
import 'package:on_air/features/account/presentation/notifications/preferences_screen.dart';
import 'package:on_air/features/account/presentation/security/security_screen.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:on_air/features/notifications/presentation/in_app_notification_banner.dart';
import 'package:on_air/features/support/data/mock_support_server.dart';
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

  Future<void> signIn(
    WidgetTester tester, {
    String password = MockAuthRepository.legacyPassword,
    Finder? destination,
  }) async {
    final home = find.byKey(const ValueKey('home-search-box'));
    if (home.evaluate().isNotEmpty) {
      GoRouter.of(tester.element(home)).go(AppRoutes.login);
    }
    await pumpUntilFound(tester, find.byKey(const ValueKey('email-field')));
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'legacy@onair.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      password,
    );
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('email-submit-button')),
      destination ?? home,
      dismissKeyboard: true,
    );
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
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('edit-name-save')),
      find.text('MI'),
      dismissKeyboard: true,
    );
    expect(find.text('Mona Ibrahim'), findsOneWidget);

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

  testWidgets('sessions, password change and revoked heartbeat journey', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await bootMockApp(tester);
    await signIn(tester);
    final homeContext = tester.element(
      find.byKey(const ValueKey('home-search-box')),
    );
    final account = homeContext.read<MockAccountServer?>()!;
    GoRouter.of(homeContext).go(AppRoutes.accountSecurity);
    await pumpUntilFound(tester, find.byType(SecurityScreen));

    final iosSession = find.byKey(
      const ValueKey('end-session-session-ios'),
    );
    await tapVisible(tester, iosSession);
    await tester.pumpAndSettle();
    expect(iosSession, findsNothing);

    await tester.tap(find.byKey(const ValueKey('end-other-sessions')));
    await pumpUntilFound(tester, find.text(ar.accountEndOthersConfirm));
    await tester.tap(find.text(ar.accountEndOthers).last);
    await tester.pumpAndSettle();
    expect(account.sessions.where((session) => !session.isCurrent), isEmpty);

    await tester.tap(find.byKey(const ValueKey('change-password-row')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('current-password-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('current-password-field')),
      'Wrongpass1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'Nextpass1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password-field')),
      'Nextpass1',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-password')));
    await pumpUntilFound(tester, find.text(ar.accountPasswordIncorrect));

    await tester.enterText(
      find.byKey(const ValueKey('current-password-field')),
      MockAuthRepository.legacyPassword,
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-password')));
    await pumpUntilFound(tester, find.text(ar.accountPasswordChanged));
    expect(find.byType(SecurityScreen), findsOneWidget);

    account.revokeHeartbeat = true;
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    await pumpUntilFound(tester, find.byKey(const ValueKey('email-field')));
    expect(find.text(ar.errorUnauthenticated), findsOneWidget);

    account.revokeHeartbeat = false;
    await signIn(
      tester,
      password: 'Nextpass1',
      destination: find.byType(SecurityScreen),
    );
    expect(find.byType(SecurityScreen), findsOneWidget);
  });

  testWidgets(
    'support push can be disabled without suppressing the in-app reply',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await bootMockApp(tester);
      await signIn(tester);
      await openAccount(tester);
      await tapAndWait(
        tester,
        find.byKey(const ValueKey('account-notifications-row')),
        find.byType(PreferencesScreen),
      );

      final supportSwitch = find.byKey(
        const ValueKey('preference-switch-support-push'),
      );
      final context = tester.element(find.byType(PreferencesScreen));
      final account = context.read<MockAccountServer?>()!;
      await tapVisible(tester, supportSwitch);
      for (
        var attempt = 0;
        attempt < 80 && account.pushEnabled('support');
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(account.pushEnabled('support'), isFalse);
      expect(
        tester
            .widget<Switch>(
              find.byKey(
                const ValueKey('preference-switch-booking-push'),
              ),
            )
            .onChanged,
        isNull,
      );

      context.read<MockSupportServer?>()!.sendStaffReply(
        MockSupportServer.waitingCaseId,
      );
      await tester.pumpAndSettle();

      final notifications = await context
          .read<NotificationsRepository>()
          .list();
      expect(
        notifications.any(
          (item) =>
              item.typeKey == 'support.staff_replied' &&
              item.category == 'support',
        ),
        isTrue,
      );
      expect(find.byType(InAppNotificationBanner), findsNothing);
      expect(account.pushEnabled('booking'), isTrue);
      expect(
        (await account.getPreferences())
            .singleWhere((item) => item.key == 'booking')
            .enabled(NotificationChannel.push),
        isTrue,
      );
    },
  );
}
