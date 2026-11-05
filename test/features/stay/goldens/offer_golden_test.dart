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
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

const _booking26 = 'b0000000-0000-4000-8000-000000000026';
const _booking27 = 'b0000000-0000-4000-8000-000000000027';

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

Widget _detailsChild(String bookingId) {
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
    bookingId: bookingId,
  );
  unawaited(cubit.load());
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
      RepositoryProvider<BookingsRepository>.value(value: backend.server),
      RepositoryProvider<StayRepository>.value(value: backend.stay),
      RepositoryProvider<ActionAttemptStore>.value(
        value: backend.actionAttempts,
      ),
      RepositoryProvider<BookingActionRegistry>.value(
        value: BookingActionRegistry.g3(),
      ),
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ],
    child: BlocProvider<BookingDetailsCubit>.value(
      value: cubit,
      child: BookingDetailsScreen(bookingId: bookingId),
    ),
  );
}

Future<void> _pumpUntilSettled(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps the details and then opens the accept dialog, for the dialog
/// golden.
Future<void> _pumpWithDialog(WidgetTester tester) async {
  await _pumpUntilSettled(tester);
  await tester.tap(find.byKey(const ValueKey('offer-accept')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    CairoTime.initialize();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              Directory.systemTemp.createTempSync('on_air_offer_goldens').path,
        );
  });

  final modes = [
    ('light_RTL', ThemeMode.light, 1.0),
    ('dark_RTL', ThemeMode.dark, 1.0),
    ('light_RTL_1_3x', ThemeMode.light, 1.3),
    ('dark_RTL_1_3x', ThemeMode.dark, 1.3),
  ];

  final scenarios = <String, (String, Future<void> Function(WidgetTester)?)>{
    'offer_pending': (_booking26, null),
    'offer_expired': (_booking27, null),
    'offer_accept_dialog': (_booking26, _pumpWithDialog),
  };

  for (final (name, mode, scale) in modes) {
    for (final scenario in scenarios.entries) {
      final (bookingId, before) = scenario.value;
      unawaited(
        goldenTest(
          'offer ${scenario.key} — $name',
          fileName: '${scenario.key}_$name',
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 2900),
          pumpBeforeTest: before ?? _pumpUntilSettled,
          builder: () => GoldenTestScenario(
            name: name,
            child: _theme(
              mode,
              scale,
              400,
              2800,
              _detailsChild(bookingId),
            ),
          ),
        ),
      );
    }
  }
}
