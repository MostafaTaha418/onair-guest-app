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
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_cubit.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

const _booking25 = 'b0000000-0000-4000-8000-000000000025';
const _claim1 = 'e0000000-0000-4000-8000-000000000001';
const _claim2 = 'e0000000-0000-4000-8000-000000000002';

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

Widget _claimChild(
  String claimId, {
  Future<void> Function(DamageClaimCubit cubit)? afterLoad,
}) {
  final backend = FakeBookingBackend(
    includeG3Fixtures: true,
    actionRegistry: BookingActionRegistry.g3(),
  );
  final connectivity = FakeConnectivity();
  final connectivityCubit = connectivity.createCubit();
  final cubit = DamageClaimCubit(
    stay: backend.stay,
    bookings: backend.server,
    attempts: backend.actionAttempts,
    registry: BookingActionRegistry.g3(),
    connectivity: connectivityCubit,
    logger: AppLogger(sink: (_) {}),
    bookingId: _booking25,
    claimId: claimId,
  );
  unawaited(() async {
    await cubit.load();
    await afterLoad?.call(cubit);
  }());
  return MultiRepositoryProvider(
    providers: [
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
    child: BlocProvider<DamageClaimCubit>.value(
      value: cubit,
      child: DamageClaimScreen(bookingId: _booking25, claimId: claimId),
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
    bookingId: _booking25,
  );
  unawaited(cubit.load());
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BookingsRepository>.value(value: backend.server),
      RepositoryProvider<BookingsCache>.value(value: backend.cache),
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
      child: const BookingDetailsScreen(bookingId: _booking25),
    ),
  );
}

Future<void> _pumpUntilSettled(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    CairoTime.initialize();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              Directory.systemTemp.createTempSync('on_air_claim_goldens').path,
        );
  });

  final modes = [
    ('light_RTL', ThemeMode.light, 1.0),
    ('dark_RTL', ThemeMode.dark, 1.0),
    ('light_RTL_1_3x', ThemeMode.light, 1.3),
    ('dark_RTL_1_3x', ThemeMode.dark, 1.3),
  ];

  final scenarios = <String, (Widget Function(), double)>{
    'damage_claim_open': (
      () => _claimChild(_claim1),
      1100,
    ),
    'damage_claim_dispute_form': (
      () => _claimChild(
        _claim1,
        afterLoad: (cubit) async {
          cubit.openDispute();
          await cubit.dispute('قصير');
        },
      ),
      1100,
    ),
    'damage_claim_resolved': (
      () => _claimChild(_claim2),
      1100,
    ),
    'booking_details_claims': (
      _detailsChild,
      2800,
    ),
  };

  for (final (name, mode, scale) in modes) {
    for (final scenario in scenarios.entries) {
      final (child, height) = scenario.value;
      unawaited(
        goldenTest(
          'claims ${scenario.key} — $name',
          fileName: '${scenario.key}_$name',
          constraints: BoxConstraints(maxWidth: 420, maxHeight: height + 100),
          pumpBeforeTest: _pumpUntilSettled,
          builder: () => GoldenTestScenario(
            name: name,
            child: _theme(mode, scale, 400, height, child()),
          ),
        ),
      );
    }
  }
}
