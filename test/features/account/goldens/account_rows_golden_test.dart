@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/presentation/account_placeholder_screen.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_auth_repository.dart';

/// The account rows (T077): the sign-in method and the masked confirmed
/// phone with its chip — light/dark × RTL/LTR × 1.0/1.3 (§8).
void main() {
  final account = GuestAccount(
    id: 'account-guest',
    status: AccountStatus.active,
    phone: '+201012345678',
    phoneVerified: true,
    email: 'guest@example.com',
    emailVerified: true,
    fullName: 'زائر تجريبي',
    authProviders: const {AuthProvider.email, AuthProvider.google},
    hasPassword: false,
    acceptedTermsVersion: 'v1',
    acceptedTermsAt: DateTime.utc(2026),
  );

  Widget screen({
    required ThemeMode mode,
    required TextDirection direction,
    required double scale,
  }) {
    final cubit = AuthCubit(FakeAuthRepository())
      ..emit(SignedIn(account, isComplete: true));
    // A bounded surface: the Scaffold's ListView needs a finite height.
    return SizedBox(
      width: 480,
      height: 800,
      child: BlocProvider<AuthCubit>.value(
        value: cubit,
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
            child: Directionality(textDirection: direction, child: child!),
          ),
          home: const AccountPlaceholderScreen(),
        ),
      ),
    );
  }

  for (final (modeName, mode) in [
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    for (final (dirName, direction) in [
      ('rtl', TextDirection.rtl),
      ('ltr', TextDirection.ltr),
    ]) {
      for (final (scaleName, scale) in [('1_0', 1.0), ('1_3', 1.3)]) {
        unawaited(
          goldenTest(
            'account_rows — $modeName $dirName $scaleName',
            fileName: 'account_rows_${modeName}_${dirName}_$scaleName',
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 900),
            pumpBeforeTest: (tester) async {
              await tester.pump();
            },
            builder: () => GoldenTestScenario(
              name: '$modeName/$dirName/$scaleName',
              child: screen(mode: mode, direction: direction, scale: scale),
            ),
          ),
        );
      }
    }
  }
}
