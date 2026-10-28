import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_air/core/push/push_token_source.dart';
import 'package:on_air/features/account_gate/application/sign_out_service.dart';
import 'package:on_air/features/account_gate/data/device_repository.dart';
import 'package:on_air/features/auth/domain/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _AuthRepository extends Mock implements AuthRepository {}

final class _PushTokens implements PushTokenSource {
  _PushTokens(this.token);
  final String? token;

  @override
  Future<String?> currentToken() async => token;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
}

final class _DeviceRepository implements DeviceTokenRepository {
  _DeviceRepository(this.events, {this.fail = false});
  final List<String> events;
  final bool fail;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
    required String locale,
  }) async {
    events.add('register');
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    events.add('unregister');
    if (fail) throw StateError('offline');
  }
}

final class _CacheCleaner implements CacheCleaner {
  _CacheCleaner(this.events);
  final List<String> events;

  @override
  Future<void> clearCaches() async => events.add('caches');
}

final class _PreferenceCleaner implements PreferenceCleaner {
  _PreferenceCleaner(this.events);
  final List<String> events;
  Set<String>? preserved;

  @override
  Future<void> clearExcept(Set<String> keysToKeep) async {
    preserved = keysToKeep;
    events.add('preferences');
  }
}

void main() {
  late _AuthRepository auth;
  late List<String> events;

  setUp(() {
    auth = _AuthRepository();
    events = [];
    when(() => auth.signOut()).thenAnswer((_) async => events.add('signOut'));
  });

  test(
    'cleans up in the required order and preserves UI preferences',
    () async {
      final preferences = _PreferenceCleaner(events);
      final service = SignOutService(
        devices: _DeviceRepository(events),
        auth: auth,
        pushTokens: _PushTokens('fcm-token'),
        caches: _CacheCleaner(events),
        preferences: preferences,
      );

      await service.signOut();

      expect(events, ['unregister', 'signOut', 'caches', 'preferences']);
      expect(preferences.preserved, {
        'themeMode',
        'localeCode',
        'last_search_v1',
      });
    },
  );

  test('the last search survives sign-out (no personal data)', () async {
    SharedPreferences.setMockInitialValues({
      'themeMode': 'dark',
      'last_search_v1': '{"q":"g=2","label":null}',
    });
    final preferences = await SharedPreferences.getInstance();
    final service = SignOutService(
      devices: _DeviceRepository(events),
      auth: auth,
      pushTokens: _PushTokens('fcm-token'),
      caches: _CacheCleaner(events),
      preferences: const SharedPreferencesCleaner(),
    );

    await service.signOut();

    expect(preferences.getString('last_search_v1'), isNotNull);
    expect(preferences.getString('themeMode'), 'dark');
  });

  test('unregister failure never blocks the remaining cleanup', () async {
    final service = SignOutService(
      devices: _DeviceRepository(events, fail: true),
      auth: auth,
      pushTokens: _PushTokens('fcm-token'),
      caches: _CacheCleaner(events),
      preferences: _PreferenceCleaner(events),
    );

    await service.signOut();

    expect(events, ['unregister', 'signOut', 'caches', 'preferences']);
  });

  test('offline server sign-out still clears caches and preferences', () async {
    when(() => auth.signOut()).thenThrow(Exception('offline'));
    final service = SignOutService(
      devices: _DeviceRepository(events),
      auth: auth,
      pushTokens: _PushTokens('fcm-token'),
      caches: _CacheCleaner(events),
      preferences: _PreferenceCleaner(events),
    );

    await service.signOut();

    expect(events, ['unregister', 'caches', 'preferences']);
  });
}
