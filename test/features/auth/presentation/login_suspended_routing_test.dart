import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_app.dart';

/// Review round 2: the login screen picks its destination from
/// `needsPhoneStep`, so a suspended account never lands on «أكّد رقمك».
void main() {
  GuestAccount account(AccountStatus status) => GuestAccount(
    id: 'guest',
    status: status,
    phone: status == AccountStatus.incomplete ? null : '+201012345678',
    phoneVerified: status != AccountStatus.incomplete,
    email: 'guest@example.com',
    emailVerified: true,
    fullName: 'Guest',
    acceptedTermsVersion: 'v1',
  );

  Future<GoRouter> pumpLogin(
    WidgetTester tester,
    FakeAuthRepository auth,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Widget marker(String label) => Scaffold(body: Text(label));
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const LoginScreen(),
        ),
        GoRoute(path: AppRoutes.home, builder: (_, _) => marker('home')),
        GoRoute(
          path: AppRoutes.completeProfile,
          builder: (_, _) => marker('confirm-phone'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpOnAirApp(
      const SizedBox.shrink(),
      authRepository: auth,
      appConfigRepository: FakeAppConfigRepository(
        const AppConfig(
          minSupportedBuildAndroid: 1,
          minSupportedBuildIos: 1,
          supportPhone: '+201000000000',
          currentTermsVersion: 'v1',
        ),
      ),
      routerConfig: router,
    );
    return router;
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('email-field')),
      'guest@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'Passw0rd!',
    );
    await tester.tap(find.byKey(const ValueKey('email-submit-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('a suspended account goes to the destination, not «أكّد رقمك»', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..account = account(AccountStatus.suspended);
    final router = await pumpLogin(tester, auth);

    await signIn(tester);

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.home,
    );
    expect(find.text('confirm-phone'), findsNothing);
  });

  testWidgets('an incomplete account still goes to «أكّد رقمك»', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..account = account(AccountStatus.incomplete);
    final router = await pumpLogin(tester, auth);

    await signIn(tester);

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.completeProfile,
    );
  });
}
