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
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_details_screen.dart';
import 'package:on_air/features/stay/domain/stay_repository.dart';
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

/// Opens the check-in sheet over an empty page.
class _CheckinSheetOpener extends StatefulWidget {
  const _CheckinSheetOpener({required this.detailsJson});

  final Map<String, dynamic> detailsJson;

  @override
  State<_CheckinSheetOpener> createState() => _CheckinSheetOpenerState();
}

class _CheckinSheetOpenerState extends State<_CheckinSheetOpener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showCheckInSheet(context, _detailsOf(widget.detailsJson)),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

BookingDetails _detailsOf(Map<String, dynamic> json) =>
    BookingDetails.fromJson(json);

Map<String, dynamic> _booking21Json() => const {
  'id': _booking21,
  'code': 'OA-G3021',
  'status': 'confirmed',
  'property': {
    'id': '00000000-0000-4000-8000-00000000001f',
    'title': 'شقة على البحر',
    'cover_image': null,
    'area_name': 'رأس البر',
    'city_name': 'دمياط',
    'address_text': 'شارع النيل، رأس البر',
    'check_in_time': '14:00',
    'check_out_time': '12:00',
  },
  'check_in': '2026-11-01',
  'check_out': '2026-11-04',
  'nights': 3,
  'guests_count': 2,
  'nightly_minor': 120000,
  'total_minor': 360000,
  'pay_now_minor': 360000,
  'paid_minor': 360000,
  'remaining_minor': 0,
  'remaining_due_at': null,
  'currency': 'EGP',
  'owner_response_deadline': null,
  'payment_state': 'succeeded',
  'payments': <Object>[],
  'refund': null,
  'terms_snapshot': null,
  'access_instructions': 'المفتاح مع حارس العمارة.',
  'available_actions': ['confirm_checkin', 'contact_support'],
  'events': <Object>[],
  'created_at': '2026-10-20T08:00:00Z',
};

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
    'checkin_sheet': () => _detailsChild(
      bookingId: _booking21,
      instead: _CheckinSheetOpener(detailsJson: _booking21Json()),
    ),
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
}
