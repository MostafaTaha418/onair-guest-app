import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/app/settings/app_settings_cubit.dart';
import 'package:on_air/app/settings/app_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to Arabic and the system theme', () async {
    final cubit = AppSettingsCubit(store: const AppSettingsStore());
    addTearDown(cubit.close);
    await cubit.start();
    expect(cubit.state.locale, const Locale('ar'));
    expect(cubit.state.themeMode, ThemeMode.system);
  });

  test('locale and theme persist across cubit instances', () async {
    final first = AppSettingsCubit(store: const AppSettingsStore());
    await first.start();
    await first.setLocale(const Locale('en'));
    await first.setThemeMode(ThemeMode.dark);
    await first.close();

    final second = AppSettingsCubit(store: const AppSettingsStore());
    addTearDown(second.close);
    await second.start();
    expect(second.state.locale, const Locale('en'));
    expect(second.state.themeMode, ThemeMode.dark);
  });

  test('English is refused when the public config disables it', () async {
    final cubit = AppSettingsCubit(
      store: const AppSettingsStore(),
      englishEnabled: false,
    );
    addTearDown(cubit.close);
    await cubit.start();
    expect(await cubit.setLocale(const Locale('en')), isFalse);
    expect(cubit.state.locale, const Locale('ar'));
  });

  test(
    'signed-in locale sync is called once and retried after failure',
    () async {
      var calls = 0;
      final cubit = AppSettingsCubit(
        store: const AppSettingsStore(),
        isSignedIn: () => true,
        syncProfileLocale: (_) async {
          calls++;
          if (calls == 1) throw StateError('offline');
        },
      );
      addTearDown(cubit.close);
      await cubit.start();
      await cubit.setLocale(const Locale('en'));
      expect(calls, 1);
      expect(cubit.state.pendingLocaleSync, isTrue);

      await cubit.start();
      expect(calls, 2);
      expect(cubit.state.pendingLocaleSync, isFalse);
    },
  );

  test(
    'a failed english check still applies the stored locale and theme',
    () async {
      const store = AppSettingsStore();
      await store.writeLocale(const Locale('en'));
      await store.writeThemeMode(ThemeMode.dark);
      final cubit = AppSettingsCubit(
        store: store,
        loadEnglishEnabled: () async => throw StateError('offline'),
      );
      addTearDown(cubit.close);

      await cubit.start();

      expect(cubit.state.locale, const Locale('en'));
      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.englishEnabled, isTrue);
    },
  );

  test('a config that disables English falls back to Arabic', () async {
    const store = AppSettingsStore();
    await store.writeLocale(const Locale('en'));
    final cubit = AppSettingsCubit(
      store: store,
      loadEnglishEnabled: () async => false,
    );
    addTearDown(cubit.close);

    await cubit.start();

    expect(cubit.state.locale, const Locale('ar'));
    expect(cubit.state.englishEnabled, isFalse);
  });
}
