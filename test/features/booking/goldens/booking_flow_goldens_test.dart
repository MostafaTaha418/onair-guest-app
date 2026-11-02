@Tags(['golden'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/domain/quote_change.dart';
import 'package:on_air/features/booking/domain/verification_outcome.dart';
import 'package:on_air/features/booking/presentation/booking_flow_cubit.dart';
import 'package:on_air/features/booking/presentation/dates_screen.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/booking/presentation/payment_return_screen.dart';
import 'package:on_air/features/booking/presentation/payment_verification_cubit.dart';
import 'package:on_air/features/booking/presentation/summary_screen.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_in_app_browser.dart';
import '../../../helpers/fake_listings_repository.dart';

const _property1f = '00000000-0000-4000-8000-00000000001f';
const _confirmedId = 'b0000000-0000-4000-8000-000000000001';
const _conflictId = 'b0000000-0000-4000-8000-000000000010';

Widget _theme(
  ThemeMode mode,
  double scale,
  double width,
  double height,
  Widget child,
) => SizedBox(
  width: width,
  height: height,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: mode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: true,
      ),
      child: Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
    home: child,
  ),
);

PropertyDetails _property1fDetails() => PropertyDetails(
  id: _property1f,
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

/// A fixed stay far enough out that the rendered calendar never rolls over
/// with the real midnight (a relative range would shift the pixels daily).
final StayRange _threeNights = StayRange(
  DateOnly(2027, 3, 20),
  DateOnly(2027, 3, 23),
);

/// A deterministic fixture read: goldens never await the server.
BookingDetails _detailsFromFixture(String id) {
  final raw = File(
    'lib/features/bookings/data/fixtures/bookings.json',
  ).readAsStringSync();
  final all = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return BookingDetails.fromJson(
    Map<String, dynamic>.from(all.firstWhere((entry) => entry['id'] == id)),
  );
}

/// The dates step with the range already picked.
Widget _datesChild() {
  final backend = FakeBookingBackend();
  final connectivityCubit = FakeConnectivity().createCubit();
  final listings = FakeListingsRepository()
    ..propertyResponses.add(_property1fDetails())
    ..unavailableNightsResponses.add(<DateOnly>{});
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
      ...backend.appProviders(),
    ],
    child: BlocProvider<BookingFlowCubit>(
      create: (context) {
        final cubit = BookingFlowCubit(
          listings: listings,
          flow: backend.server,
          connectivity: connectivityCubit,
          propertyId: _property1f,
          termsHash: 'mock-terms-1',
          initialStay: _threeNights,
          initialGuests: 2,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: DatesScreen(
        propertyId: _property1f,
        // The committed CI baselines were generated on this Cairo day.
        today: DateOnly(2026, 11, 1),
      ),
    ),
  );
}

/// The summary over a deposit quote; [pendingChange] pins the re-price.
Widget _summaryChild({bool pendingChange = false}) {
  final backend = FakeBookingBackend();
  final connectivityCubit = FakeConnectivity().createCubit();
  final listings = FakeListingsRepository()
    ..propertyResponses.add(_property1fDetails())
    ..unavailableNightsResponses.add(<DateOnly>{});
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
      ...backend.appProviders(),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<PaymentAttemptCubit>(
          create: (context) => PaymentAttemptCubit(
            flow: backend.server,
            store: backend.paymentAttempts,
            browser: FakeInAppBrowser.new,
            logger: AppLogger(sink: (_) {}),
          ),
        ),
        BlocProvider<BookingFlowCubit>(
          create: (context) {
            final cubit = BookingFlowCubit(
              listings: listings,
              flow: backend.server,
              connectivity: connectivityCubit,
              propertyId: _property1f,
              termsHash: 'mock-terms-1',
              initialStay: _threeNights,
              initialGuests: 2,
            );
            unawaited(() async {
              await cubit.load();
              await cubit.requestQuote();
              if (pendingChange) {
                final quote = cubit.state.quote!;
                final changed = BookingQuote(
                  quoteId: 'quote-repriced',
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
                cubit.emit(
                  cubit.state.copyWith(
                    quote: changed,
                    pendingChange: QuoteChange.between(quote, changed),
                  ),
                );
              }
            }());
            return cubit;
          },
        ),
      ],
      child: const SummaryScreen(propertyId: _property1f),
    ),
  );
}

/// The payment-return screen pinned to one of the five verification states.
Widget _returnChild() {
  final backend = FakeBookingBackend();
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
      ...backend.appProviders(),
    ],
    child: BlocProvider<PaymentAttemptCubit>(
      create: (context) => PaymentAttemptCubit(
        flow: backend.server,
        store: backend.paymentAttempts,
        browser: FakeInAppBrowser.new,
        logger: AppLogger(sink: (_) {}),
      ),
      child: const PaymentReturnScreen(bookingIdFromLink: _confirmedId),
    ),
  );
}

/// Pins the return screen's cubit to [state] after the first frames; `null`
/// keeps whatever the screen itself resolved (the confirmed fixture).
Future<void> Function(WidgetTester) _pinReturn(VerifyState? state) =>
    (tester) async {
      await tester.pump();
      await tester.pump();
      if (state != null) {
        tester
            .element(find.byType(Scaffold))
            .read<PaymentVerificationCubit>()
            .emit(state);
      }
      await tester.pump();
      await tester.pump();
    };

Future<void> _pumpTwoFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    CairoTime.initialize();
    // CachedNetworkImage asks the platform for its cache directory before
    // failing over to the error box; give it a real temp directory.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async =>
              Directory.systemTemp.createTempSync('on_air_golden_images').path,
        );
  });

  final modes = [
    ('light_RTL', ThemeMode.light, 1.0),
    ('dark_RTL', ThemeMode.dark, 1.0),
    ('light_RTL_1_3x', ThemeMode.light, 1.3),
    ('dark_RTL_1_3x', ThemeMode.dark, 1.3),
  ];

  for (final (name, mode, scale) in modes) {
    unawaited(
      goldenTest(
        'dates with a picked range — $name',
        fileName: 'booking_dates_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1700),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, scale, 400, 1600, _datesChild()),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'summary deposit quote — $name',
        fileName: 'booking_summary_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1900),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, scale, 400, 1800, _summaryChild()),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'summary with a pending change — $name',
        fileName: 'booking_summary_pending_change_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1900),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(
            mode,
            scale,
            400,
            1800,
            _summaryChild(pendingChange: true),
          ),
        ),
      ),
    );
    final returnStates = <(String, VerifyState?)>[
      ('waiting', const VerifyWaiting()),
      ('success', null),
      (
        'failed',
        VerifyResolved(
          VerificationOutcome.failed,
          _detailsFromFixture(_confirmedId),
        ),
      ),
      (
        'conflict',
        VerifyResolved(
          VerificationOutcome.conflict,
          _detailsFromFixture(_conflictId),
        ),
      ),
      ('timeout', const VerifyTimeout(_confirmedId)),
    ];
    for (final (stateName, state) in returnStates) {
      unawaited(
        goldenTest(
          'payment return $stateName — $name',
          fileName: 'payment_return_${stateName}_$name',
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1100),
          pumpBeforeTest: _pinReturn(state),
          builder: () => GoldenTestScenario(
            name: name,
            child: _theme(mode, scale, 400, 1000, _returnChild()),
          ),
        ),
      );
    }
  }
}
