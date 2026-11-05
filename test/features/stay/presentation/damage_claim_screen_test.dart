import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/features/app_update/presentation/not_available_screen.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_cubit.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_resolver_screen.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/pump_app.dart';

const _booking25 = 'b0000000-0000-4000-8000-000000000025';
const _claim1 = 'e0000000-0000-4000-8000-000000000001';
const _claim2 = 'e0000000-0000-4000-8000-000000000002';

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late ConnectivityCubit connectivityCubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );
    connectivity = FakeConnectivity();
    connectivityCubit = connectivity.createCubit();
  });

  tearDown(() async {
    await connectivityCubit.close();
    connectivity.dispose();
    backend.dispose();
  });

  Future<void> pumpClaim(WidgetTester tester, String claimId) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpOnAirApp(
      BlocProvider<DamageClaimCubit>(
        create: (context) {
          final cubit = DamageClaimCubit(
            stay: backend.stay,
            bookings: backend.server,
            attempts: backend.actionAttempts,
            registry: BookingActionRegistry.g3(),
            connectivity: context.read<ConnectivityCubit>(),
            logger: AppLogger(sink: (_) {}),
            bookingId: _booking25,
            claimId: claimId,
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: DamageClaimScreen(bookingId: _booking25, claimId: claimId),
      ),
      authRepository: FakeAuthRepository(),
      appConfigRepository: FakeAppConfigRepository(
        const AppConfig(
          minSupportedBuildAndroid: 1,
          minSupportedBuildIos: 1,
          supportPhone: '+201000000000',
          currentTermsVersion: 'mock-terms-1',
        ),
      ),
      bookingBackend: backend,
      connectivityCubit: connectivityCubit,
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the protection notice comes first with the open chip', (
    tester,
  ) async {
    await pumpClaim(tester, _claim1);

    final firstWidget = tester.widget<InfoBanner>(
      find.byType(InfoBanner).first,
    );
    expect(firstWidget.message, l10n.claimProtection);
    expect(find.text(l10n.claimStatusOpen), findsOneWidget);
  });

  testWidgets('a short dispute note shows the length error', (tester) async {
    await pumpClaim(tester, _claim1);

    await tester.tap(find.byKey(const ValueKey('claim-dispute')));
    await tester.pump();
    final noteField = find.byType(TextField);
    await tester.enterText(noteField, '01234');
    await tester.tap(find.byKey(const ValueKey('claim-send-dispute')));
    await tester.pump();

    expect(find.text(l10n.claimDisputeTooShort), findsOneWidget);
    expect(backend.stay.claimAnswers, 0);
  });

  testWidgets('agree opens its confirmation dialog with the amount', (
    tester,
  ) async {
    await pumpClaim(tester, _claim1);

    await tester.tap(find.byKey(const ValueKey('claim-agree')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        l10n.claimAgreeDialogBody(MoneyFormatter().format(Money(50000))),
      ),
      findsOneWidget,
    );
    expect(backend.stay.claimAnswers, 0);
  });

  testWidgets('the resolved claim shows its outcome and no buttons', (
    tester,
  ) async {
    await pumpClaim(tester, _claim2);

    expect(find.text(l10n.claimOutcomeNoCharge), findsOneWidget);
    expect(find.byKey(const ValueKey('claim-agree')), findsNothing);
    expect(find.byKey(const ValueKey('claim-dispute')), findsNothing);
  });

  testWidgets('there is no attachment picker', (tester) async {
    await pumpClaim(tester, _claim1);

    expect(find.byIcon(AppIcons.photoStack), findsNothing);
  });

  testWidgets('tapping a thumbnail opens the paged viewer', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpClaim(tester, _claim1);

    await tester.tap(find.bySemanticsLabel(l10n.claimEvidencePhoto('1', '2')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.claimEvidencePhoto('1', '2')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the resolver replaces itself with the claim route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.damageClaimResolver(_claim1),
      routes: [
        GoRoute(
          path: AppRoutes.damageClaimResolverPattern,
          name: 'damage-claim-resolver',
          builder: (_, state) => DamageClaimResolverScreen(
            claimId: state.pathParameters['claimId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.damageClaimPattern,
          name: 'linked-damage-claim',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final claimId = state.pathParameters['claimId']!;
            return BlocProvider<DamageClaimCubit>(
              create: (context) {
                final cubit = DamageClaimCubit(
                  stay: backend.stay,
                  bookings: backend.server,
                  attempts: backend.actionAttempts,
                  registry: BookingActionRegistry.g3(),
                  connectivity: context.read<ConnectivityCubit>(),
                  logger: AppLogger(sink: (_) {}),
                  bookingId: id,
                  claimId: claimId,
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: DamageClaimScreen(bookingId: id, claimId: claimId),
            );
          },
        ),
      ],
    );
    await tester.pumpOnAirApp(
      const SizedBox.shrink(),
      routerConfig: router,
      authRepository: FakeAuthRepository(),
      appConfigRepository: FakeAppConfigRepository(
        const AppConfig(
          minSupportedBuildAndroid: 1,
          minSupportedBuildIos: 1,
          supportPhone: '+201000000000',
          currentTermsVersion: 'mock-terms-1',
        ),
      ),
      bookingBackend: backend,
      connectivityCubit: connectivityCubit,
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.claimTitle), findsOneWidget);
    expect(find.byType(DamageClaimResolverScreen), findsNothing);
  });

  testWidgets('an unknown claim id shows the not-available screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.damageClaimResolver(
        'e0000000-0000-4000-8000-0000000000ff',
      ),
      routes: [
        GoRoute(
          path: AppRoutes.damageClaimResolverPattern,
          name: 'damage-claim-resolver',
          builder: (_, state) => DamageClaimResolverScreen(
            claimId: state.pathParameters['claimId']!,
          ),
        ),
      ],
    );
    await tester.pumpOnAirApp(
      const SizedBox.shrink(),
      routerConfig: router,
      authRepository: FakeAuthRepository(),
      appConfigRepository: FakeAppConfigRepository(
        const AppConfig(
          minSupportedBuildAndroid: 1,
          minSupportedBuildIos: 1,
          supportPhone: '+201000000000',
          currentTermsVersion: 'mock-terms-1',
        ),
      ),
      bookingBackend: backend,
      connectivityCubit: connectivityCubit,
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotAvailableScreen), findsOneWidget);
  });
}
