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
    final stored = await store.read();
    final englishEnabled =
        await loadEnglishEnabled?.call() ?? state.englishEnabled;
    final locale = !englishEnabled && stored.locale.languageCode == 'en'
        ? const Locale('ar')
        : stored.locale;
    if (isClosed) return;
    emit(
      state.copyWith(
        locale: locale,
        themeMode: stored.themeMode,
        englishEnabled: englishEnabled,
      ),
    );
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
