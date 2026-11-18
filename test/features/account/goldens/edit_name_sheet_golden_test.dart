@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/account/presentation/edit_name_sheet.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  final states = <(String, String)>[
    ('valid', 'منى إبراهيم'),
    ('too_short', 'م'),
  ];

  for (final (stateName, name) in states) {
    for (final (themeName, themeMode) in [
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      for (final (localeName, locale) in [
        ('ar_rtl', const Locale('ar')),
        ('en_ltr', const Locale('en')),
      ]) {
        for (final (scaleName, textScale) in [
          ('1_0', 1.0),
          ('1_3', 1.3),
        ]) {
          for (final width in [320.0, 800.0]) {
            final widthName = width.toInt();
            final variant =
                '${themeName}_${localeName}_${scaleName}_$widthName';
            unawaited(
              goldenTest(
                'edit name — $stateName $variant',
                fileName: 'edit_name_sheet_${stateName}_$variant',
                constraints: BoxConstraints(
                  maxWidth: width + 40,
                  maxHeight: 920,
                ),
                pumpBeforeTest: (tester) async {
                  await tester.pump();
                  await tester.pump(const Duration(milliseconds: 300));
                },
                builder: () => GoldenTestScenario(
                  name: '$stateName/$variant',
                  child: _surface(
                    name,
                    themeMode: themeMode,
                    locale: locale,
                    textScale: textScale,
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
  String name, {
  required ThemeMode themeMode,
  required Locale locale,
  required double textScale,
  required double width,
}) => SizedBox(
  width: width,
  height: 844,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: themeMode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
        viewInsets: const EdgeInsets.only(bottom: 280),
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: themeMode == ThemeMode.dark
              ? OnAirTheme.dark.colorScheme.surface
              : OnAirTheme.light.colorScheme.surface,
          borderRadius: const BorderRadiusDirectional.vertical(
            top: Radius.circular(Dimens.radiusSheet),
          ),
          clipBehavior: Clip.antiAlias,
          child: OnAirEditNameSheet(currentName: name),
        ),
      ),
    ),
  ),
);
