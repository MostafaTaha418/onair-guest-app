import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/countdown_text.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/bookings_cubit.dart';
import 'package:on_air/features/bookings/presentation/bookings_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/pump_app.dart';

/// Returns empty pages for every tab.
final class EmptyBookings implements BookingsRepository {
  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) async =>
      const BookingsPage(items: [], nextCursor: null);

  @override
  Future<BookingDetails> getBooking(String bookingId) =>
      throw UnimplementedError();
}

/// A list request that never answers, to hold the skeleton on screen.
final class HeldBookings implements BookingsRepository {
  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) =>
      Completer<BookingsPage>().future;

  @override
  Future<BookingDetails> getBooking(String bookingId) =>
      throw UnimplementedError();
}

void main() {
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

  Future<void> pumpBookings(
    WidgetTester tester, {
    BookingTab initialTab = BookingTab.current,
    BookingsRepository? bookings,
    ConnectivityCubit? connectivityCubit,
  }) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repo = bookings ?? backend.server;
    final router = GoRouter(
      initialLocation: AppRoutes.bookingsTab(
        switch (initialTab) {
          BookingTab.current => 'current',
          BookingTab.past => 'past',
          _ => 'cancelled',
        },
      ),
      routes: [
        GoRoute(
          path: AppRoutes.bookings,
          builder: (context, state) {
            final tab = switch (state.uri.queryParameters['tab']) {
              'past' => BookingTab.past,
              'cancelled' => BookingTab.cancelled,
              _ => BookingTab.current,
            };
            return RepositoryProvider<BookingsRepository>.value(
              value: repo,
              child: BlocProvider<BookingsCubit>(
                create: (context) {
                  final cubit = BookingsCubit(
                    bookings: repo,
                    cache: backend.cache,
                    connectivity: context.read<ConnectivityCubit>(),
                  );
                  unawaited(cubit.start(tab));
                  return cubit;
                },
                child: BookingsScreen(initialTab: tab),
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.search,
          builder: (_, _) => const Text('search-stub'),
        ),
        GoRoute(
          path: AppRoutes.bookingDetailsPattern,
          builder: (_, state) => Text('details:${state.pathParameters['id']}'),
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
      connectivityCubit: connectivityCubit ?? connectivity.createCubit(),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();
  }

  testWidgets('the three tabs render with their labels and cards', (
    tester,
  ) async {
    await pumpBookings(tester);

    expect(find.text(l10n.bookingsTabCurrent), findsOneWidget);
    expect(find.text(l10n.bookingsTabPast), findsOneWidget);
    expect(find.text(l10n.bookingsTabCancelled), findsOneWidget);

    // The confirmed fixture card: title, dates, and the status chip.
    expect(find.text('شقة 3 غرف للتجربة'), findsWidgets);
    expect(
      find.text(
        '${DateOnlyFormatter.dayMonth(DateOnly.parse("2026-11-20"))} – '
        '${DateOnlyFormatter.dayMonth(DateOnly.parse("2026-11-23"))}',
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.bookingStatusConfirmed), findsOneWidget);
    expect(find.text(l10n.bookingStatusAwaitingOwner), findsOneWidget);
    expect(find.text(l10n.bookingStatusPaymentVerifying), findsOneWidget);
    expect(find.text(l10n.bookingStatusCheckedIn), findsOneWidget);
  });

  testWidgets('an awaiting-owner card shows the deadline countdown', (
    tester,
  ) async {
    await pumpBookings(tester);
    expect(find.byType(CountdownText), findsWidgets);
    expect(
      find.textContaining(RegExp(r'\d+:\d{2}')),
      findsWidgets,
      reason: 'the countdown text shows an H:MM remaining',
    );
  });

  testWidgets('a card tap opens the details route', (tester) async {
    await pumpBookings(tester);
    await tester.tap(find.text('شقة 3 غرف للتجربة').first);
    await tester.pump();
    await tester.pump();
    expect(
      find.text('details:b0000000-0000-4000-8000-000000000001'),
      findsOneWidget,
    );
  });

  testWidgets('an empty tab shows its message and the search button', (
    tester,
  ) async {
    await pumpBookings(
      tester,
      initialTab: BookingTab.cancelled,
      bookings: EmptyBookings(),
    );
    expect(find.text(l10n.bookingsEmptyCancelled), findsOneWidget);
    expect(find.text(l10n.bookingsFindApartment), findsOneWidget);

    await tester.tap(find.text(l10n.bookingsFindApartment));
    await tester.pump();
    await tester.pump();
    expect(find.text('search-stub'), findsOneWidget);
  });

  testWidgets('loading shows skeletons', (tester) async {
    await pumpBookings(tester, bookings: HeldBookings());
    expect(find.byType(SkeletonBox), findsWidgets);
  });

  testWidgets('offline with a cache shows the last-updated note', (
    tester,
  ) async {
    final server = await backend.server.listBookings(BookingTab.current);
    await backend.cache.saveTab(BookingTab.current, server.items);
    // The cubit must already be offline when the screen builds: a broadcast
    // flip is never replayed to a later subscriber.
    final conn = connectivity.createCubit();
    connectivity.goOffline();
    await tester.pump(const Duration(milliseconds: 50));

    await pumpBookings(tester, connectivityCubit: conn);

    final cached = (await backend.cache.readTab(BookingTab.current))!;
    expect(
      find.text(l10n.lastUpdated(formatCairoDayMonthTime(cached.fetchedAt))),
      findsOneWidget,
    );
    expect(find.text(l10n.offline), findsNothing);
  });

  testWidgets('payment_pending and abandoned fixtures never appear as cards', (
    tester,
  ) async {
    await pumpBookings(tester);

    await openTab(tester, l10n.bookingsTabPast);
    expect(find.text(l10n.bookingStatusCompleted), findsWidgets);
    expect(find.text(l10n.bookingStatusPaymentPending), findsNothing);
    expect(find.text(l10n.bookingStatusAbandoned), findsNothing);

    await openTab(tester, l10n.bookingsTabCancelled);
    expect(find.text(l10n.bookingStatusCancelled), findsWidgets);
    expect(find.text(l10n.bookingStatusPaymentPending), findsNothing);
    expect(find.text(l10n.bookingStatusAbandoned), findsNothing);
  });
}
