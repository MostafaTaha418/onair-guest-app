import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/app/splash/splash_screen.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/components/on_air_bottom_nav.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/home/presentation/home_placeholder_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class _Connectivity extends Mock implements Connectivity {}

Widget _frame({
  required Widget home,
  required ThemeMode mode,
  required double scale,
  required double width,
}) => SizedBox(
  width: width,
  height: 600,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: mode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: home,
  ),
);

Widget _shell(ThemeMode mode, double scale, double width) {
  final connectivity = _Connectivity();
  when(
    () => connectivity.onConnectivityChanged,
  ).thenAnswer((_) => const Stream.empty());
  when(
    connectivity.checkConnectivity,
  ).thenAnswer((_) async => [ConnectivityResult.wifi]);
  final cubit = ConnectivityCubit(connectivity: connectivity);
  addTearDown(cubit.close);
  return _frame(
    mode: mode,
    scale: scale,
    width: width,
    home: BlocProvider<ConnectivityCubit>.value(
      value: cubit,
      child: Scaffold(
        body: const HomePlaceholderScreen(),
        bottomNavigationBar: OnAirBottomNav(
          currentIndex: 0,
          labels: const ['الرئيسية', 'بحث', 'حجوزاتي', 'المفضلة', 'حسابي'],
          onTap: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  unawaited(
    goldenTest(
      'splash palette and scaling',
      fileName: 'splash',
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 1400),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.light,
              scale: 1,
              width: 360,
            ),
          ),
          GoldenTestScenario(
            name: 'dark',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.dark,
              scale: 1,
              width: 360,
            ),
          ),
          GoldenTestScenario(
            name: '1.3x',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.light,
              scale: 1.3,
              width: 360,
            ),
          ),
          GoldenTestScenario(
            name: '320 wide',
            child: _frame(
              home: const SplashScreen(),
              mode: ThemeMode.light,
              scale: 1,
              width: 320,
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'visitor shell palette and scaling',
      fileName: 'visitor_shell',
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 1400),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'light',
            child: _shell(ThemeMode.light, 1, 360),
          ),
          GoldenTestScenario(
            name: 'dark',
            child: _shell(ThemeMode.dark, 1, 360),
          ),
          GoldenTestScenario(
            name: '1.3x',
            child: _shell(ThemeMode.light, 1.3, 360),
          ),
          GoldenTestScenario(
            name: '320 wide',
            child: _shell(ThemeMode.light, 1, 320),
          ),
        ],
      ),
    ),
  );
}
