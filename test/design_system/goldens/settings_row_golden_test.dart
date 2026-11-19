import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/settings_row.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

Widget _scenario(ThemeMode mode, Locale locale, double scale) => SizedBox(
  width: 360,
  height: 660,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
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
    home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsGroup(
            label: locale.languageCode == 'ar' ? 'عام' : 'General',
            children: [
              SettingsRow(
                icon: Icons.notifications_none,
                title: locale.languageCode == 'ar'
                    ? 'الإشعارات'
                    : 'Notifications',
                showChevron: true,
                onTap: () {},
              ),
              SettingsRow(
                icon: Icons.palette_outlined,
                title: locale.languageCode == 'ar' ? 'المظهر' : 'Appearance',
                tone: SettingsIconTone.teal,
                value: locale.languageCode == 'ar' ? 'حسب الجهاز' : 'System',
                showChevron: true,
                onTap: () {},
              ),
              SettingsRow(
                icon: Icons.language,
                title: locale.languageCode == 'ar' ? 'اللغة' : 'Language',
                tone: SettingsIconTone.orange,
                trailing: const Switch(value: true, onChanged: null),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsGroup(
            label: locale.languageCode == 'ar' ? 'الحساب' : 'Account',
            children: [
              SettingsRow(
                icon: Icons.security_outlined,
                title: locale.languageCode == 'ar'
                    ? 'الأمان والأجهزة'
                    : 'Security & devices',
                subtitle: locale.languageCode == 'ar'
                    ? 'راجع الأجهزة المسجّل دخولها'
                    : 'Review signed-in devices',
                tone: SettingsIconTone.neutral,
                locked: true,
              ),
              SettingsRow(
                icon: Icons.delete_outline,
                title: locale.languageCode == 'ar'
                    ? 'حذف الحساب'
                    : 'Delete account',
                tone: SettingsIconTone.danger,
                enabled: false,
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

void main() {
  unawaited(
    goldenTest(
      'settings rows cover tones and states',
      fileName: 'settings_rows',
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 6000),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final mode in [ThemeMode.light, ThemeMode.dark])
            for (final locale in [const Locale('ar'), const Locale('en')])
              for (final scale in [1.0, 1.3])
                GoldenTestScenario(
                  name: '${mode.name} ${locale.languageCode} ${scale}x',
                  child: _scenario(mode, locale, scale),
                ),
        ],
      ),
    ),
  );
}
