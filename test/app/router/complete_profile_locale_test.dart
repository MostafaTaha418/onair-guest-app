import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/app_router.dart';
import 'package:on_air/app/router/auth_router_refresh.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../helpers/fake_app_config_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_connectivity.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/pump_until_found.dart';

/// Review fix 8: the «أكّد رقمك» route builder passes the app's CURRENT
/// locale — with an English locale, `start()` carries `p_locale: 'en'`.
final class _CapturingRepository implements PhoneVerificationRepository {
  PhoneVerificationDraft? lastDraft;

  @override
  Future<String> start(
    PhoneVerificationDraft draft,
    PhoneVerificationPurpose purpose,
  ) async {
    lastDraft = draft;
    return 'challenge-1';
  }

  @override
  Future<WhatsAppChallenge> send(String challengeId) async {
    final now = DateTime.now().toUtc();
    return WhatsAppChallenge(
      challengeId: challengeId,
      maskedPhone: '+20 10•• ••• 678',
      expiresAt: now.add(const Duration(minutes: 10)),
      window: SendWindow(serverTime: now, receivedAt: now),
    );
  }

  @override
  Future<(DeliveryStatus, DeliveryFailure?, SendWindow)> status(
    String challengeId,
  ) async {
    final now = DateTime.now().toUtc();
    return (
      DeliveryStatus.delivered,
      null,
      SendWindow(serverTime: now, receivedAt: now),
    );
  }

  @override
  Future<GuestAccount> verify(String challengeId, String code) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('an English locale reaches start() as p_locale en', (
    tester,
  ) async {
    CairoTime.initialize();
    final auth = FakeAuthRepository()
      ..account = GuestAccount(
        id: 'id',
        status: AccountStatus.incomplete,
        email: 'guest@example.com',
      );
    final authCubit = AuthCubit(auth);
    await authCubit.restore();
    final searchCubit = SearchCubit(
      repo: FakeListingsRepository(),
      lastSearch: LastSearchStore(),
      connectivity: FakeConnectivity().createCubit(),
    );
    final repo = _CapturingRepository();
    final refresh = AuthRouterRefresh(authCubit);
    addTearDown(refresh.dispose);
    late final GoRouter router;
    addTearDown(() async {
      await searchCubit.close();
      await authCubit.close();
      router.dispose();
    });
    router = createAppRouter(
      refreshListenable: refresh,
      authCubit: authCubit,
      searchCubit: searchCubit,
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: auth),
          RepositoryProvider<PhoneVerificationRepository>.value(value: repo),
          RepositoryProvider<AppConfigSource>.value(
            value: FakeAppConfigRepository(
              const AppConfig(
                minSupportedBuildAndroid: 1,
                minSupportedBuildIos: 1,
                supportPhone: '+201000000000',
                currentTermsVersion: 'v1',
              ),
            ),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<SearchCubit>.value(value: searchCubit),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: OnAirTheme.light,
            darkTheme: OnAirTheme.dark,
          ),
        ),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('confirm-phone-field')),
    );

    // A tall surface keeps every control hit-testable (device-CI rule).
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-name-field')),
      'Mona Adel',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-phone-field')),
      '01012345678',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('confirm-phone-terms')),
    );
    await tester.tap(find.byKey(const ValueKey('confirm-phone-terms')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('confirm-phone-continue')),
    );
    await tester.tap(find.byKey(const ValueKey('confirm-phone-continue')));
    await tester.pump();

    expect(repo.lastDraft!.locale, 'en');
  });
}
