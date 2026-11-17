import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/app/settings/app_settings_store.dart';

@immutable
final class AppSettings {
  const AppSettings({
    this.locale = const Locale('ar'),
    this.themeMode = ThemeMode.system,
    this.englishEnabled = true,
    this.pendingLocaleSync = false,
  });

  final Locale locale;
  final ThemeMode themeMode;
  final bool englishEnabled;
  final bool pendingLocaleSync;

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? englishEnabled,
    bool? pendingLocaleSync,
  }) => AppSettings(
    locale: locale ?? this.locale,
    themeMode: themeMode ?? this.themeMode,
    englishEnabled: englishEnabled ?? this.englishEnabled,
    pendingLocaleSync: pendingLocaleSync ?? this.pendingLocaleSync,
  );
}

final class AppSettingsCubit extends Cubit<AppSettings> {
  AppSettingsCubit({
    required this.store,
    bool englishEnabled = true,
    this.loadEnglishEnabled,
    bool Function()? isSignedIn,
    this.syncProfileLocale,
  }) : _isSignedIn = isSignedIn ?? (() => false),
       super(AppSettings(englishEnabled: englishEnabled));

  /// Deterministic presentation state for goldens and focused widget tests.
  AppSettingsCubit.seeded(super.initialState)
    : store = const AppSettingsStore(),
      loadEnglishEnabled = null,
      _isSignedIn = _neverSignedIn,
      syncProfileLocale = null;

  final AppSettingsStore store;
  final Future<bool> Function()? loadEnglishEnabled;
  final bool Function() _isSignedIn;
  final Future<void> Function(String locale)? syncProfileLocale;

  Future<void> start() async {
    // The stored choices apply before anything can fail: a config fetch
    // error must not boot the app back to the defaults (ar/system).
    final stored = await store.read();
    if (isClosed) return;
    emit(state.copyWith(locale: stored.locale, themeMode: stored.themeMode));
    var englishEnabled = state.englishEnabled;
    try {
      englishEnabled = await loadEnglishEnabled?.call() ?? englishEnabled;
    } on Object {
      // Offline or broken config: keep the current value.
    }
    if (isClosed) return;
    final locale = !englishEnabled && state.locale.languageCode == 'en'
        ? const Locale('ar')
        : state.locale;
    emit(state.copyWith(locale: locale, englishEnabled: englishEnabled));
    if (state.pendingLocaleSync) await _syncLocale(locale.languageCode);
  }

  Future<bool> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (code != 'ar' && code != 'en') return false;
    if (code == 'en' && !state.englishEnabled) return false;
    if (state.locale.languageCode == code && !state.pendingLocaleSync) {
      return true;
    }
    await store.writeLocale(Locale(code));
    emit(state.copyWith(locale: Locale(code), pendingLocaleSync: false));
    if (_isSignedIn()) await _syncLocale(code);
    return true;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    await store.writeThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> _syncLocale(String code) async {
    final sync = syncProfileLocale;
    if (sync == null) return;
    try {
      await sync(code);
      if (isClosed) return;
      emit(state.copyWith(pendingLocaleSync: false));
    } on Object {
      if (isClosed) return;
      emit(state.copyWith(pendingLocaleSync: true));
    }
  }
}

bool _neverSignedIn() => false;
