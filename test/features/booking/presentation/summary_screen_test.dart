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
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
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

PropertyDetails _property(String id, DepositType depositType) =>
    PropertyDetails(
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
      policy: PolicySummary(
        depositType: depositType,
        depositPercentBp: depositType == DepositType.percent ? 2500 : null,
        depositAmount: null,
        freeCancellationHours: 72,
      ),
      nightlyPrice: Money(depositType == DepositType.full ? 220000 : 150000),
      ratingAvg: null,
      reviewCount: 0,
      latestReviews: const [],
      termsVersion: 'mock-terms-1',
    );

/// Delegates to the mock server but holds the next start response so the
/// test can see the in-button loader.
final class HoldingFlow implements BookingFlowRepository {
  HoldingFlow(this._inner);

  final BookingFlowRepository _inner;
  Completer<PaymentSessionInfo>? holdStart;

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) {
    final hold = holdStart;
    if (hold != null) return hold.future;
    return _inner.startPayment(
      quoteId: quoteId,
      termsHash: termsHash,
      attemptKey: attemptKey,
    );
  }

  @override
  Future<VerificationStatus> verificationStatus() =>
      _inner.verificationStatus();

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

void main() {
  const property1f = '00000000-0000-4000-8000-00000000001f';
  const property21 = '00000000-0000-4000-8000-000000000021';

  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late FakeInAppBrowser browser;
  late PaymentAttemptCubit attemptCubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    CairoTime.initialize();
  });

  late HoldingFlow flow;

  setUp(() {
    backend = FakeBookingBackend();
    connectivity = FakeConnectivity();
    browser = FakeInAppBrowser();
    flow = HoldingFlow(backend.server);
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

  Future<void> pumpSummary(
    WidgetTester tester, {
    required String propertyId,
    required FakeListingsRepository listings,
  }) async {
    tester.view.physicalSize = const Size(400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.bookingSummary(propertyId),
      routes: [
        GoRoute(
          path: AppRoutes.bookingEntryPattern,
          builder: (context, state) => BlocProvider<BookingFlowCubit>(
            create: (context) {
              final cubit = BookingFlowCubit(
                listings: listings,
                flow: backend.server,
                connectivity: context.read<ConnectivityCubit>(),
                propertyId: propertyId,
                termsHash: 'mock-terms-1',
                initialStay: StayRange(
                  CairoTime.today().addDays(20),
                  CairoTime.today().addDays(23),
                ),
                initialGuests: 2,
              );
              unawaited(cubit.load());
              return cubit;
            },
            child: const Text('dates-stub'),
          ),
        ),
        GoRoute(
          path: AppRoutes.bookingSummaryPattern,
          builder: (context, state) => BlocProvider<PaymentAttemptCubit>.value(
            value: attemptCubit,
            child: BlocProvider<BookingFlowCubit>(
              create: (context) {
                final cubit = BookingFlowCubit(
                  listings: listings,
                  flow: backend.server,
                  connectivity: context.read<ConnectivityCubit>(),
                  propertyId: propertyId,
                  termsHash: 'mock-terms-1',
                  initialStay: StayRange(
                    CairoTime.today().addDays(20),
                    CairoTime.today().addDays(23),
                  ),
                  initialGuests: 2,
                );
                unawaited(() async {
                  await cubit.load();
                  await cubit.requestQuote();
                }());
                return cubit;
              },
              child: SummaryScreen(propertyId: propertyId),
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
  }

  testWidgets('a deposit quote shows every amount from the server', (
    tester,
  ) async {
    final listings = FakeListingsRepository();
    listings.propertyResponses.add(_property(property1f, DepositType.percent));
    listings.unavailableNightsResponses.add(<DateOnly>{});
    await pumpSummary(tester, propertyId: property1f, listings: listings);

    expect(find.text(l10n.bookingNightsCount('3')), findsOneWidget);
    expect(find.text('EGP 1,500.00'), findsOneWidget);
    expect(find.text('EGP 4,500.00'), findsOneWidget);
    expect(find.text('EGP 1,125.00'), findsOneWidget);
    expect(find.text('EGP 3,375.00'), findsOneWidget);
    expect(find.text(l10n.bookingSummaryOwnerNotice), findsOneWidget);
  });

  testWidgets('a full-payment quote has no remaining row', (tester) async {
    final listings = FakeListingsRepository();
    listings.propertyResponses.add(_property(property21, DepositType.full));
    listings.unavailableNightsResponses.add(<DateOnly>{});
    await pumpSummary(tester, propertyId: property21, listings: listings);

    // Total and due-now are the same amount for a full-payment quote.
    expect(find.text('EGP 6,600.00'), findsNWidgets(2));
    expect(find.text(l10n.bookingRemaining), findsNothing);
    expect(find.text('EGP 0.00'), findsNothing);
  });

  testWidgets('go to payment disables at once and opens the page once', (
    tester,
  ) async {
    final listings = FakeListingsRepository();
    listings.propertyResponses.add(_property(property1f, DepositType.percent));
    listings.unavailableNightsResponses.add(<DateOnly>{});
    await pumpSummary(tester, propertyId: property1f, listings: listings);

    flow.holdStart = Completer<PaymentSessionInfo>();
    await tester.tap(find.byKey(const ValueKey('summary-pay')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-pay')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    flow.holdStart!.complete(
      PaymentSessionInfo(
        bookingId: 'b0000000-0000-4000-8000-000000000099',
        paymentId: 'p99',
        paymentUrl: Uri.parse(
          'https://pay.mock.onair.test/session/'
          'b0000000-0000-4000-8000-000000000099',
        ),
        paymentUrlExpiresAt: DateTime.utc(2026, 11, 1, 10, 30),
      ),
    );
    await tester.pumpAndSettle();
    expect(browser.opened, hasLength(1));
    expect(
      browser.opened.single.url.toString(),
      startsWith('https://pay.mock.onair.test/session/'),
    );
  });
}
