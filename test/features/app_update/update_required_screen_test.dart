import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/app_update/presentation/update_required_screen.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

import '../../helpers/fake_app_config_repository.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

const _config = AppConfig(
  minSupportedBuildAndroid: 1,
  minSupportedBuildIos: 1,
  supportPhone: '+201000000000',
  currentTermsVersion: 'v1',
);

void main() {
  testWidgets('store button opens the platform store', (tester) async {
    var opened = false;
    await tester.pumpOnAirApp(
      UpdateRequiredScreen(onOpenStore: () => opened = true),
      authRepository: FakeAuthRepository(),
      appConfigRepository: FakeAppConfigRepository(_config),
    );
    await tester.tap(find.byType(OnAirPrimaryButton));
    expect(opened, isTrue);
  });

  testWidgets('system back navigation is blocked', (tester) async {
    await tester.pumpOnAirApp(
      const UpdateRequiredScreen(),
      authRepository: FakeAuthRepository(),
      appConfigRepository: FakeAppConfigRepository(_config),
    );
    // PopScope(canPop: false) is the blocking contract: a back request is
    // handled by the scope and never leaves the screen.
    expect(
      tester.widget<PopScope>(find.byType(PopScope)).canPop,
      isFalse,
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pump();
    expect(find.byType(UpdateRequiredScreen), findsOneWidget);
  });

  unawaited(
    goldenTest(
      'update required screen palette and scaling',
      fileName: 'update_required_screen',
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 1400),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(name: 'light', child: _frame(ThemeMode.light)),
          GoldenTestScenario(name: 'dark', child: _frame(ThemeMode.dark)),
        ],
      ),
    ),
  );
}

Widget _frame(ThemeMode mode) => SizedBox(
  width: 360,
  height: 600,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: OnAirTheme.light,
    darkTheme: OnAirTheme.dark,
    themeMode: mode,
    home: const Directionality(
      textDirection: TextDirection.rtl,
      child: UpdateRequiredScreen(),
    ),
  ),
);
