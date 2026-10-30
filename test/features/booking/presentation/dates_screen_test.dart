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
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/presentation/booking_flow_cubit.dart';
import 'package:on_air/features/booking/presentation/dates_screen.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_app_config_repository.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_listings_repository.dart';
import '../../../helpers/pump_app.dart';

PropertyDetails _property1f() => PropertyDetails(
  id: '00000000-0000-4000-8000-00000000001f',
  title: 'شقة 3 غرف للتجربة',
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
  termsVersion: 'mock-terms-1',
);

final class FlakyFlow implements BookingFlowRepository {
  FlakyFlow(this._inner);

  final BookingFlowRepository _inner;
  String? nextQuoteError;

  /// When set, quote() waits on it: lets the test see the in-button loader.
  Completer<BookingQuote>? holdQuote;

  @override
  Future<VerificationStatus> verificationStatus() =>
      _inner.verificationStatus();

  @override
  Future<BookingQuote> quote({
    required String propertyId,
    required StayRange stay,
    required int guests,
    required String termsHash,
  }) async {
    final error = nextQuoteError;
    if (error != null) {
      throw AppFailure(ErrorMapper.fromCode(error));
    }
    final hold = holdQuote;
    if (hold != null) {
      return hold.future;
    }
    return _inner.quote(
      propertyId: propertyId,
      stay: stay,
      guests: guests,
      termsHash: termsHash,
    );
  }

  @override
  Future<PaymentSessionInfo> startPayment({
    required String quoteId,
    required String termsHash,
    required String attemptKey,
  }) => _inner.startPayment(
    quoteId: quoteId,
    termsHash: termsHash,
    attemptKey: attemptKey,
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

  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late FakeListingsRepository listings;
  late FlakyFlow flow;
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    CairoTime.initialize();
  });

  setUp(() {
    backend = FakeBookingBackend();
    connectivity = FakeConnectivity();
    listings = FakeListingsRepository();
    flow = FlakyFlow(backend.server);
  });

  tearDown(() {
    backend.dispose();
    connectivity.dispose();
  });

  Future<void> pumpDates(
    WidgetTester tester, {
    Map<String, String> query = const {},
    double height = 2200,
  }) async {
    tester.view.physicalSize = Size(400, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Uri(
        path: AppRoutes.bookingEntry(property1f),
        queryParameters: query.isEmpty ? null : query,
      ).toString(),
      routes: [
        GoRoute(
          path: AppRoutes.bookingEntryPattern,
          builder: (context, state) => BlocProvider<BookingFlowCubit>(
            create: (context) {
              final q = state.uri.queryParameters;
              final cubit = BookingFlowCubit(
                listings: listings,
                flow: flow,
                connectivity: context.read<ConnectivityCubit>(),
                propertyId: property1f,
                termsHash: q['terms'] ?? 'mock-terms-1',
                initialStay: StayRange.tryCreate(
                  DateOnly.tryParse(q['checkIn']),
                  DateOnly.tryParse(q['checkOut']),
                  CairoTime.today(),
                ),
                initialGuests: int.tryParse(q['guests'] ?? ''),
              );
              unawaited(cubit.load());
              return cubit;
            },
            child: const DatesScreen(propertyId: property1f),
          ),
        ),
        GoRoute(
          path: AppRoutes.bookingSummaryPattern,
          builder: (_, _) => const Text('summary-stub'),
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

  DateOnly day(int offset) => CairoTime.today().addDays(offset);

  /// The calendar shows one month; walk forward until [day] is visible.
  Future<void> ensureMonthVisible(WidgetTester tester, DateOnly day) async {
    var guard = 0;
    while (find.text(DateOnlyFormatter.monthYear(day)).evaluate().isEmpty) {
      if (guard++ > 24) {
        fail('the calendar never reached ${DateOnlyFormatter.monthYear(day)}');
      }
      await tester.tap(find.byTooltip(l10n.calendarNextMonth));
      await tester.pumpAndSettle();
    }
  }

  Future<void> pickRange(WidgetTester tester, int from, int to) async {
    await ensureMonthVisible(tester, day(from));
    await tester.tap(find.text('${day(from).day}').last);
    await tester.pump();
    await ensureMonthVisible(tester, day(to));
    await tester.tap(find.text('${day(to).day}').last);
    await tester.pumpAndSettle();
  }

  testWidgets('unavailable days are refused with a notice', (tester) async {
    listings.propertyResponses.add(_property1f());
    listings.unavailableNightsResponses.add({day(21)});
    await pumpDates(tester);

    await pickRange(tester, 20, 23);
    expect(find.text(l10n.bookingRangeHasUnavailable), findsOneWidget);
    expect(
      tester
          .widget<OnAirPrimaryButton>(
            find.byKey(const ValueKey('dates-continue')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('continue is disabled until a valid range is picked', (
    tester,
  ) async {
    listings.propertyResponses.add(_property1f());
    listings.unavailableNightsResponses.add(<DateOnly>{});
    await pumpDates(tester);

    final finder = find.byKey(const ValueKey('dates-continue'));
    expect(
      tester.widget<OnAirPrimaryButton>(finder).onPressed,
      isNull,
    );

    await pickRange(tester, 20, 23);
    expect(
      tester.widget<OnAirPrimaryButton>(finder).onPressed,
      isNotNull,
    );
    expect(find.text(l10n.bookingNightsCount('3')), findsOneWidget);
  });

  testWidgets('continue quotes and navigates to the summary', (tester) async {
    listings.propertyResponses.add(_property1f());
    listings.unavailableNightsResponses.add(<DateOnly>{});
    await pumpDates(tester);

    await pickRange(tester, 20, 23);
    flow.holdQuote = Completer<BookingQuote>();
    await tester.tap(find.byKey(const ValueKey('dates-continue')));
    await tester.pump();
    // The in-button loader shows while quoting.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dates-continue')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    flow.holdQuote!.complete(
      await backend.server.quote(
        propertyId: property1f,
        stay: StayRange(day(20), day(23)),
        guests: 2,
        termsHash: 'mock-terms-1',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('summary-stub'), findsOneWidget);
  });

  testWidgets('a refused quote shows the message on the same screen', (
    tester,
  ) async {
    listings.propertyResponses.add(_property1f());
    listings.unavailableNightsResponses.add(<DateOnly>{});
    flow.nextQuoteError = 'DATES_UNAVAILABLE';
    await pumpDates(tester);

    await pickRange(tester, 20, 23);
    await tester.tap(find.byKey(const ValueKey('dates-continue')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.bookingDatesUnavailable), findsOneWidget);
    expect(find.text('summary-stub'), findsNothing);
  });

  testWidgets('offline disables continue', (tester) async {
    listings.propertyResponses.add(_property1f());
    listings.unavailableNightsResponses.add(<DateOnly>{});
    await pumpDates(tester);
    connectivity.goOffline();
    await tester.pumpAndSettle();

    await pickRange(tester, 20, 23);
    expect(
      tester
          .widget<OnAirPrimaryButton>(
            find.byKey(const ValueKey('dates-continue')),
          )
          .onPressed,
      isNull,
    );
  });
}
