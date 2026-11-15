@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/platform/secure_screen.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/auth/presentation/forgot_password_screen.dart';
import 'package:on_air/features/auth/presentation/new_password_screen.dart';
import 'package:on_air/features/auth/presentation/otp_screen.dart';
import 'package:on_air/features/auth/presentation/register_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../../helpers/fake_auth_repository.dart';

final class _NoSecure implements SecureScreenControl {
  @override
  Future<void> setSecure({required bool enabled}) async {}
}

Widget _screen(String name, DateTime now) => switch (name) {
  'register' => const RegisterScreen(),
  'recovery' => const ForgotPasswordScreen(),
  'new_password' => const NewPasswordScreen(),
  'otp' => _otp(now),
  _ => throw ArgumentError.value(name),
};

Widget _otp(DateTime now) {
  final auth = FakeAuthRepository()
    ..challenge = CodeChallenge(
      channel: VerificationChannel.emailRecovery,
      target: 'guest@example.com',
      resendAt: now.add(const Duration(seconds: 57)),
    );
  final cubit = AuthCubit(auth, clock: () => now);
  unawaited(cubit.requestRecovery('guest@example.com'));
  return BlocProvider<AuthCubit>.value(
    value: cubit,
    child: OtpScreen(
      secureScreen: _NoSecure(),
      clock: () => now,
    ),
  );
}

Widget _theme(
  String name,
  ThemeMode mode,
  Locale locale,
  double scale,
  double width,
  double height,
  DateTime now,
) => SizedBox(
  width: width,
  height: height,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
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
      child: child!,
    ),
    home: _screen(name, now),
  ),
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  // Asset images decode on the real event loop: step outside the fake
  // async zone briefly so the social logos paint in the golden.
  await tester.runAsync<void>(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

void main() {
  final now = DateTime.utc(2026, 11, 3, 10);
  for (final screen in ['register', 'recovery', 'otp', 'new_password']) {
    for (final (variant, mode, locale, scale, width, height) in [
      ('light_ar', ThemeMode.light, const Locale('ar'), 1.0, 360.0, 800.0),
      ('dark_ar', ThemeMode.dark, const Locale('ar'), 1.0, 360.0, 800.0),
      ('light_en', ThemeMode.light, const Locale('en'), 1.0, 360.0, 800.0),
      ('dark_en', ThemeMode.dark, const Locale('en'), 1.0, 360.0, 800.0),
      ('small_ar_1_3x', ThemeMode.light, const Locale('ar'), 1.3, 320.0, 640.0),
      ('wide_en', ThemeMode.light, const Locale('en'), 1.0, 600.0, 900.0),
    ]) {
      unawaited(
        goldenTest(
          '$screen — $variant',
          fileName: '${screen}_$variant',
          constraints: BoxConstraints(
            maxWidth: width + 20,
            maxHeight: height + 50,
          ),
          pumpBeforeTest: _pump,
          builder: () => GoldenTestScenario(
            name: variant,
            child: _theme(screen, mode, locale, scale, width, height, now),
          ),
        ),
      );
    }
  }
}
