@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/auth/presentation/login_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Sets the target platform for the pumped tree and resets it afterwards, so
/// the iOS/Android social-row variants stay isolated.
class _PlatformScope extends StatefulWidget {
  const _PlatformScope({required this.platform, required this.child});

  final TargetPlatform platform;
  final Widget child;

  @override
  State<_PlatformScope> createState() => _PlatformScopeState();
}

class _PlatformScopeState extends State<_PlatformScope> {
  @override
  void initState() {
    super.initState();
    debugDefaultTargetPlatformOverride = widget.platform;
  }

  @override
  void dispose() {
    debugDefaultTargetPlatformOverride = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _login(ThemeMode mode, double scale, TargetPlatform platform) =>
    _PlatformScope(
      platform: platform,
      child: SizedBox(
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
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: const LoginScreen(),
        ),
      ),
    );

/// Asset images decode on the real event loop: step outside the fake async
/// zone briefly, then pump again so the logos are painted in the golden.
Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync<void>(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

void main() {
  for (final (platform, platformName) in [
    (TargetPlatform.iOS, 'ios'),
    (TargetPlatform.android, 'android'),
  ]) {
    for (final (name, mode, scale) in [
      ('light_RTL', ThemeMode.light, 1.0),
      ('dark_RTL', ThemeMode.dark, 1.0),
      ('light_RTL_1_3x', ThemeMode.light, 1.3),
    ]) {
      unawaited(
        goldenTest(
          'login — ${platformName}_$name',
          fileName: 'login_${platformName}_$name',
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 850),
          pumpBeforeTest: _pump,
          builder: () => GoldenTestScenario(
            name: name,
            child: _login(mode, scale, platform),
          ),
        ),
      );
    }
  }
}
