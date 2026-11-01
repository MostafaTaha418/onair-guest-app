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
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/components/refund_stage_tracker.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/bookings/presentation/bookings_cubit.dart';
import 'package:on_air/features/bookings/presentation/bookings_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/pump_app.dart';

/// Replaces every refund with a `failed` one, to exercise the problem UI.
final class FailedRefundBookings implements BookingsRepository {
  FailedRefundBookings(this._inner);

  final BookingsRepository _inner;

  @override
  Future<BookingDetails> getBooking(String bookingId) async {
    final details = await _inner.getBooking(bookingId);
    return BookingDetails.fromJson({
      ...details.toCacheJson(),
      'refund': {
        'id': 'd0000000-0000-4000-8000-0000000000f0',
        'amount_minor': details.paid.amountMinor,
        'status': 'failed',
        'updated_at': '2026-10-29T10:00:00Z',
      },
    });
  }

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) =>
      _inner.listBookings(tab, cursor: cursor);
}

void main() {
  const rejectedId = 'b0000000-0000-4000-8000-000000000006';
  const expiredId = 'b0000000-0000-4000-8000-000000000007';
  const conflictId = 'b0000000-0000-4000-8000-000000000010';
  const cancelledId = 'b0000000-0000-4000-8000-000000000008';
  const confirmedId = 'b0000000-0000-4000-8000-000000000001';

  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    CairoTime.initialize();
  });

  setUp(() {
    backend = FakeBookingBackend();
    connectivity = FakeConnectivity();
  });

  tearDown(() {
    backend.dispose();
    connectivity.dispose();
  });

  Future<void> pumpDetails(
    WidgetTester tester,
    String bookingId, {
    BookingsRepository? bookings,
  }) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repo = bookings ?? backend.server;
    final router = GoRouter(
      initialLocation: AppRoutes.bookingDetails(bookingId),
      routes: [
        GoRoute(
          path: AppRoutes.bookingDetailsPattern,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return RepositoryProvider<BookingsRepository>.value(
              value: repo,
              child: BlocProvider<BookingDetailsCubit>(
                create: (context) {
                  final cubit = BookingDetailsCubit(
                    bookings: repo,
                    cache: backend.cache,
                    arrival: backend.arrivalInstructions,
                    signals: backend.signals,
                    connectivity: context.read<ConnectivityCubit>(),
                    bookingId: id,
                  );
                  unawaited(cubit.load());
                  return cubit;
                },
                child: BookingDetailsScreen(bookingId: id),
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
      connectivityCubit: connectivity.createCubit(),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  /// Pumps My Bookings straight onto one tab (no tab taps needed here).
  Future<void> pumpBookingsTab(WidgetTester tester, String tabWire) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.bookingsTab(tabWire),
      routes: [
        GoRoute(
          path: AppRoutes.bookings,
          builder: (context, state) {
            final tab = switch (state.uri.queryParameters['tab']) {
              'past' => BookingTab.past,
              'cancelled' => BookingTab.cancelled,
              _ => BookingTab.current,
            };
            return BlocProvider<BookingsCubit>(
              create: (context) {
                final cubit = BookingsCubit(
                  bookings: backend.server,
                  cache: backend.cache,
                  connectivity: context.read<ConnectivityCubit>(),
                );
                unawaited(cubit.start(tab));
                return cubit;
              },
              child: BookingsScreen(initialTab: tab),
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
      connectivityCubit: connectivity.createCubit(),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  RefundStageTracker tracker(WidgetTester tester) =>
      tester.widget<RefundStageTracker>(find.byType(RefundStageTracker));

  testWidgets('rejected: stage requested, chip, and the paid amount', (
    tester,
  ) async {
    await pumpDetails(tester, rejectedId);
    expect(find.text(l10n.refundTitle), findsOneWidget);
    expect(find.text(l10n.refundAmount), findsOneWidget);
    // The same figure is also the paid amount in the payments section.
    expect(
      find.text(MoneyFormatter().format(Money(60000))),
      findsExactly(2),
    );
    expect(tracker(tester).currentIndex, 0);
    expect(tracker(tester).failed, isFalse);
    expect(find.text(l10n.refundChipRequested), findsOneWidget);
    // The reached-step checks stop at the current stage (AC-042).
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text(l10n.refundChipDone), findsNothing);
    // AC-020: the message carries the full paid amount.
    expect(
      find.text(
        l10n.bookingMsgRejected(MoneyFormatter().format(Money(60000))),
      ),
      findsOneWidget,
    );
  });

  testWidgets('expired: stage approved, chip in progress, and the amount', (
    tester,
  ) async {
    await pumpDetails(tester, expiredId);
    expect(tracker(tester).currentIndex, 1);
    expect(find.text(l10n.refundChipInProgress), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(find.text(l10n.refundChipDone), findsNothing);
    // AC-021: the message carries the full paid amount.
    expect(
      find.text(l10n.bookingMsgExpired(MoneyFormatter().format(Money(50000)))),
      findsOneWidget,
    );
  });

  testWidgets('conflict: stage executed still is not refunded', (tester) async {
    await pumpDetails(tester, conflictId);
    expect(tracker(tester).currentIndex, 2);
    expect(find.text(l10n.refundChipInProgress), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    expect(find.text(l10n.refundChipDone), findsNothing);
  });

  testWidgets('cancelled: only the verified refund shows refunded', (
    tester,
  ) async {
    await pumpDetails(tester, cancelledId);
    expect(tracker(tester).currentIndex, 3);
    expect(find.text(l10n.refundChipDone), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
    expect(find.text(l10n.refundProblemHint), findsNothing);
  });

  testWidgets('a failed refund shows the problem hint', (tester) async {
    await pumpDetails(
      tester,
      rejectedId,
      bookings: FailedRefundBookings(backend.server),
    );
    expect(find.text(l10n.refundChipProblem), findsOneWidget);
    expect(find.text(l10n.refundProblemHint), findsOneWidget);
    expect(tracker(tester).failed, isTrue);
  });

  testWidgets('the cancelled tab cards carry the refund chips', (tester) async {
    await pumpBookingsTab(tester, 'cancelled');
    // Fixtures 06/07/08/10 sit in this tab with four refund stages.
    expect(find.text(l10n.refundChipRequested), findsOneWidget);
    expect(find.text(l10n.refundChipInProgress), findsNWidgets(2));
    expect(find.text(l10n.refundChipDone), findsOneWidget);
  });

  testWidgets('the confirmed fixture shows the remaining-due message', (
    tester,
  ) async {
    await pumpDetails(tester, confirmedId);
    expect(
      find.text(
        l10n.bookingMsgConfirmedWithRemaining(
          MoneyFormatter().format(Money(337500)),
        ),
      ),
      findsOneWidget,
    );
    expect(find.byType(RefundStageTracker), findsNothing);
  });
}
