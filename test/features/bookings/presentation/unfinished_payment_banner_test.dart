import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/booking/domain/payment_attempt.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/unfinished_payment_cubit.dart';
import 'package:on_air/features/bookings/presentation/widgets/unfinished_payment_banner.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_booking_backend.dart';

const _property1f = '00000000-0000-4000-8000-00000000001f';

Future<String> _createPendingBooking(FakeBookingBackend backend) async {
  final quote = await backend.server.quote(
    propertyId: _property1f,
    stay: StayRange(DateOnly.parse('2026-11-20'), DateOnly.parse('2026-11-23')),
    guests: 2,
    termsHash: 'mock-terms-1',
  );
  final session = await backend.server.startPayment(
    quoteId: quote.quoteId,
    termsHash: quote.termsHash,
    attemptKey: 'attempt-key-1',
  );
  return session.bookingId;
}

/// A repository whose pending tab is empty (the JSON fixtures carry a
/// `payment_pending` booking that would otherwise light the banner).
final class _EmptyPending implements BookingsRepository {
  _EmptyPending(this._inner);

  final BookingsRepository _inner;

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) async =>
      tab == BookingTab.pending
      ? const BookingsPage(items: [], nextCursor: null)
      : _inner.listBookings(tab, cursor: cursor);

  @override
  Future<BookingDetails> getBooking(String bookingId) =>
      _inner.getBooking(bookingId);
}

Future<UnfinishedPaymentCubit> _refreshedCubit(
  FakeBookingBackend backend,
) async {
  final cubit = UnfinishedPaymentCubit(
    bookings: backend.server,
    attempts: backend.paymentAttempts,
  );
  await cubit.refresh();
  return cubit;
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required UnfinishedPaymentCubit cubit,
}) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => Scaffold(
          body: ListView(children: const [UnfinishedPaymentBanner()]),
        ),
      ),
      GoRoute(
        path: '/bookings',
        builder: (_, _) => Scaffold(
          body: ListView(children: const [UnfinishedPaymentBanner()]),
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentReturnPath,
        builder: (_, state) =>
            Text('return:${state.uri.queryParameters['booking']}'),
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (_, state) => Text('details:${state.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    BlocProvider<UnfinishedPaymentCubit>.value(
      value: cubit,
      child: MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: OnAirTheme.light,
        darkTheme: OnAirTheme.dark,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late FakeBookingBackend backend;
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    CairoTime.initialize();
  });

  setUp(() {
    backend = FakeBookingBackend();
  });

  tearDown(() {
    backend.dispose();
  });

  testWidgets('UnfinishedSome shows the banner on Home and My Bookings', (
    tester,
  ) async {
    await _createPendingBooking(backend);
    final cubit = await _refreshedCubit(backend);
    addTearDown(cubit.close);

    await _pumpHost(tester, cubit: cubit);
    expect(find.text(l10n.unfinishedPaymentBanner), findsOneWidget);

    // The same banner tops My Bookings.
    GoRouter.of(
      tester.element(find.text(l10n.unfinishedPaymentBanner)),
    ).go('/bookings');
    await tester.pump();
    expect(find.text(l10n.unfinishedPaymentBanner), findsOneWidget);
  });

  testWidgets('UnfinishedNone hides the banner', (tester) async {
    final cubit = UnfinishedPaymentCubit(
      bookings: _EmptyPending(backend.server),
      attempts: backend.paymentAttempts,
    );
    await cubit.refresh();
    addTearDown(cubit.close);
    await _pumpHost(tester, cubit: cubit);
    expect(find.text(l10n.unfinishedPaymentBanner), findsNothing);
  });

  testWidgets('tap opens the attempt verification screen', (tester) async {
    final bookingId = await _createPendingBooking(backend);
    await backend.paymentAttempts.save(
      PaymentAttempt(
        attemptKey: 'attempt-key-1',
        quoteId: 'q1',
        propertyId: _property1f,
        termsHash: 'mock-terms-1',
        startedAt: DateTime.utc(2026, 11, 1, 10),
        bookingId: bookingId,
      ),
    );
    final cubit = await _refreshedCubit(backend);
    addTearDown(cubit.close);
    await _pumpHost(tester, cubit: cubit);

    await tester.tap(find.text(l10n.unfinishedPaymentOpen));
    await tester.pump();
    await tester.pump();
    expect(find.text('return:$bookingId'), findsOneWidget);
  });

  testWidgets('tap opens the booking details without a stored attempt', (
    tester,
  ) async {
    final bookingId = await _createPendingBooking(backend);
    final cubit = await _refreshedCubit(backend);
    addTearDown(cubit.close);
    await _pumpHost(tester, cubit: cubit);

    await tester.tap(find.text(l10n.unfinishedPaymentOpen));
    await tester.pump();
    await tester.pump();
    expect(find.text('details:$bookingId'), findsOneWidget);
  });
}
