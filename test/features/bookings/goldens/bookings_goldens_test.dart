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
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/bookings/presentation/bookings_cubit.dart';
import 'package:on_air/features/bookings/presentation/bookings_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

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

/// The fixture awaiting-owner deadline is a fixed instant, so the card's
/// live countdown would render a different «H:MM» every day. The golden
/// drops deadlines; the countdown widget itself is covered by unit tests.
final class PinnedBookings implements BookingsRepository {
  PinnedBookings(this._inner);

  final BookingsRepository _inner;

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) async {
    final page = await _inner.listBookings(tab, cursor: cursor);
    return BookingsPage(
      items: [
        for (final booking in page.items)
          BookingSummary.fromJson({
            ...booking.toJson(),
            'owner_response_deadline': null,
          }),
      ],
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<BookingDetails> getBooking(String bookingId) =>
      _inner.getBooking(bookingId);
}

const _confirmedId = 'b0000000-0000-4000-8000-000000000001';
const _conflictId = 'b0000000-0000-4000-8000-000000000010';
const _cancelledId = 'b0000000-0000-4000-8000-000000000008';

Widget _bookingsChild() {
  final backend = FakeBookingBackend();
  final connectivity = FakeConnectivity();
  final connectivityCubit = connectivity.createCubit();
  final cubit = BookingsCubit(
    bookings: PinnedBookings(backend.server),
    cache: backend.cache,
    connectivity: connectivityCubit,
  );
  unawaited(cubit.start(BookingTab.current));
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BookingsRepository>.value(value: backend.server),
      RepositoryProvider<BookingsCache>.value(value: backend.cache),
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
    ],
    child: BlocProvider<BookingsCubit>.value(
      value: cubit,
      child: const BookingsScreen(),
    ),
  );
}

Widget _detailsChild([String bookingId = _confirmedId]) {
  final backend = FakeBookingBackend();
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
      RepositoryProvider<BookingsRepository>.value(value: backend.server),
      RepositoryProvider<BookingsCache>.value(value: backend.cache),
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
      RepositoryProvider<BookingActionRegistry>.value(
        value: BookingActionRegistry.g2(),
      ),
    ],
    child: BlocProvider<BookingDetailsCubit>.value(
      value: cubit,
      child: BookingDetailsScreen(bookingId: bookingId),
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
    // CachedNetworkImage asks the platform for its cache directory before
    // failing over to the error box; give it a real temp directory.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp
              .createTempSync(
                'on_air_golden_images',
              )
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
        'bookings current tab — $name',
        fileName: 'bookings_current_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1400),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, scale, 400, 1300, _bookingsChild()),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'booking details confirmed — $name',
        fileName: 'booking_details_confirmed_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 2900),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, scale, 400, 2800, _detailsChild()),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'booking details conflict — $name',
        fileName: 'booking_details_conflict_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 2900),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(
            mode,
            scale,
            400,
            2800,
            _detailsChild(_conflictId),
          ),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'booking details cancelled — $name',
        fileName: 'booking_details_cancelled_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 2900),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(
            mode,
            scale,
            400,
            2800,
            _detailsChild(_cancelledId),
          ),
        ),
      ),
    );
  }
}
