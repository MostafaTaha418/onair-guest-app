@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/domain/account_repository.dart';
import 'package:on_air/features/account/presentation/security/change_password_cubit.dart';
import 'package:on_air/features/account/presentation/security/change_password_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_connectivity.dart';

class _Repository extends Fake implements AccountRepository {}

void main() {
  for (final stateName in ['empty', 'rule_met', 'incorrect']) {
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
                'change password — $stateName $variant',
                fileName: 'change_password_${stateName}_$variant',
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
  final populated = stateName != 'empty';
  final cubit = ChangePasswordCubit.seeded(
    _Repository(),
    ChangePasswordState(
      current: populated ? 'Passw0rd!' : '',
      next: populated ? 'Nextpass1' : '',
      confirm: populated ? 'Nextpass1' : '',
      currentError: stateName == 'incorrect'
          ? const ApiError(
              code: ErrorCode.passwordIncorrect,
              messageKey: 'accountPasswordIncorrect',
            )
          : null,
    ),
  );
  final connectivity = FakeConnectivity().createCubit();
  return SizedBox(
    width: width,
    height: 844,
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
            viewInsets: const EdgeInsets.only(bottom: 280),
          ),
          child: child!,
        ),
        home: const ChangePasswordScreen(),
      ),
    ),
  );
}
