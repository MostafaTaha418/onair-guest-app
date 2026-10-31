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
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/notifications/domain/app_notification.dart';
import 'package:on_air/features/notifications/presentation/notifications_cubit.dart';
import 'package:on_air/features/notifications/presentation/notifications_screen.dart';
import 'package:on_air/features/notifications/presentation/unread_count_cubit.dart';
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

AppNotification _notification(String id, String typeKey, DateTime createdAt) =>
    AppNotification(
      id: id,
      typeKey: typeKey,
      category: 'booking',
      entityType: 'booking',
      entityId: 'b0000000-0000-4000-8000-000000000001',
      params: const {},
      readAt: null,
      createdAt: createdAt,
    );

/// The center with the fixture's unread rows ([denied] adds the
/// «notifications are off» notice).
Widget _centerChild({required bool denied}) {
  final backend = FakeBookingBackend();
  final connectivityCubit = FakeConnectivity().createCubit();
  final unread = UnreadCountCubit(
    notifications: backend.server,
    signals: backend.signals,
  );
  final cubit =
      NotificationsCubit(
        notifications: backend.server,
        signals: backend.signals,
        connectivity: connectivityCubit,
        unread: unread,
      )..emit(
        NotificationsReady(
          items: [
            _notification(
              'e0000000-0000-4000-8000-000000000001',
              'booking.request_received',
              DateTime.utc(2026, 10, 30, 8),
            ),
            _notification(
              'e0000000-0000-4000-8000-000000000002',
              'booking.confirmed',
              DateTime.utc(2026, 10, 29, 12),
            ),
            _notification(
              'e0000000-0000-4000-8000-000000000003',
              'booking.rejected',
              DateTime.utc(2026, 10, 29, 11),
            ),
            _notification(
              'e0000000-0000-4000-8000-000000000004',
              'booking.expired',
              DateTime.utc(2026, 10, 28, 9),
            ),
          ],
          hasMore: false,
        ),
      );
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ConnectivityCubit>.value(value: connectivityCubit),
      ...backend.appProviders(),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<NotificationsCubit>.value(value: cubit),
        BlocProvider<UnreadCountCubit>.value(value: unread),
      ],
      child: RepositoryProvider<NotificationPermission>.value(
        value: FakeNotificationPermission(
          current: denied ? PushPermission.denied : PushPermission.granted,
        ),
        child: const NotificationsScreen(),
      ),
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
        'notification center with unread items — $name',
        fileName: 'notifications_unread_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1300),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, scale, 400, 1200, _centerChild(denied: false)),
        ),
      ),
    );
    unawaited(
      goldenTest(
        'notification center with the off notice — $name',
        fileName: 'notifications_off_$name',
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 1300),
        pumpBeforeTest: _pumpTwoFrames,
        builder: () => GoldenTestScenario(
          name: name,
          child: _theme(mode, scale, 400, 1200, _centerChild(denied: true)),
        ),
      ),
    );
  }
}
