import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/app/settings/app_settings_cubit.dart';
import 'package:on_air/app/settings/app_settings_store.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/payments/in_app_browser.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/presentation/account_screen.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/support/domain/support_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_support_repository.dart';

/// A browser spy: the terms/privacy taps must land here with the locale
/// URL (T073 asserts the in-app browser semantics at the component seam).
class _SpyBrowser extends Fake implements InAppBrowser {
  final opened = <Uri>[];

  @override
  Future<void> open(Uri url, {required String bookingId}) async {
    opened.add(url);
  }
}

class _NoopCoordinator extends Fake implements SignOutCoordinator {
  int calls = 0;
  @override
  Future<void> signOut() async => calls++;
}

/// The session seam: one account restored on session read.
class _SignedInRepository extends Fake implements AuthRepository {
  _SignedInRepository(this.account);
  final GuestAccount account;

  @override
  Future<GuestAccount?> restoreSession() async => account;

  @override
  Stream<GuestAccount?> get authStateChanges => const Stream.empty();
}

void main() {
  late AppLocalizations l10n;
  late FakeSupportRepository support;
  late FakeConnectivity connectivity;
  late _SpyBrowser browser;
  late _NoopCoordinator coordinator;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    support = FakeSupportRepository();
    connectivity = FakeConnectivity();
    browser = _SpyBrowser();
    coordinator = _NoopCoordinator();
  });

  tearDown(() => connectivity.dispose());

  GuestAccount account({Set<AuthProvider> providers = const {}}) =>
      GuestAccount(
        id: 'id',
        status: AccountStatus.active,
        phone: '+201012345678',
        phoneVerified: true,
        fullName: 'زائر تجريبي',
        email: 'legacy@onair.test',
        emailVerified: true,
        authProviders: providers.isEmpty
            ? const {AuthProvider.email}
            : providers,
        acceptedTermsVersion: 'v1',
      );

  Future<void> pump(
    WidgetTester tester, {
    bool signedIn = true,
    GuestAccount? signedInAccount,
    bool hasSupportPhone = true,
    bool online = true,
  }) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final connectivityCubit = connectivity.createCubit();
    if (!online) connectivity.goOffline();
    addTearDown(connectivityCubit.close);
    final settings = AppSettingsCubit(store: const AppSettingsStore());
    await settings.start();
    addTearDown(settings.close);
    final auth = AuthCubit(
      _SignedInRepository(signedInAccount ?? account()),
      signOutCoordinator: coordinator,
    );
    if (signedIn) {
      await auth.restore();
    }
    addTearDown(auth.close);
    final router = GoRouter(
      initialLocation: AppRoutes.account,
      routes: [
        GoRoute(
          path: AppRoutes.account,
          builder: (context, state) => BlocProvider<AuthCubit>.value(
            value: auth,
            child: const AccountScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (_, _) => const Text('support'),
        ),
        GoRoute(
          path: AppRoutes.supportFaq,
          builder: (_, _) => const Text('faq'),
        ),
        GoRoute(
          path: AppRoutes.accountDelete,
          builder: (_, _) => const Text('delete'),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Text('login'),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, _) => const Text('register'),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SupportRepository>.value(value: support),
          RepositoryProvider<InAppBrowser>.value(value: browser),
          RepositoryProvider<AppConfigSource>.value(
            value: FakeAppConfigRepository(
              AppConfig(
                minSupportedBuildAndroid: 1,
                minSupportedBuildIos: 1,
                supportPhone: hasSupportPhone ? '+201000000000' : '',
                currentTermsVersion: 'v1',
                supportContact: SupportContact(
                  phone: hasSupportPhone ? '+201000000000' : null,
                ),
                legal: LegalLinks(
                  termsUrlAr: Uri.parse('https://example.invalid/terms'),
                  privacyUrlAr: Uri.parse('https://example.invalid/privacy'),
                ),
              ),
            ),
          ),
        ],
        child: BlocProvider<ConnectivityCubit>.value(
          value: connectivityCubit,
          child: BlocProvider<AppSettingsCubit>.value(
            value: settings,
            child: MaterialApp.router(
              locale: const Locale('ar'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: OnAirTheme.light,
              routerConfig: router,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    if (!online) {
      connectivity.goOffline();
      await tester.pump();
    }
  }

  testWidgets(
    'an email account renders every row and the S005 phone row',
    (tester) async {
      await pump(tester);
      await tester.pump();
      expect(find.text('زائر تجريبي'), findsOneWidget);
      expect(find.text('زت'), findsOneWidget); // the initials avatar
      expect(find.text(l10n.accountMethodEmail), findsOneWidget);
      expect(find.text('+20 10•• ••• 678'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-phone-chip')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-notifications-row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-security-row')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('account-support-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('account-faq-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('account-terms-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('account-delete-row')), findsOneWidget);
      // The call row dials the published number.
      expect(find.text(l10n.supportCall), findsOneWidget);
    },
  );

  testWidgets('a Google account shows Google as the sign-in method', (
    tester,
  ) async {
    await pump(
      tester,
      signedInAccount: account(providers: const {AuthProvider.google}),
    );
    await tester.pump();
    expect(find.text(l10n.accountMethodGoogle), findsOneWidget);
    expect(find.text(l10n.accountMethodEmail), findsNothing);
  });

  testWidgets('a visitor sees the sign-in card and the public rows only', (
    tester,
  ) async {
    await pump(tester, signedIn: false);
    await tester.pump();
    expect(find.byKey(const ValueKey('visitor-sign-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('visitor-register')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-notifications-row')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('account-security-row')), findsNothing);
    expect(find.byKey(const ValueKey('account-support-row')), findsNothing);
    expect(find.byKey(const ValueKey('account-faq-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-terms-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-privacy-row')), findsOneWidget);
    expect(find.text(l10n.supportCall), findsOneWidget);
  });

  testWidgets('the support row shows the unread dot with unread replies', (
    tester,
  ) async {
    support.anyUnread = true;
    await pump(tester);
    await tester.pump();
    expect(find.byKey(const ValueKey('support-unread-dot')), findsOneWidget);
  });

  testWidgets('the support row hides the dot without unread replies', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    expect(find.byKey(const ValueKey('support-unread-dot')), findsNothing);
  });

  testWidgets('sign-out confirms and runs the coordinator once', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    final row = find.byKey(const ValueKey('account-sign-out-row'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(coordinator.calls, 0); // only after the sheet confirms
    await tester.tap(find.text(l10n.accountSignOut).last);
    await tester.pumpAndSettle();
    expect(coordinator.calls, 1);
  });

  testWidgets('terms and privacy open the locale URLs in the browser', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    final terms = find.byKey(const ValueKey('account-terms-row'));
    final privacy = find.byKey(const ValueKey('account-privacy-row'));
    await tester.ensureVisible(terms);
    await tester.tap(terms);
    await tester.pump();
    await tester.ensureVisible(privacy);
    await tester.tap(privacy);
    await tester.pump();
    expect(browser.opened.map((url) => url.toString()), [
      'https://example.invalid/terms',
      'https://example.invalid/privacy',
    ]);
  });

  testWidgets('the call row is hidden without a published number', (
    tester,
  ) async {
    await pump(tester, hasSupportPhone: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-call-row')), findsNothing);
  });

  testWidgets('editing the profile is disabled while offline', (
    tester,
  ) async {
    await pump(tester, online: false);
    final edit = tester.widget<TextButton>(
      find.byKey(const ValueKey('account-edit-name')),
    );
    expect(edit.onPressed, isNull);
  });
}
