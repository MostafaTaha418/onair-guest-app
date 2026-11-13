@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/social_sign_in_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _button(
  SocialProvider provider, {
  required ThemeMode mode,
  bool busy = false,
  bool enabled = true,
}) => SizedBox(
  width: 160,
  height: 160,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: mode,
    home: Center(
      child: SocialSignInButton(
        provider: provider,
        onPressed: enabled ? () {} : null,
        busy: busy,
      ),
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
  for (final provider in SocialProvider.values) {
    for (final (stateName, busy, enabled) in [
      ('enabled', false, true),
      ('busy', true, true),
      ('disabled', false, false),
    ]) {
      for (final (modeName, mode) in [
        ('light', ThemeMode.light),
        ('dark', ThemeMode.dark),
      ]) {
        unawaited(
          goldenTest(
            '${provider.name} — $stateName — $modeName',
            fileName: 'social_${provider.name}_${stateName}_$modeName',
            constraints: const BoxConstraints(maxWidth: 200, maxHeight: 240),
            pumpBeforeTest: _pump,
            builder: () => GoldenTestScenario(
              name: '$stateName/$modeName',
              child: _button(
                provider,
                busy: busy,
                enabled: enabled,
                mode: mode,
              ),
            ),
          ),
        );
      }
    }
  }
}
