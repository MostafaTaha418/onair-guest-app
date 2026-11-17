@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/features/support/presentation/home/support_home_cubit.dart';
import 'package:on_air/features/support/presentation/home/support_home_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_support_repository.dart';

void main() {
  Widget surface(
    SupportHomeState state, {
    required ThemeMode themeMode,
    required Locale locale,
    required double textScale,
    required double width,
  }) {
    final cubit = SupportHomeCubit.seeded(
      repository: FakeSupportRepository(),
      state: state,
    );
    return SizedBox(
      width: width,
      height: 844,
      child: BlocProvider.value(
        value: cubit,
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
            ),
            child: child!,
          ),
          home: SupportHomeScreen(now: () => DateTime.utc(2026, 11, 16, 14)),
        ),
      ),
    );
  }

  final open = sampleSupportCase();
  final finished = sampleSupportCase(
    id: 'c0000000-0000-4000-8000-000000000002',
    status: CaseStatus.closed,
    activity: DateTime.utc(2026, 11, 15),
  );

  final states = <(String, SupportHomeState)>[
    ('empty', const SupportHomeEmpty()),
    (
      'list',
      SupportHomeReady(items: [open, finished], nextCursor: null),
    ),
    (
      'offline',
      SupportHomeReady(
        items: [open, finished],
        nextCursor: null,
        offline: true,
      ),
    ),
  ];
  for (final (stateName, state) in states) {
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
                'support home — $stateName $variant',
                fileName: 'support_home_${stateName}_$variant',
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
                  child: surface(
                    state,
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
