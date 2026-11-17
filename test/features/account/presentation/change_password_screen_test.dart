import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/presentation/security/change_password_cubit.dart';
import 'package:on_air/features/account/presentation/security/change_password_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';

class _Repository extends Fake implements AccountRepository {
  int calls = 0;
  final pending = Completer<void>();

  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    calls++;
    await pending.future;
  }
}

class _SuccessfulRepository extends Fake implements AccountRepository {
  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {}
}

void main() {
  testWidgets('save enables only for a valid matching form and submits once', (
    tester,
  ) async {
    final repository = _Repository();
    final cubit = ChangePasswordCubit(repository);
    final connectivity = FakeConnectivity().createCubit();
    addTearDown(cubit.close);
    addTearDown(connectivity.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider<ConnectivityCubit>.value(value: connectivity),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: OnAirTheme.light,
          home: const ChangePasswordScreen(),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('current-password-field')),
      'Passw0rd!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'Nextpass1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password-field')),
      'Nextpass1',
    );
    await tester.pump();
    final button = find.byKey(const ValueKey('save-password'));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(repository.calls, 1);
  });

  testWidgets('success shows the localized snackbar and returns', (
    tester,
  ) async {
    final cubit = ChangePasswordCubit(_SuccessfulRepository());
    final fakeConnectivity = FakeConnectivity();
    final connectivity = fakeConnectivity.createCubit();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('done')),
        ),
        GoRoute(
          path: '/change',
          builder: (_, _) => const ChangePasswordScreen(),
        ),
      ],
    );
    addTearDown(cubit.close);
    addTearDown(connectivity.close);
    addTearDown(fakeConnectivity.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider<ConnectivityCubit>.value(value: connectivity),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: OnAirTheme.light,
        ),
      ),
    );
    unawaited(router.push('/change'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('current-password-field')),
      'Passw0rd!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'Nextpass1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password-field')),
      'Nextpass1',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-password')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final l10n = lookupAppLocalizations(const Locale('ar'));
    expect(find.text(l10n.accountPasswordChanged), findsOneWidget);
    expect(find.text('done'), findsOneWidget);
  });
}
