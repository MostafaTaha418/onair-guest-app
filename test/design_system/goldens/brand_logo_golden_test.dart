import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:on_air/design_system/brand/on_air_logo.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _sheet(ThemeMode mode, String locale) => SizedBox(
  width: 360,
  height: 300,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale(locale),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: mode,
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            OnAirLogo.lockup(height: 56),
            OnAirLogo.wordmark(),
            Row(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                OnAirLogo.mark(height: 64),
                OnAirLogo.mark(),
                // Small-size cut (32 px and below).
                OnAirLogo.mark(height: 24),
                OnAirLogo.mark(height: 16),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  unawaited(
    goldenTest(
      'brand logo in both themes and languages',
      fileName: 'brand_logo',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light ar',
            child: _sheet(ThemeMode.light, 'ar'),
          ),
          GoldenTestScenario(
            name: 'light en',
            child: _sheet(ThemeMode.light, 'en'),
          ),
          GoldenTestScenario(
            name: 'dark ar',
            child: _sheet(ThemeMode.dark, 'ar'),
          ),
          GoldenTestScenario(
            name: 'dark en',
            child: _sheet(ThemeMode.dark, 'en'),
          ),
        ],
      ),
    ),
  );
}
