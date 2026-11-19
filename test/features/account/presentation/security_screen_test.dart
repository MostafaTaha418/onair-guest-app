import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/active_session.dart';
import 'package:on_air/features/account/presentation/security/change_password_screen.dart';
import 'package:on_air/features/account/presentation/security/security_cubit.dart';
import 'package:on_air/features/account/presentation/security/security_screen.dart';
import 'package:on_air/features/auth/data/mock_auth_repository.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/mock_app.dart';

class _Repository extends Fake implements AccountRepository {
  int endAllCalls = 0;
  @override
  Future<void> endOtherSessions() async => endAllCalls++;
}

class _Auth extends Fake implements AuthRepository {
  _Auth(this.account);
  final GuestAccount account;
  @override
  Stream<GuestAccount?> get authStateChanges => const Stream.empty();

  @override
  Future<GuestAccount?> restoreSession() async => account;
}

ActiveSession _session(String id, {bool current = false}) => ActiveSession(
  id: id,
  deviceLabel: current ? 'Pixel 8 · Android 14' : 'iPhone 15 · iOS 18',
  platform: current ? SessionPlatform.android : SessionPlatform.ios,
  createdAt: DateTime.utc(2026, 11),
  lastActiveAt: DateTime.now().toUtc(),
  isCurrent: current,
);

void main() {
  Future<
    ({
      SecurityCubit security,
      AuthCubit auth,
      ConnectivityCubit connection,
      _Repository repository,
    })
  >
  pump(
    WidgetTester tester, {
    required bool hasPassword,
    bool withOther = true,
    bool online = true,
  }) async {
    final repository = _Repository();
    final security = SecurityCubit.seeded(
      repository,
      SecurityReady(
        sessions: [
          _session('current', current: true),
          if (withOther) _session('other'),
        ],
      ),
    );
    final auth = AuthCubit(
      _Auth(
        GuestAccount(
          id: 'guest',
          status: AccountStatus.active,
          phone: '+201012345678',
          hasPassword: hasPassword,
        ),
      ),
    );
    await auth.restore();
    final fakeConnectivity = FakeConnectivity();
    final connection = fakeConnectivity.createCubit();
    if (!online) fakeConnectivity.goOffline();
    addTearDown(security.close);
    addTearDown(auth.close);
    addTearDown(connection.close);
    addTearDown(fakeConnectivity.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: security),
          BlocProvider.value(value: auth),
          BlocProvider.value(value: connection),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: OnAirTheme.light,
          home: const SecurityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (
      security: security,
      auth: auth,
      connection: connection,
      repository: repository,
    );
  }

  testWidgets('password accounts see the row; social accounts do not', (
    tester,
  ) async {
    await pump(tester, hasPassword: true);
    expect(find.byKey(const ValueKey('change-password-row')), findsOneWidget);
    await pump(tester, hasPassword: false);
    expect(find.byKey(const ValueKey('change-password-row')), findsNothing);
  });

  testWidgets('current device has a chip and no end action', (tester) async {
    await pump(tester, hasPassword: true);
    expect(find.byKey(const ValueKey('current-device-chip')), findsOneWidget);
    expect(find.byKey(const ValueKey('end-session-current')), findsNothing);
    expect(find.byKey(const ValueKey('end-session-other')), findsOneWidget);
  });

  testWidgets(
    'all-others is hidden with one session and actions disable offline',
    (
      tester,
    ) async {
      await pump(tester, hasPassword: true, withOther: false);
      expect(find.byKey(const ValueKey('end-other-sessions')), findsNothing);
      await pump(tester, hasPassword: true, online: false);
      final button = tester.widget<TextButton>(
        find.byKey(const ValueKey('end-session-other')),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('ending all other sessions requires confirmation', (
    tester,
  ) async {
    final result = await pump(tester, hasPassword: true);
    await tester.tap(find.byKey(const ValueKey('end-other-sessions')));
    final l10n = lookupAppLocalizations(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.accountEndOthersConfirm), findsOneWidget);
    await tester.tap(find.text(l10n.accountEndOthers).last);
    await tester.pumpAndSettle();
    expect(result.repository.endAllCalls, 1);
  });

  testWidgets('password route redirects social accounts to security', (
    tester,
  ) async {
    final authRepository = MockAuthRepository()
      ..scenario = MockSocialScenario.completeUser;
    addTearDown(authRepository.dispose);
    await authRepository.signInWithGoogle();
    await bootMockApp(tester, auth: authRepository);
    final home = find.byKey(const ValueKey('home-search-box'));
    GoRouter.of(tester.element(home)).go('/account/security/password');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byType(SecurityScreen), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsNothing);
  });
}
