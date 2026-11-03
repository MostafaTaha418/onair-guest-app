@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _login(ThemeMode mode, double scale) => SizedBox(
  width: 360,
  height: 800,
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
    home: const LoginScreen(phoneAuthEnabled: false),
  ),
);

void main() {
  for (final (name, mode, scale) in [
    ('light_RTL', ThemeMode.light, 1.0),
    ('dark_RTL', ThemeMode.dark, 1.0),
    ('light_RTL_1_3x', ThemeMode.light, 1.3),
  ]) {
    unawaited(
      goldenTest(
        'login — $name',
        fileName: 'login_$name',
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 850),
        builder: () => GoldenTestScenario(
          name: name,
          child: _login(mode, scale),
        ),
      ),
    );
  }
}
