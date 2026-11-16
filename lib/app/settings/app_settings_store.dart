import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class StoredAppSettings {
  const StoredAppSettings({required this.locale, required this.themeMode});

  final Locale locale;
  final ThemeMode themeMode;
}

final class AppSettingsStore {
  const AppSettingsStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const localeKey = 'localeCode';
  static const themeModeKey = 'themeMode';
  final Future<SharedPreferences> Function() _preferences;

  Future<StoredAppSettings> read() async {
    final prefs = await _preferences();
    final localeCode = switch (prefs.getString(localeKey)) {
      'en' => 'en',
      _ => 'ar',
    };
    final theme = switch (prefs.getString(themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return StoredAppSettings(locale: Locale(localeCode), themeMode: theme);
  }

  Future<void> writeLocale(Locale locale) async {
    await (await _preferences()).setString(localeKey, locale.languageCode);
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    await (await _preferences()).setString(themeModeKey, mode.name);
  }
}
