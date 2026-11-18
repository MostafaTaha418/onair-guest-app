import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/features/account/presentation/account_placeholder_screen.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../helpers/fake_app_config_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

/// S005 US8 (T075): the account placeholder shows the sign-in method, the
/// masked confirmed phone with the «متأكد» chip, and the change entry.
void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));

  late FakeAuthRepository auth;
  late AuthCubit cubit;

  setUp(() {
    auth = FakeAuthRepository();
    cubit = AuthCubit(auth);
  });

  Future<void> pumpAccount(
    WidgetTester tester, {
    required GuestAccount account,
  }) async {
    auth.account = account;
    await cubit.restore();
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => const AccountPlaceholderScreen(),
        ),
        GoRoute(
          path: AppRoutes.accountPhone,
          builder: (_, _) => const Scaffold(
            body: Center(
              child: Text('phone-stub', key: ValueKey('phone-stub')),
            ),
          ),
        ),
      ],
    );
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
      authCubit: cubit,
      routerConfig: router,
    );
    await tester.pumpAndSettle();
  }

  GuestAccount account({
    Set<AuthProvider> providers = const {AuthProvider.google},
  }) => GuestAccount(
    id: 'account-guest',
    status: AccountStatus.active,
    phone: '+201012345678',
    phoneVerified: true,
    email: 'guest@example.com',
    emailVerified: true,
    fullName: 'زائر تجريبي',
    authProviders: providers,
    hasPassword: false,
    acceptedTermsVersion: 'v1',
    acceptedTermsAt: DateTime.utc(2026),
  );

  testWidgets('a Google account shows the sign-in method row', (tester) async {
    await pumpAccount(tester, account: account());

    expect(find.text(l10n.accountSignInMethod), findsOneWidget);
    expect(find.text(l10n.accountMethodGoogle), findsOneWidget);
    expect(find.text(l10n.accountMethodEmail), findsNothing);
  });

  testWidgets('several providers join with «، »', (tester) async {
    await pumpAccount(
      tester,
      account: account(providers: {AuthProvider.email, AuthProvider.google}),
    );

    expect(
      find.text('${l10n.accountMethodEmail}، ${l10n.accountMethodGoogle}'),
      findsOneWidget,
    );
  });

  testWidgets('the phone shows masked with the confirmed chip', (
    tester,
  ) async {
    await pumpAccount(tester, account: account());

    expect(find.text(l10n.accountPhone), findsOneWidget);
    expect(find.text('+20 10•• ••• 678'), findsOneWidget);
    expect(find.text(l10n.accountPhoneConfirmed), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-phone-chip')),
      findsOneWidget,
    );
  });

  testWidgets('«تغيير» pushes the change-number route', (tester) async {
    await pumpAccount(tester, account: account());

    await tester.tap(find.byKey(const ValueKey('account-change-phone')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('phone-stub')), findsOneWidget);
  });
}
