import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/account_gate/application/personal_data_resetter.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/account_gate/presentation/session_listener.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_auth_repository.dart';

final class _SessionEvents implements SessionEventSource {
  final controller = StreamController<SessionEndEvent>.broadcast();

  @override
  Stream<SessionEndEvent> get events => controller.stream;
}

final class _Resetter implements PersonalDataResetter {
  int calls = 0;

  @override
  Future<void> resetPersonalData() async => calls++;
}

final class _ControlledSignOut implements SignOutCoordinator {
  final ready = Completer<void>();

  @override
  Future<void> signOut() => ready.future;
}

void main() {
  final account = GuestAccount(
    id: 'guest',
    phone: '+201012345678',
    fullName: 'Guest Name',
    acceptedTermsVersion: 'v1',
  );

  for (final event in SessionEndEvent.values) {
    testWidgets(
      '${event.name} shows unauthenticated and returns to the same route',
      (tester) async {
        final repository = FakeAuthRepository()..account = account;
        final cubit = AuthCubit(repository, currentTermsVersion: 'v1');
        await cubit.restore();
        final sessionEvents = _SessionEvents();
        final resetter = _Resetter();
        final refresh = _CubitListenable(cubit);
        late final GoRouter router;
        router = GoRouter(
          initialLocation: AppRoutes.bookings,
          refreshListenable: refresh,
          redirect: (_, state) => resolveRedirect(
            RedirectContext(
              location: state.uri.path,
              authState: cubit.state,
              from: state.uri.queryParameters['from'],
            ),
          ),
          routes: [
            GoRoute(
              path: AppRoutes.bookings,
              builder: (_, _) => const Scaffold(body: Text('bookings-page')),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (_, _) => const Scaffold(body: Text('login-page')),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const Scaffold(body: Text('home-page')),
            ),
          ],
        );

        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: MaterialApp.router(
              routerConfig: router,
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
              ],
              builder: (context, child) => SessionListener(
                router: router,
                eventSource: sessionEvents,
                personalDataResetter: resetter,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('bookings-page'), findsOneWidget);

        sessionEvents.controller.add(event);
        await tester.pumpAndSettle();

        expect(find.text('login-page'), findsOneWidget);
        expect(
          find.text('انتهت الجلسة. سجّل الدخول مرة أخرى.'),
          findsOneWidget,
        );
        expect(resetter.calls, 1);

        repository.publish(account);
        await tester.pumpAndSettle();
        expect(find.text('bookings-page'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await sessionEvents.controller.close();
        router.dispose();
        refresh.dispose();
      },
    );
  }

  testWidgets('personal data resets only after sign-out cleanup', (
    tester,
  ) async {
    final repository = FakeAuthRepository()..account = account;
    final coordinator = _ControlledSignOut();
    final cubit = AuthCubit(
      repository,
      currentTermsVersion: 'v1',
      signOutCoordinator: coordinator,
    );
    await cubit.restore();
    final sessionEvents = _SessionEvents();
    final resetter = _Resetter();
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('home-page')),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => SessionListener(
            router: router,
            eventSource: sessionEvents,
            personalDataResetter: resetter,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final signOut = cubit.signOut();
    await tester.pump();
    expect(cubit.state, isA<SigningOut>());
    expect(resetter.calls, 0);

    coordinator.ready.complete();
    await signOut;
    await tester.pump();
    expect(cubit.state, isA<SignedOut>());
    expect(resetter.calls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await sessionEvents.controller.close();
    router.dispose();
  });
}

final class _CubitListenable extends ChangeNotifier {
  _CubitListenable(AuthCubit cubit) {
    _subscription = cubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
