@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/domain/active_session.dart';
import 'package:on_air/features/account/presentation/security/security_cubit.dart';
import 'package:on_air/features/account/presentation/security/security_screen.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';

class _Repository extends Fake implements AccountRepository {}

class _Auth extends Fake implements AuthRepository {
  @override
  Stream<GuestAccount?> get authStateChanges => const Stream.empty();
}

void main() {
  for (final stateName in ['password', 'social', 'ending']) {
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
                'security — $stateName $variant',
                fileName: 'security_${stateName}_$variant',
                // The ending state intentionally contains an indeterminate
                // progress indicator, so settling would never complete.
                pumpBeforeTest: (tester) =>
                    tester.pump(const Duration(milliseconds: 100)),
                constraints: BoxConstraints(
                  maxWidth: width + 40,
                  maxHeight: 920,
                ),
                builder: () => GoldenTestScenario(
                  name: '$stateName/$variant',
                  child: _surface(
                    stateName,
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
}

Widget _surface(
  String stateName, {
  required ThemeMode themeMode,
  required Locale locale,
  required double scale,
  required double width,
}) {
  final now = DateTime.now().toUtc();
  final sessions = [
    ActiveSession(
      id: 'current',
      deviceLabel: 'Samsung SM-A546 · Android 14',
      platform: SessionPlatform.android,
      createdAt: now.subtract(const Duration(days: 30)),
      lastActiveAt: now,
      isCurrent: true,
    ),
    ActiveSession(
      id: 'iphone',
      deviceLabel: 'iPhone 15 · iOS 18',
      platform: SessionPlatform.ios,
      createdAt: now.subtract(const Duration(days: 10)),
      lastActiveAt: now.subtract(const Duration(hours: 2)),
      isCurrent: false,
    ),
    ActiveSession(
      id: 'web',
      deviceLabel: 'Chrome · Windows',
      platform: SessionPlatform.web,
      createdAt: now.subtract(const Duration(days: 5)),
      lastActiveAt: now.subtract(const Duration(days: 1)),
      isCurrent: false,
    ),
  ];
  final repository = _Repository();
  final security = SecurityCubit.seeded(
    repository,
    SecurityReady(
      sessions: sessions,
      ending: stateName == 'ending' ? {'iphone'} : const {},
    ),
  );
  final auth = AuthCubit(_Auth())
    ..applyAccount(
      GuestAccount(
        id: 'guest',
        status: AccountStatus.active,
        phone: '+201012345678',
        hasPassword: stateName != 'social',
      ),
    );
  final connectivity = FakeConnectivity().createCubit();
  return SizedBox(
    width: width,
    height: 844,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: security),
        BlocProvider.value(value: auth),
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
        home: const SecurityScreen(),
      ),
    ),
  );
}
