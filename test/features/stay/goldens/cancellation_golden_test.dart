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
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/presentation/cancellation/cancellation_cubit.dart';
import 'package:on_air/features/stay/presentation/cancellation/cancellation_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

const _booking21 = 'b0000000-0000-4000-8000-000000000021';
const _booking23 = 'b0000000-0000-4000-8000-000000000023';
const _booking24 = 'b0000000-0000-4000-8000-000000000024';

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

Widget _cancellationChild(
  String bookingId, {
  Future<void> Function(CancellationCubit cubit, FakeBookingBackend backend)?
  afterLoad,
}) {
  final backend = FakeBookingBackend(
    includeG3Fixtures: true,
    actionRegistry: BookingActionRegistry.g3(),
  );
  final connectivity = FakeConnectivity();
  final connectivityCubit = connectivity.createCubit();
  final cubit = CancellationCubit(
    stay: backend.stay,
    attempts: backend.actionAttempts,
    connectivity: connectivityCubit,
    logger: AppLogger(sink: (_) {}),
    bookingId: bookingId,
  );
  unawaited(() async {
    await cubit.load();
    await afterLoad?.call(cubit, backend);
  }());
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<StayRepository>.value(value: backend.stay),
      RepositoryProvider<ActionAttemptStore>.value(
        value: backend.actionAttempts,
      ),
      RepositoryProvider<BookingActionRegistry>.value(
        value: BookingActionRegistry.g3(),
      ),
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ],
    child: BlocProvider<CancellationCubit>.value(
      value: cubit,
      child: CancellationScreen(bookingId: bookingId),
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
          (_) async => Directory.systemTemp
              .createTempSync('on_air_cancellation_goldens')
              .path,
        );
  });

  final modes = [
    ('light_RTL', ThemeMode.light, 1.0),
    ('dark_RTL', ThemeMode.dark, 1.0),
    ('light_RTL_1_3x', ThemeMode.light, 1.3),
    ('dark_RTL_1_3x', ThemeMode.dark, 1.3),
  ];

  final scenarios = <String, Widget Function()>{
    'free': () => _cancellationChild(_booking23),
    'deposit_lost': () => _cancellationChild(_booking21),
    'no_refund': () => _cancellationChild(_booking24),
    'changed': () => _cancellationChild(
      _booking21,
      afterLoad: (cubit, backend) async {
        backend.stay.forceTermsChangeOnce(_booking21);
        await cubit.submit();
      },
    ),
  };

  for (final (name, mode, scale) in modes) {
    for (final scenario in scenarios.entries) {
      unawaited(
        goldenTest(
          'cancellation ${scenario.key} — $name',
          fileName: 'cancellation_${scenario.key}_$name',
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1200),
          pumpBeforeTest: _pumpUntilSettled,
          builder: () => GoldenTestScenario(
            name: name,
            child: _theme(mode, scale, 400, 1100, scenario.value()),
          ),
        ),
      );
    }
  }

  for (final width in [320.0, 800.0]) {
    unawaited(
      goldenTest(
        'cancellation deposit lost — light RTL w${width.toInt()}',
        fileName: 'cancellation_deposit_lost_light_RTL_w${width.toInt()}',
        constraints: BoxConstraints(maxWidth: width + 20, maxHeight: 1300),
        pumpBeforeTest: _pumpUntilSettled,
        builder: () => GoldenTestScenario(
          name: 'w${width.toInt()}',
          child: _theme(
            ThemeMode.light,
            1,
            width,
            1200,
            _cancellationChild(_booking21),
          ),
        ),
      ),
    );
  }
}
