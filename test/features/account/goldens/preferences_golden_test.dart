@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';
import 'package:on_air/features/account/presentation/notifications/preferences_cubit.dart';
import 'package:on_air/features/account/presentation/notifications/preferences_screen.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';

class _Repository extends Fake implements AccountRepository {}

void main() {
  for (final (themeName, themeMode) in [
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    for (final (localeName, locale) in [
      ('ar_rtl', const Locale('ar')),
      ('en_ltr', const Locale('en')),
    ]) {
      for (final (scaleName, scale) in [('1_0', 1.0), ('1_3', 1.3)]) {
        for (final width in [320.0, 800.0]) {
          final variant =
              '${themeName}_${localeName}_${scaleName}_${width.toInt()}';
          unawaited(
            goldenTest(
              'preferences — mixed blocked $variant',
              fileName: 'preferences_mixed_blocked_$variant',
              constraints: BoxConstraints(
                maxWidth: width + 40,
                maxHeight: 920,
              ),
              builder: () => GoldenTestScenario(
                name: 'mixed-blocked/$variant',
                child: _surface(
                  themeMode: themeMode,
                  locale: locale,
                  scale: scale,
                  width: width,
                ),
              ),
            ),
          );
        }
      }
    }
  }
}

Widget _surface({
  required ThemeMode themeMode,
  required Locale locale,
  required double scale,
  required double width,
}) {
  const preferences = [
    NotificationPreference(
      key: 'booking',
      labelKey: 'notifCategoryBooking',
      isMandatory: true,
      channels: {
        NotificationChannel.push: PreferenceChannel(enabled: true),
        NotificationChannel.email: PreferenceChannel(enabled: true),
      },
    ),
    NotificationPreference(
      key: 'support',
      labelKey: 'notifCategorySupport',
      isMandatory: false,
      channels: {
        NotificationChannel.push: PreferenceChannel(enabled: false),
        NotificationChannel.email: PreferenceChannel(enabled: true),
      },
    ),
    NotificationPreference(
      key: 'reminders',
      labelKey: 'notifCategoryReminders',
      isMandatory: false,
      channels: {
        NotificationChannel.push: PreferenceChannel(enabled: true),
        NotificationChannel.email: PreferenceChannel(enabled: false),
      },
    ),
  ];
  final cubit = PreferencesCubit.seeded(
    _Repository(),
    const PreferencesReady(
      preferences: preferences,
      deviceNotificationsBlocked: true,
    ),
  );
  final connectivity = FakeConnectivity().createCubit();
  final coordinator = PushPermissionCoordinator(
    permission: FakeNotificationPermission(current: PushPermission.denied),
    devices: null,
  );
  return SizedBox(
    width: width,
    height: 844,
    child: RepositoryProvider.value(
      value: coordinator,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider<ConnectivityCubit>.value(value: connectivity),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: OnAirTheme.light,
          darkTheme: OnAirTheme.dark,
          themeMode: themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const PreferencesScreen(),
        ),
      ),
    ),
  );
}
