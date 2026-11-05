import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/stay/presentation/offer/offer_card.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/pump_app.dart';

const _booking26 = 'b0000000-0000-4000-8000-000000000026';
const _offerId = 'f0000000-0000-4000-8000-000000000099';

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late ConnectivityCubit connectivityCubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    CairoTime.initialize();
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

  ReplacementOffer offerFor({
    required int rawDifference,
    OfferStatus status = OfferStatus.pending,
    DateTime? expiresAt,
  }) => ReplacementOffer(
    id: _offerId,
    status: status,
    propertyId: '00000000-0000-4000-8000-00000000002f',
    propertyTitle: 'شقة بديلة على البحر',
    areaName: 'رأس البر',
    coverImage: null,
    stay: StayRange(
      DateOnly.parse('2026-11-15'),
      DateOnly.parse('2026-11-18'),
    ),
    difference: Money(rawDifference.abs()),
    direction: rawDifference > 0
        ? OfferDirection.guestPays
        : rawDifference < 0
        ? OfferDirection.guestRefunded
        : OfferDirection.none,
    expiresAt: expiresAt,
  );

  Future<void> pumpCard(WidgetTester tester, ReplacementOffer offer) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpOnAirApp(
      OfferCard(offer: offer, onAnswered: () {}),
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

  testWidgets('the difference reads differently per direction', (tester) async {
    await pumpCard(tester, offerFor(rawDifference: 50000));
    expect(
      find.text(
        l10n.offerPayMore(MoneyFormatter().format(Money(50000))),
      ),
      findsOneWidget,
    );

    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );
    await pumpCard(tester, offerFor(rawDifference: -50000));
    expect(
      find.text(
        l10n.offerRefundDiff(MoneyFormatter().format(Money(50000))),
      ),
      findsOneWidget,
    );

    backend.dispose();
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );
    await pumpCard(tester, offerFor(rawDifference: 0));
    expect(find.text(l10n.offerNoDiff), findsOneWidget);
  });

  testWidgets('a pending offer shows its expiry and the two answers', (
    tester,
  ) async {
    final expiresAt = DateTime.parse('2026-11-02T10:00:00Z').toUtc();
    await pumpCard(
      tester,
      offerFor(rawDifference: 50000, expiresAt: expiresAt),
    );

    expect(
      find.text(l10n.offerExpires(formatCairoDayMonthTime(expiresAt))),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('offer-accept')), findsOneWidget);
    expect(find.byKey(const ValueKey('offer-decline')), findsOneWidget);
  });

  testWidgets('accepting asks for confirmation with the difference', (
    tester,
  ) async {
    await pumpCard(tester, offerFor(rawDifference: 50000));

    await tester.tap(find.byKey(const ValueKey('offer-accept')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.offerAcceptDialogTitle), findsOneWidget);
    // The difference sentence is in the card banner and the dialog body.
    expect(
      find.text(
        l10n.offerPayMore(MoneyFormatter().format(Money(50000))),
      ),
      findsExactly(2),
    );
    expect(backend.stay.offerAnswers, 0);
  });

  testWidgets('answered statuses show their chip and no buttons', (
    tester,
  ) async {
    for (final (status, label) in [
      (OfferStatus.accepted, l10n.offerStatusAccepted),
      (OfferStatus.declined, l10n.offerStatusDeclined),
      (OfferStatus.expired, l10n.offerStatusExpired),
      (OfferStatus.withdrawn, l10n.offerStatusExpired),
    ]) {
      backend.dispose();
      backend = FakeBookingBackend(
        includeG3Fixtures: true,
        actionRegistry: BookingActionRegistry.g3(),
      );
      await pumpCard(tester, offerFor(status: status, rawDifference: 50000));

      expect(find.text(label), findsOneWidget, reason: status.name);
      expect(find.byKey(const ValueKey('offer-accept')), findsNothing);
      expect(find.byKey(const ValueKey('offer-decline')), findsNothing);
    }
  });

  testWidgets('focus=offer scrolls the offer card into view', (tester) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.bookingDetailsFocus(_booking26, 'offer'),
      routes: [
        GoRoute(
          path: AppRoutes.bookingDetailsPattern,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BlocProvider<BookingDetailsCubit>(
              create: (context) {
                final cubit = BookingDetailsCubit(
                  bookings: backend.server,
                  cache: backend.cache,
                  arrival: backend.arrivalInstructions,
                  signals: backend.signals,
                  connectivity: context.read<ConnectivityCubit>(),
                  bookingId: id,
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: BookingDetailsScreen(
                bookingId: id,
                focus: state.uri.queryParameters['focus'],
              ),
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
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The offer card is on screen: its rect overlaps the viewport.
    final cardRect = tester.getRect(find.byType(OfferCard));
    expect(cardRect.bottom, greaterThan(0));
    expect(cardRect.top, lessThan(1100));
  });
}
