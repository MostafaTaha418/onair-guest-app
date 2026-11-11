import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/payment_attempt.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/booking/presentation/payment_return_screen.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_in_app_browser.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const property1f = '00000000-0000-4000-8000-00000000001f';

  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late FakeInAppBrowser browser;
  late PaymentAttemptCubit attemptCubit;
  late AppLocalizations l10n;
  late AppLocalizations l10nEn;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
    CairoTime.initialize();
  });

  setUp(() {
    backend = FakeBookingBackend(includeG3Fixtures: true);
    connectivity = FakeConnectivity();
    browser = FakeInAppBrowser();
    attemptCubit = PaymentAttemptCubit(
      flow: backend.server,
      store: backend.paymentAttempts,
      browser: () => browser,
      logger: AppLogger(sink: (_) {}),
    );
  });

  tearDown(() async {
    await attemptCubit.close();
    backend.dispose();
    connectivity.dispose();
  });

  /// One attempt key per booking so sessions never collide.
  var attemptCounter = 0;

  Future<String> bookingFor(MockPaymentResult result) async {
    final quote = await backend.server.quote(
      propertyId: property1f,
      stay: StayRange(
        CairoTime.today().addDays(20),
        CairoTime.today().addDays(23),
      ),
      guests: 2,
      termsHash: 'mock-terms-1',
    );
    final session = await backend.server.startPayment(
      quoteId: quote.quoteId,
      termsHash: 'mock-terms-1',
      attemptKey: 'attempt-outcome-${++attemptCounter}'.padRight(36, '0'),
    );
    if (result != MockPaymentResult.silent) {
      await backend.server.completePayment(session.bookingId, result);
    } else {
      await backend.server.completePayment(
        session.bookingId,
        MockPaymentResult.silent,
      );
    }
    return session.bookingId;
  }

  Future<void> pumpReturn(
    WidgetTester tester, {
    required String bookingId,
    Size size = const Size(400, 1800),
    double textScaleFactor = 1,
    Locale locale = const Locale('ar'),
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final router = GoRouter(
      initialLocation: AppRoutes.paymentReturn(bookingId: bookingId),
      routes: [
        GoRoute(
          path: AppRoutes.paymentReturnPath,
          name: 'payment-return',
          builder: (_, state) => BlocProvider<PaymentAttemptCubit>.value(
            value: attemptCubit,
            child: PaymentReturnScreen(
              bookingIdFromLink: state.uri.queryParameters['booking'],
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.bookings,
          builder: (_, _) => const Text('bookings-stub'),
        ),
        GoRoute(
          path: '/property/:id',
          builder: (_, _) => const Text('property-stub'),
        ),
        GoRoute(
          path: AppRoutes.bookingDetailsPattern,
          builder: (_, _) => const Text('details-stub'),
        ),
        GoRoute(
          path: AppRoutes.remainingPaymentPattern,
          builder: (_, _) => const Text('remaining-stub'),
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
      locale: locale,
      themeMode: themeMode,
    );
    await tester.pump();
  }

  testWidgets('waiting shows the verifying copy and no retry button', (
    tester,
  ) async {
    final bookingId = await bookingFor(MockPaymentResult.silent);
    await pumpReturn(tester, bookingId: bookingId);

    // The app bar and the body share the title.
    expect(find.text(l10n.paymentVerifying), findsNWidgets(2));
    expect(find.byKey(const ValueKey('return-try-again')), findsNothing);
    expect(find.byKey(const ValueKey('summary-pay')), findsNothing);
  });

  testWidgets('waiting immediately offers the stored checkout recovery', (
    tester,
  ) async {
    final bookingId = await bookingFor(MockPaymentResult.silent);
    await backend.paymentAttempts.save(
      PaymentAttempt(
        attemptKey: 'attempt-wait-${++attemptCounter}'.padRight(36, '0'),
        quoteId: 'quote-x',
        propertyId: property1f,
        termsHash: 'mock-terms-1',
        bookingId: bookingId,
        paymentUrl: 'https://pay.mock.onair.test/session/$bookingId',
        paymentUrlExpiresAt: DateTime.now().toUtc().add(
          const Duration(minutes: 5),
        ),
        startedAt: DateTime.now().toUtc(),
      ),
    );
    await attemptCubit.restore();
    await pumpReturn(tester, bookingId: bookingId);

    expect(
      find.byKey(const ValueKey('return-reopen-checkout')),
      findsOneWidget,
    );
  });

  testWidgets('recovery supports narrow English, dark mode and large text', (
    tester,
  ) async {
    final bookingId = await bookingFor(MockPaymentResult.silent);
    await backend.paymentAttempts.save(
      PaymentAttempt(
        attemptKey: 'attempt-a11y-${++attemptCounter}'.padRight(36, '0'),
        quoteId: 'quote-x',
        propertyId: property1f,
        termsHash: 'mock-terms-1',
        bookingId: bookingId,
        paymentUrl: 'https://pay.mock.onair.test/session/$bookingId',
        paymentUrlExpiresAt: DateTime.now().toUtc().add(
          const Duration(minutes: 5),
        ),
        startedAt: DateTime.now().toUtc(),
      ),
    );
    await attemptCubit.restore();
    await pumpReturn(
      tester,
      bookingId: bookingId,
      size: const Size(320, 700),
      textScaleFactor: 1.6,
      locale: const Locale('en'),
      themeMode: ThemeMode.dark,
    );

    final action = find.text(l10nEn.paymentResumeCheckout);
    expect(action, findsOneWidget);
    expect(Directionality.of(tester.element(action)), TextDirection.ltr);
    expect(Theme.of(tester.element(action)).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('success shows the title, the countdown, and view booking', (
    tester,
  ) async {
    final bookingId = await bookingFor(MockPaymentResult.success);
    await pumpReturn(tester, bookingId: bookingId);
    await tester.pump();

    expect(find.text(l10n.paymentSuccessTitle), findsOneWidget);
    // The countdown renders the real remaining time inside the template.
    final countdownPrefix = l10n.ownerDeadlineCountdown('x').split('x').first;
    expect(find.textContaining(countdownPrefix), findsOneWidget);
    expect(find.byKey(const ValueKey('return-view-booking')), findsOneWidget);
  });

  testWidgets('the deadline is announced once with the static Cairo label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final bookingId = await bookingFor(MockPaymentResult.success);
    final details = await backend.server.getBooking(bookingId);
    final expected = l10n.bookingMsgAwaitingOwner(
      formatCairoDayMonthTime(details.ownerResponseDeadline!),
    );
    await pumpReturn(tester, bookingId: bookingId);
    await tester.pump();

    SemanticsNode deadlineNode() =>
        tester.getSemantics(find.bySemanticsLabel(RegExp(expected)));
    expect(deadlineNode().label, expected);
    // The ticking remaining-time template never reaches semantics.
    final ticking = RegExp(l10n.ownerDeadlineCountdown('x').split('x').first);
    expect(find.bySemanticsLabel(ticking), findsNothing);

    await tester.pump(const Duration(seconds: 2));

    expect(deadlineNode().label, expected);
    expect(find.bySemanticsLabel(ticking), findsNothing);
    handle.dispose();
  });

  testWidgets('a failed payment offers try again', (tester) async {
    final bookingId = await bookingFor(MockPaymentResult.failure);
    await pumpReturn(tester, bookingId: bookingId);
    await tester.pump();

    expect(find.text(l10n.paymentFailedTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('return-try-again')), findsOneWidget);
  });

  testWidgets('a conflict offers find other dates', (tester) async {
    final bookingId = await bookingFor(MockPaymentResult.conflict);
    await pumpReturn(tester, bookingId: bookingId);
    await tester.pump();

    expect(find.text(l10n.paymentConflictTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('return-find-dates')), findsOneWidget);
  });

  testWidgets('a timeout shows the go-to-bookings screen', (tester) async {
    final bookingId = await bookingFor(MockPaymentResult.silent);
    await pumpReturn(tester, bookingId: bookingId);
    // The full default backoff is 120 s; one pump past it reaches the
    // timeout state.
    await tester.pump(const Duration(seconds: 125));
    await tester.pumpAndSettle();

    expect(find.text(l10n.paymentTimeoutTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('return-go-bookings')), findsOneWidget);
  });

  testWidgets('the link cannot turn a failed payment into a success', (
    tester,
  ) async {
    final bookingId = await bookingFor(MockPaymentResult.failure);
    await pumpReturn(
      tester,
      bookingId: bookingId,
    );
    await tester.pump();

    // The screen only reads `booking`; there is no `status` parameter at
    // all, and the failed server state decides the outcome.
    expect(find.text(l10n.paymentFailedTitle), findsOneWidget);
    expect(find.text(l10n.paymentSuccessTitle), findsNothing);
  });

  Future<void> pumpReturnWithAttempt(
    WidgetTester tester, {
    required String bookingId,
  }) async {
    await backend.paymentAttempts.save(
      PaymentAttempt(
        attemptKey: 'attempt-return-${++attemptCounter}'.padRight(36, '0'),
        quoteId: 'quote-x',
        propertyId: property1f,
        termsHash: 'mock-terms-1',
        bookingId: bookingId,
        startedAt: DateTime.utc(2026, 11, 1, 9),
      ),
    );
    await attemptCubit.restore();
    await pumpReturn(tester, bookingId: bookingId);
  }

  testWidgets('a resolved outcome clears the attempt without any tap: '
      'success', (tester) async {
    final bookingId = await bookingFor(MockPaymentResult.success);
    await pumpReturnWithAttempt(tester, bookingId: bookingId);
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.paymentSuccessTitle), findsOneWidget);
    expect(await backend.paymentAttempts.read(), isNull);
  });

  testWidgets('a resolved outcome clears the attempt without any tap: '
      'conflict', (tester) async {
    final bookingId = await bookingFor(MockPaymentResult.conflict);
    await pumpReturnWithAttempt(tester, bookingId: bookingId);
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.paymentConflictTitle), findsOneWidget);
    expect(await backend.paymentAttempts.read(), isNull);
  });

  testWidgets('a failed payment keeps the stored attempt for try again', (
    tester,
  ) async {
    final bookingId = await bookingFor(MockPaymentResult.failure);
    await pumpReturnWithAttempt(tester, bookingId: bookingId);
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.paymentFailedTitle), findsOneWidget);
    expect(await backend.paymentAttempts.read(), isNotNull);
  });

  testWidgets('a timeout keeps the stored attempt for the banner', (
    tester,
  ) async {
    final bookingId = await bookingFor(MockPaymentResult.silent);
    await pumpReturnWithAttempt(tester, bookingId: bookingId);
    // The full default backoff is 120 s; one pump past it reaches the
    // timeout state.
    await tester.pump(const Duration(seconds: 125));
    await tester.pumpAndSettle();

    expect(find.text(l10n.paymentTimeoutTitle), findsOneWidget);
    expect(await backend.paymentAttempts.read(), isNotNull);
  });

  testWidgets('a timeout can reopen a still-valid checkout once', (
    tester,
  ) async {
    final bookingId = await bookingFor(MockPaymentResult.silent);
    await backend.paymentAttempts.save(
      PaymentAttempt(
        attemptKey: 'attempt-reopen-${++attemptCounter}'.padRight(36, '0'),
        quoteId: 'quote-x',
        propertyId: property1f,
        termsHash: 'mock-terms-1',
        bookingId: bookingId,
        paymentUrl: 'https://pay.mock.onair.test/session/$bookingId',
        paymentUrlExpiresAt: DateTime.now().toUtc().add(
          const Duration(minutes: 5),
        ),
        startedAt: DateTime.now().toUtc(),
      ),
    );
    await attemptCubit.restore();
    await pumpReturn(tester, bookingId: bookingId);
    await tester.pump(const Duration(seconds: 125));
    await tester.pumpAndSettle();

    final reopen = find.byKey(const ValueKey('return-reopen-checkout'));
    expect(reopen, findsOneWidget);
    await tester.tap(reopen);
    await tester.pump();
    await tester.tap(reopen);
    await tester.pump();

    expect(browser.opened, hasLength(1));
    expect(browser.opened.single.bookingId, bookingId);
  });

  Future<String> remainingBookingFor(MockPaymentResult result) async {
    const bookingId = 'b0000000-0000-4000-8000-000000000020';
    final session = await backend.server.startRemainingPayment(
      bookingId: bookingId,
      attemptKey: 'remaining-outcome-${++attemptCounter}'.padRight(36, '0'),
    );
    final attempt = PaymentAttempt.remaining(
      attemptKey: 'stored-remaining-${++attemptCounter}'.padRight(36, '0'),
      bookingId: bookingId,
      startedAt: DateTime.utc(2026, 11, 1, 9),
    ).copyWith(paymentId: session.paymentId);
    await backend.paymentAttempts.save(attempt);
    await attemptCubit.restore();
    await backend.server.completePayment(bookingId, result);
    return bookingId;
  }

  testWidgets('remaining success shows paid copy without owner deadline', (
    tester,
  ) async {
    final bookingId = await remainingBookingFor(MockPaymentResult.success);
    await pumpReturn(tester, bookingId: bookingId);
    await tester.pump();

    expect(find.text(l10n.remainingPaidTitle), findsOneWidget);
    final countdownPrefix = l10n.ownerDeadlineCountdown('x').split('x').first;
    expect(find.textContaining(countdownPrefix), findsNothing);
    expect(find.byKey(const ValueKey('return-view-booking')), findsOneWidget);
  });

  testWidgets('remaining failure retries the remaining payment route', (
    tester,
  ) async {
    final bookingId = await remainingBookingFor(MockPaymentResult.failure);
    await pumpReturn(tester, bookingId: bookingId);
    await tester.pump();

    expect(find.text(l10n.remainingFailedBody), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('return-try-again')));
    await tester.pumpAndSettle();
    expect(find.text('remaining-stub'), findsOneWidget);
  });
}
