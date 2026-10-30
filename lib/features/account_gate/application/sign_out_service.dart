import 'package:on_air/core/config/app_config_repository.dart';
import 'package:on_air/core/push/push_token_source.dart';
import 'package:on_air/features/account_gate/data/device_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SignOutCoordinator {
  Future<void> signOut();
}

abstract interface class CacheCleaner {
  Future<void> clearCaches();
}

abstract interface class PreferenceCleaner {
  Future<void> clearExcept(Set<String> keysToKeep);
}

final class AppConfigCacheCleaner implements CacheCleaner {
  const AppConfigCacheCleaner(this._config);

  final AppConfigSource _config;

  @override
  Future<void> clearCaches() async => _config.clearCache();
}

final class SharedPreferencesCleaner implements PreferenceCleaner {
  const SharedPreferencesCleaner();

  @override
  Future<void> clearExcept(Set<String> keysToKeep) async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().where(
      (key) => !keysToKeep.contains(key),
    )) {
      await preferences.remove(key);
    }
  }
}

final class RepositorySignOutCoordinator implements SignOutCoordinator {
  const RepositorySignOutCoordinator(this._auth);

  final AuthRepository _auth;

  @override
  Future<void> signOut() => _auth.signOut();
}

final class SignOutService implements SignOutCoordinator {
  const SignOutService({
    required this.devices,
    required this.auth,
    required this.pushTokens,
    required this.caches,
    required this.preferences,
  });

  // last_search_v1 holds no personal data (spec Assumptions), so it stays.
  static const preservedPreferenceKeys = {
    'themeMode',
    'localeCode',
    'last_search_v1',
  };

  final DeviceTokenRepository devices;
  final AuthRepository auth;
  final PushTokenSource pushTokens;
  final CacheCleaner caches;
  final PreferenceCleaner preferences;

  @override
  Future<void> signOut() async {
    try {
      final token = await pushTokens.currentToken();
      if (token != null && token.isNotEmpty) {
        await devices.unregisterDeviceToken(token);
      }
    } on Object {
      // A stale server token is preferable to leaving the account signed in.
    }
    try {
      // GoTrue removes the local session before calling the server, so a
      // failure here (e.g. offline) only means the server call did not land.
      await auth.signOut();
    } on Object {
      // Continue: personal data must still be cleared (FR-034, SC-008).
    } finally {
      await caches.clearCaches();
      await preferences.clearExcept(preservedPreferenceKeys);
    }
  }
}
