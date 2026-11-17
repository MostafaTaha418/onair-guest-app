import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/settings/app_settings_cubit.dart';
import 'package:on_air/app/settings/app_settings_store.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/account/presentation/settings_sheets.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  AppSettingsCubit cubit({bool englishEnabled = true}) => AppSettingsCubit(
    store: const AppSettingsStore(),
    englishEnabled: englishEnabled,
  );

  Widget surface(AppSettingsCubit settings) =>
      BlocProvider<AppSettingsCubit>.value(
        value: settings,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: OnAirTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () => showLanguageSheet(context),
                      child: const Text('language'),
                    ),
                    TextButton(
                      onPressed: () => showAppearanceSheet(context),
                      child: const Text('appearance'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('the language radio applies immediately', (tester) async {
    final settings = cubit();
    addTearDown(settings.close);
    await settings.start();
    await tester.pumpWidget(surface(settings));
    await tester.tap(find.text('language'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsLanguageArabic), findsOneWidget);
    expect(find.text(l10n.settingsLanguageEnglish), findsOneWidget);
    await tester.tap(find.text(l10n.settingsLanguageEnglish));
    await tester.pumpAndSettle();
    expect(settings.state.locale.languageCode, 'en');
  });

  testWidgets('English is hidden when englishEnabled is false', (tester) async {
    final settings = cubit(englishEnabled: false);
    addTearDown(settings.close);
    await settings.start();
    await tester.pumpWidget(surface(settings));
    await tester.tap(find.text('language'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsLanguageArabic), findsOneWidget);
    expect(find.text(l10n.settingsLanguageEnglish), findsNothing);
  });

  testWidgets('the appearance radio applies immediately', (tester) async {
    final settings = cubit();
    addTearDown(settings.close);
    await settings.start();
    await tester.pumpWidget(surface(settings));
    await tester.tap(find.text('appearance'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsThemeSystem), findsOneWidget);
    expect(find.text(l10n.settingsThemeLight), findsOneWidget);
    expect(find.text(l10n.settingsThemeDark), findsOneWidget);
    await tester.tap(find.text(l10n.settingsThemeDark));
    await tester.pumpAndSettle();
    expect(settings.state.themeMode, ThemeMode.dark);
  });
}
