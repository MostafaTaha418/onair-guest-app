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
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/presentation/stay_ack/stay_ack_cubit.dart';
import 'package:on_air/features/stay/presentation/stay_ack/stay_ack_sheets.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

const _booking21 = 'b0000000-0000-4000-8000-000000000021';
const _booking22 = 'b0000000-0000-4000-8000-000000000022';

Widget _theme(
  ThemeMode mode,
  double scale,
  double width,
  double height,
  Widget child, {
  Locale locale = const Locale('ar'),
  TextDirection direction = TextDirection.rtl,
}) => SizedBox(
  width: width,
  height: height,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
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
      child: Directionality(textDirection: direction, child: child!),
    ),
    home: child,
  ),
);

/// The details child with an optional mutation applied before the first
/// load, so the golden shows the exact post-mutation server state.
Widget _detailsChild({
  required String bookingId,
  Future<void> Function(FakeBookingBackend backend)? mutate,
  Widget? instead,
}) {
  final backend = FakeBookingBackend(
    includeG3Fixtures: true,
    actionRegistry: BookingActionRegistry.g3(),
  );
  final connectivity = FakeConnectivity();
  final connectivityCubit = connectivity.createCubit();
  if (instead != null) {
    unawaited(mutate?.call(backend));
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BookingsRepository>.value(value: backend.server),
        RepositoryProvider<StayRepository>.value(value: backend.stay),
        RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
        RepositoryProvider<BookingsCache>.value(value: backend.cache),
        RepositoryProvider<BookingActionRegistry>.value(
          value: BookingActionRegistry.g3(),
        ),
        RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
      ],
      child: instead,
    );
  }
  final cubit = BookingDetailsCubit(
    bookings: backend.server,
    cache: backend.cache,
    arrival: backend.arrivalInstructions,
    signals: backend.signals,
    connectivity: connectivityCubit,
    bookingId: bookingId,
  );
  unawaited(() async {
    await mutate?.call(backend);
    await cubit.load();
  }());
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BookingsRepository>.value(value: backend.server),
      RepositoryProvider<StayRepository>.value(value: backend.stay),
      RepositoryProvider<AppLogger>.value(value: AppLogger(sink: (_) {})),
      RepositoryProvider<BookingsCache>.value(value: backend.cache),
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

/// Renders the check-in sheet body directly inside the sheet shape. The sheet
/// opens on the root navigator, which a golden's isolated harness cannot host,
/// so — like the account sheet goldens — the body is pumped on its own rather
/// than through [showCheckInSheet].
Widget _checkinSheet() {
  final backend = FakeBookingBackend(
    includeG3Fixtures: true,
    actionRegistry: BookingActionRegistry.g3(),
  );
  return Builder(
    builder: (context) => Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: context.colors.surface,
          borderRadius: const BorderRadiusDirectional.vertical(
            top: Radius.circular(Dimens.radiusSheet),
          ),
          clipBehavior: Clip.antiAlias,
          child: BlocProvider<StayAckCubit>(
            create: (_) => StayAckCubit(
              stay: backend.stay,
              logger: AppLogger(sink: (_) {}),
              bookingId: _booking21,
            ),
            child: const AckSheetBody(checkIn: true, bookingId: _booking21),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpUntilSettled(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 1, milliseconds: 100));
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
              .createTempSync('on_air_stay_ack_goldens')
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
    'checkin_sheet': _checkinSheet,
    'waiting_handover': () => _detailsChild(
      bookingId: _booking21,
      mutate: (backend) => backend.stay.confirmCheckIn(_booking21),
    ),
    'checkout_tracker': () => _detailsChild(
      bookingId: _booking22,
      mutate: (backend) =>
          backend.stay.ownerConfirmsCheckout(_booking22, keyLeftSafe: true),
    ),
  };

  for (final (name, mode, scale) in modes) {
    for (final scenario in scenarios.entries) {
      unawaited(
        goldenTest(
          'stay ack ${scenario.key} — $name',
          fileName: 'stay_ack_${scenario.key}_$name',
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: scenario.key == 'checkin_sheet' ? 1200 : 2900,
          ),
          pumpBeforeTest: _pumpUntilSettled,
          builder: () => GoldenTestScenario(
            name: name,
            child: _theme(
              mode,
              scale,
              400,
              scenario.key == 'checkin_sheet' ? 1100 : 2800,
              scenario.value(),
            ),
          ),
        ),
      );
    }
  }
  for (final scenario in scenarios.entries) {
    final isSheet = scenario.key == 'checkin_sheet';
    unawaited(
      goldenTest(
        'stay ack ${scenario.key} — light_LTR_en',
        fileName: 'stay_ack_${scenario.key}_light_LTR_en',
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: isSheet ? 1200 : 2900,
        ),
        pumpBeforeTest: _pumpUntilSettled,
        builder: () => GoldenTestScenario(
          name: 'light_LTR_en',
          child: _theme(
            ThemeMode.light,
            1,
            400,
            isSheet ? 1100 : 2800,
            scenario.value(),
            locale: const Locale('en'),
            direction: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
