import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/domain/quote_change.dart';
import 'package:on_air/features/booking/presentation/booking_flow_cubit.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/booking/presentation/summary_screen.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_in_app_browser.dart';
import '../../../helpers/fake_listings_repository.dart';
import '../../../helpers/pump_app.dart';

PropertyDetails _property(String id, String termsVersion) => PropertyDetails(
  id: id,
  title: 'شقة',
  description: 'وصف',
  propertyType: 'apartment',
  areaName: 'المعادي',
  cityName: 'القاهرة',
  governorateName: 'القاهرة',
  addressText: 'شارع 9',
  images: const [],
  bedrooms: 3,
  bathrooms: 2,
  maxGuests: 6,
  areaSqm: 120,
  amenities: const [],
  rules: const StayRules(
    checkInTime: '14:00',
    checkOutTime: '12:00',
    visitorsAllowed: false,
    maxVisitors: null,
    houseRules: null,
  ),
  policy: const PolicySummary(
    depositType: DepositType.percent,
    depositPercentBp: 2500,
    depositAmount: null,
    freeCancellationHours: 72,
  ),
  nightlyPrice: Money(150000),
  ratingAvg: null,
  reviewCount: 0,
  latestReviews: const [],
  termsVersion: termsVersion,
);

/// Delegates to the mock server but counts (and can hold) payment starts.
final class InterruptibleFlow implements BookingFlowRepository {
  InterruptibleFlow(this._inner);

  final BookingFlowRepository _inner;
  int startCalls = 0;
  Completer<PaymentSessionInfo>? holdStart;
  AppFailure? nextStartFailure;

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) => _inner.quote(
    propertyId: propertyId,
    stay: stay,
    guests: guests,
    termsHash: termsHash,
  );

  @override
  Future<VerificationStatus> verificationStatus() =>
      _inner.verificationStatus();

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) {
    startCalls++;
    final failure = nextStartFailure;
    if (failure != null) throw failure;
    final hold = holdStart;
    if (hold != null) return hold.future;
    return _inner.startPayment(
      quoteId: quoteId,
      termsHash: termsHash,
      attemptKey: attemptKey,
    );
  }

  @override
  Future<PhoneChallenge> requestPhoneChange({
    required String phoneE164,
    required bool hasWhatsapp,
    String? whatsappE164,
  }) => _inner.requestPhoneChange(
    phoneE164: phoneE164,
    hasWhatsapp: hasWhatsapp,
    whatsappE164: whatsappE164,
  );

  @override
  Future<void> sendCode(String challengeId) => _inner.sendCode(challengeId);

  @override
  Future<void> verifyCode({
    required String challengeId,
    required String code,
  }) => _inner.verifyCode(challengeId: challengeId, code: code);
}

/// A re-priced version of the server quote: same stay, higher amounts.
BookingQuote _reprice(BookingQuote quote) => BookingQuote(
  quoteId: 'quote-changed',
  propertyId: quote.propertyId,
  stay: quote.stay,
  nights: quote.nights,
  guests: quote.guests,
  nightly: Money(180000),
  total: Money(540000),
  payNow: Money(135000),
  remaining: Money(405000),
  remainingDueAt: quote.remainingDueAt,
  termsHash: quote.termsHash,
  policySummary: quote.policySummary,
  expiresAt: quote.expiresAt,
);

void main() {
  const property1f = '00000000-0000-4000-8000-00000000001f';

  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late FakeInAppBrowser browser;
  late PaymentAttemptCubit attemptCubit;
  late InterruptibleFlow flow;
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    CairoTime.initialize();
  });

  setUp(() {
    backend = FakeBookingBackend();
    connectivity = FakeConnectivity();
    browser = FakeInAppBrowser();
    flow = InterruptibleFlow(backend.server);
    attemptCubit = PaymentAttemptCubit(
      flow: flow,
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

  Future<BookingFlowCubit> pumpSummary(
    WidgetTester tester, {
    required FakeListingsRepository listings,
  }) async {
    tester.view.physicalSize = const Size(400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    BookingFlowCubit? cubit;
    final router = GoRouter(
      initialLocation: AppRoutes.bookingSummary(property1f),
      routes: [
        GoRoute(
          path: AppRoutes.bookingSummaryPattern,
          builder: (context, state) => BlocProvider<PaymentAttemptCubit>.value(
            value: attemptCubit,
            child: BlocProvider<BookingFlowCubit>(
              create: (context) {
                final created = BookingFlowCubit(
                  listings: listings,
                  flow: flow,
                  connectivity: context.read<ConnectivityCubit>(),
                  propertyId: property1f,
                  termsHash: 'mock-terms-1',
                  initialStay: StayRange(
                    CairoTime.today().addDays(20),
                    CairoTime.today().addDays(23),
                  ),
                  initialGuests: 2,
                );
                cubit = created;
                unawaited(() async {
                  await created.load();
                  await created.requestQuote();
                }());
                return created;
              },
              child: const SummaryScreen(propertyId: property1f),
            ),
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
      connectivityCubit: connectivity.createCubit(),
    );
    await tester.pumpAndSettle();
    return cubit!;
  }

  testWidgets('changed amounts show the old value struck through and need '
      'confirmation before paying', (tester) async {
    final listings = FakeListingsRepository()
      ..propertyResponses.add(_property(property1f, 'mock-terms-1'))
      ..unavailableNightsResponses.add(<DateOnly>{});
    final flowCubit = await pumpSummary(tester, listings: listings);

    // The server re-priced while the guest read the summary.
    final old = flowCubit.state.quote!;
    flowCubit.emit(
      flowCubit.state.copyWith(
        quote: _reprice(old),
        pendingChange: QuoteChange.between(old, _reprice(old)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.quoteChangedNotice), findsOneWidget);
    // Old amounts struck through next to the new ones.
    expect(find.text('EGP 1,500.00'), findsOneWidget);
    expect(find.text('EGP 1,800.00'), findsOneWidget);
    expect(find.text('EGP 4,500.00'), findsOneWidget);
    expect(find.text('EGP 5,400.00'), findsOneWidget);
    final nightlyRow = tester
        .widgetList<AmountRow>(find.byType(AmountRow))
        .firstWhere((row) => row.label == l10n.bookingNightlyPrice);
    expect(nightlyRow.highlighted, isTrue);
    expect(nightlyRow.previousValue, 'EGP 1,500.00');

    // The pay button is replaced until the guest confirms the new amounts.
    expect(find.byKey(const ValueKey('summary-pay')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('quote-confirm-new')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.quoteChangedNotice), findsNothing);
    final pay = tester.widget<OnAirPrimaryButton>(
      find.byKey(const ValueKey('summary-pay')),
    );
    expect(pay.onPressed, isNotNull);
  });

  testWidgets('changed terms show the notice, the new lines, and an accept '
      'button that re-quotes', (tester) async {
    final listings = FakeListingsRepository()
      ..propertyResponses.add(_property(property1f, 'mock-terms-1'))
      ..unavailableNightsResponses.add(<DateOnly>{});
    final flowCubit = await pumpSummary(tester, listings: listings);

    // The server refused the payment start: the terms moved on.
    listings.propertyResponses.add(_property(property1f, 'mock-terms-2'));
    unawaited(
      flowCubit.onPaymentError(
        const ApiError(
          code: ErrorCode.termsChanged,
          messageKey: 'TERMS_CHANGED',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.termsChangedNotice), findsOneWidget);
    expect(find.byKey(const ValueKey('terms-accept-new')), findsOneWidget);
    // The pay button is disabled while the terms are unaccepted.
    final pay = tester.widget<OnAirPrimaryButton>(
      find.byKey(const ValueKey('summary-pay')),
    );
    expect(pay.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('terms-accept-new')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.termsChangedNotice), findsNothing);
    expect(flowCubit.state.termsHash, 'mock-terms-2');
    final payAgain = tester.widget<OnAirPrimaryButton>(
      find.byKey(const ValueKey('summary-pay')),
    );
    expect(payAgain.onPressed, isNotNull);
  });

  testWidgets('a double tap on pay starts one session', (tester) async {
    final listings = FakeListingsRepository()
      ..propertyResponses.add(_property(property1f, 'mock-terms-1'))
      ..unavailableNightsResponses.add(<DateOnly>{});
    await pumpSummary(tester, listings: listings);

    flow.holdStart = Completer<PaymentSessionInfo>();
    await tester.tap(find.byKey(const ValueKey('summary-pay')));
    await tester.pump();
    // The button is already loading; a second tap must not queue a start.
    await tester.tap(find.byKey(const ValueKey('summary-pay')));
    await tester.pump();
    expect(flow.startCalls, 1);
    flow.holdStart!.complete(
      PaymentSessionInfo(
        bookingId: 'b0000000-0000-4000-8000-000000000099',
        paymentId: 'p99',
        paymentUrl: Uri.parse(
          'https://pay.mock.onair.test/session/b0000000-0000-4000-8000-000000000099',
        ),
        paymentUrlExpiresAt: DateTime.utc(2026, 11, 1, 10, 30),
      ),
    );
    await tester.pumpAndSettle();
    expect(flow.startCalls, 1);
  });

  testWidgets('PROPERTY_NOT_AVAILABLE replaces the summary body', (
    tester,
  ) async {
    final listings = FakeListingsRepository()
      ..propertyResponses.add(_property(property1f, 'mock-terms-1'))
      ..unavailableNightsResponses.add(<DateOnly>{});
    flow.nextStartFailure = AppFailure(
      ErrorMapper.fromCode('PROPERTY_NOT_AVAILABLE'),
    );
    await pumpSummary(tester, listings: listings);

    await tester.tap(find.byKey(const ValueKey('summary-pay')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.propertyNotAvailable), findsOneWidget);
    expect(find.text(l10n.bookingsFindApartment), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('RATE_LIMITED snacks and disables pay until retry-after', (
    tester,
  ) async {
    final listings = FakeListingsRepository()
      ..propertyResponses.add(_property(property1f, 'mock-terms-1'))
      ..unavailableNightsResponses.add(<DateOnly>{});
    flow.nextStartFailure = const AppFailure(
      ApiError(
        code: ErrorCode.rateLimited,
        messageKey: 'authRateLimited',
        retryAfter: Duration(seconds: 3),
      ),
    );
    await pumpSummary(tester, listings: listings);

    await tester.tap(find.byKey(const ValueKey('summary-pay')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    final pay = tester.widget<OnAirPrimaryButton>(
      find.byKey(const ValueKey('summary-pay')),
    );
    expect(pay.onPressed, isNull);

    // The retry-after passes: the pay button comes back on its own.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    final payAgain = tester.widget<OnAirPrimaryButton>(
      find.byKey(const ValueKey('summary-pay')),
    );
    expect(payAgain.onPressed, isNotNull);
  });
}
