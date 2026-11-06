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
import 'package:on_air/features/stay/data/action_attempt_store.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/presentation/cash/cash_confirm_cubit.dart';
import 'package:on_air/features/stay/presentation/cash/cash_confirm_screen.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_cubit.dart';
import 'package:on_air/features/stay/presentation/cash/cash_receipt_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

const _booking20 = 'b0000000-0000-4000-8000-000000000020';
const _booking22 = 'b0000000-0000-4000-8000-000000000022';
const _booking28 = 'b0000000-0000-4000-8000-000000000028';
const _payment22 = 'c0000000-0000-4000-8000-000000000222';

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

/// One clock for the cubit and the resend countdown: the golden always
/// shows the full 30-second wait, whatever the machine's speed.
DateTime _fixedNow() => DateTime.utc(2026, 11, 1, 10);

Widget _confirmChild({
  required String bookingId,
  Future<void> Function(FakeBookingBackend backend)? beforeLoad,
  Future<void> Function(CashConfirmCubit cubit)? afterLoad,
}) {
  final backend = FakeBookingBackend(
    includeG3Fixtures: true,
    actionRegistry: BookingActionRegistry.g3(),
  );
  final connectivity = FakeConnectivity();
  final connectivityCubit = connectivity.createCubit();
  final cubit = CashConfirmCubit(
    bookings: backend.server,
    stay: backend.stay,
    attempts: backend.actionAttempts,
    registry: BookingActionRegistry.g3(),
    connectivity: connectivityCubit,
    logger: AppLogger(sink: (_) {}),
    bookingId: bookingId,
    now: _fixedNow,
  );
  unawaited(() async {
    await beforeLoad?.call(backend);
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
      RepositoryProvider<BookingsCache>.value(value: backend.cache),
      RepositoryProvider<BookingActionRegistry>.value(
        value: BookingActionRegistry.g3(),
      ),
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ],
    child: BlocProvider<CashConfirmCubit>.value(
      value: cubit,
      child: CashConfirmScreen(bookingId: bookingId, now: _fixedNow),
    ),
  );
}

Widget _receiptChild() {
  final backend = FakeBookingBackend(
    includeG3Fixtures: true,
    actionRegistry: BookingActionRegistry.g3(),
  );
  final connectivity = FakeConnectivity();
  final connectivityCubit = connectivity.createCubit();
  final cubit = CashReceiptCubit(
    bookings: backend.server,
    cache: backend.cache,
    connectivity: connectivityCubit,
    bookingId: _booking22,
    paymentId: _payment22,
  );
  unawaited(cubit.load());
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BookingsRepository>.value(value: backend.server),
      RepositoryProvider<BookingsCache>.value(value: backend.cache),
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ],
    child: BlocProvider<CashReceiptCubit>.value(
      value: cubit,
      child: const CashReceiptScreen(
        bookingId: _booking22,
        paymentId: _payment22,
      ),
    ),
  );
}

Future<void> _pumpUntilSettled(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
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
          (_) async =>
              Directory.systemTemp.createTempSync('on_air_cash_goldens').path,
        );
  });

  final modes = [
    ('light_RTL', ThemeMode.light, 1.0),
    ('dark_RTL', ThemeMode.dark, 1.0),
    ('light_RTL_1_3x', ThemeMode.light, 1.3),
    ('dark_RTL_1_3x', ThemeMode.dark, 1.3),
  ];

  final scenarios = <String, Widget Function()>{
    'phone': () => _confirmChild(bookingId: _booking20),
    'not_authorized': () => _confirmChild(
      bookingId: _booking20,
      afterLoad: (cubit) => cubit.submitPhone('01099999999'),
    ),
    'code': () => _confirmChild(
      bookingId: _booking28,
      beforeLoad: (backend) async {
        final all = await backend.server.bookings;
        final pending = Map<String, dynamic>.from(
          all[_booking28]!['pending_cash'] as Map,
        );
        pending['retry_after_seconds'] = 30;
        all[_booking28]!['pending_cash'] = pending;
      },
    ),
    'receipt': _receiptChild,
  };

  for (final (name, mode, scale) in modes) {
    for (final scenario in scenarios.entries) {
      unawaited(
        goldenTest(
          'cash ${scenario.key} — $name',
          fileName: 'cash_${scenario.key}_$name',
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
  unawaited(
    goldenTest(
      'cash phone — light_LTR_en',
      fileName: 'cash_phone_light_LTR_en',
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1200),
      pumpBeforeTest: _pumpUntilSettled,
      builder: () => GoldenTestScenario(
        name: 'light_LTR_en',
        child: _theme(
          ThemeMode.light,
          1,
          400,
          1100,
          _confirmChild(
            bookingId: _booking20,
          ),
          locale: const Locale('en'),
          direction: TextDirection.ltr,
        ),
      ),
    ),
  );
  unawaited(
    goldenTest(
      'cash not_authorized — light_LTR_en',
      fileName: 'cash_not_authorized_light_LTR_en',
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1200),
      pumpBeforeTest: _pumpUntilSettled,
      builder: () => GoldenTestScenario(
        name: 'light_LTR_en',
        child: _theme(
          ThemeMode.light,
          1,
          400,
          1100,
          _confirmChild(
            bookingId: _booking20,
            afterLoad: (cubit) => cubit.submitPhone('01099999999'),
          ),
          locale: const Locale('en'),
          direction: TextDirection.ltr,
        ),
      ),
    ),
  );
  unawaited(
    goldenTest(
      'cash code — light_LTR_en',
      fileName: 'cash_code_light_LTR_en',
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1200),
      pumpBeforeTest: _pumpUntilSettled,
      builder: () => GoldenTestScenario(
        name: 'light_LTR_en',
        child: _theme(
          ThemeMode.light,
          1,
          400,
          1100,
          _confirmChild(
            bookingId: _booking28,
            beforeLoad: (backend) async {
              final all = await backend.server.bookings;
              final pending = Map<String, dynamic>.from(
                all[_booking28]!['pending_cash'] as Map,
              );
              pending['retry_after_seconds'] = 30;
              all[_booking28]!['pending_cash'] = pending;
            },
          ),
          locale: const Locale('en'),
          direction: TextDirection.ltr,
        ),
      ),
    ),
  );
  unawaited(
    goldenTest(
      'cash receipt — light_LTR_en',
      fileName: 'cash_receipt_light_LTR_en',
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1200),
      pumpBeforeTest: _pumpUntilSettled,
      builder: () => GoldenTestScenario(
        name: 'light_LTR_en',
        child: _theme(
          ThemeMode.light,
          1,
          400,
          1100,
          _receiptChild(),
          locale: const Locale('en'),
          direction: TextDirection.ltr,
        ),
      ),
    ),
  );
}
