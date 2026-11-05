@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/stay/presentation/remaining_payment/remaining_payment_cubit.dart';
import 'package:on_air/features/stay/presentation/remaining_payment/remaining_payment_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';
import '../../../helpers/fake_in_app_browser.dart';

const _bookingId = 'b0000000-0000-4000-8000-000000000020';

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

Widget _remainingChild() {
  final backend = FakeBookingBackend(
    includeG3Fixtures: true,
    actionRegistry: BookingActionRegistry.g3(),
  );
  final connectivity = FakeConnectivity();
  final connectivityCubit = connectivity.createCubit();
  final browser = FakeInAppBrowser();
  final remaining = RemainingPaymentCubit(
    bookings: backend.server,
    registry: BookingActionRegistry.g3(),
    connectivity: connectivityCubit,
    bookingId: _bookingId,
  );
  unawaited(remaining.load());
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BookingsRepository>.value(value: backend.server),
      RepositoryProvider<BookingActionRegistry>.value(
        value: BookingActionRegistry.g3(),
      ),
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<RemainingPaymentCubit>.value(value: remaining),
        BlocProvider<PaymentAttemptCubit>(
          create: (_) => PaymentAttemptCubit(
            flow: backend.server,
            store: backend.paymentAttempts,
            browser: () => browser,
            logger: AppLogger(sink: (_) {}),
          ),
        ),
      ],
      child: const RemainingPaymentScreen(bookingId: _bookingId),
    ),
  );
}

Widget _detailsChild() {
  final backend = FakeBookingBackend(
    includeG3Fixtures: true,
    actionRegistry: BookingActionRegistry.g3(),
  );
  final connectivity = FakeConnectivity();
  final connectivityCubit = connectivity.createCubit();
  final cubit = BookingDetailsCubit(
    bookings: backend.server,
    cache: backend.cache,
    arrival: backend.arrivalInstructions,
    signals: backend.signals,
    connectivity: connectivityCubit,
    bookingId: _bookingId,
  );
  unawaited(cubit.load());
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BookingsRepository>.value(value: backend.server),
      RepositoryProvider<BookingsCache>.value(value: backend.cache),
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
      RepositoryProvider<BookingActionRegistry>.value(
        value: BookingActionRegistry.g3(),
      ),
    ],
    child: BlocProvider<BookingDetailsCubit>.value(
      value: cubit,
      child: const BookingDetailsScreen(bookingId: _bookingId),
    ),
  );
}

Future<void> _pumpTwoFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    CairoTime.initialize();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp
              .createTempSync('on_air_remaining_goldens')
              .path,
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
        'remaining payment — $name',
        fileName: 'remaining_payment_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1200),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, scale, 400, 1100, _remainingChild()),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'booking details deposit — $name',
        fileName: 'booking_details_deposit_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 2900),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, scale, 400, 2800, _detailsChild()),
        ),
      ),
    );
  }

  for (final width in [320.0, 800.0]) {
    unawaited(
      goldenTest(
        'remaining payment — light RTL w${width.toInt()}',
        fileName: 'remaining_payment_light_RTL_w${width.toInt()}',
        constraints: BoxConstraints(
          maxWidth: width + 20,
          maxHeight: 1300,
        ),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: 'w${width.toInt()}',
          child: _theme(
            ThemeMode.light,
            1,
            width,
            1200,
            _remainingChild(),
          ),
        ),
      ),
    );
  }
}
