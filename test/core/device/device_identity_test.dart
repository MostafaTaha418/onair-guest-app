import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/device/device_identity.dart';
import 'package:on_air/core/storage/secure_store.dart';

final class _FakeSecureStore implements SecureStore {
  final Map<String, String> values = {};
  int writes = 0;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    writes += 1;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<Map<String, String>> readAll() async => Map.of(values);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeychainDeviceIdentity (iOS)', () {
    test('creates a v4 UUID and stores it under device_install_id', () async {
      final store = _FakeSecureStore();
      final identity = KeychainDeviceIdentity(store: store);

      final id = await identity.id();

      expect(KeychainDeviceIdentity.isUuidV4(id), isTrue, reason: id);
      expect(store.values['device_install_id'], id);
      expect(store.writes, 1);
    });

    test(
      'a second instance on the same store returns the same value',
      () async {
        // Simulated reinstall: a new identity object over the surviving
        // Keychain store must not mint a new id (research R4).
        final store = _FakeSecureStore();
        final first = await KeychainDeviceIdentity(store: store).id();
        final second = await KeychainDeviceIdentity(store: store).id();
        expect(second, first);
        expect(store.writes, 1);
      },
    );
  });

  group('AndroidDeviceIdentity', () {
    const channel = MethodChannel('on_air/device_identity');

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('returns the ANDROID_ID from the platform channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'androidId');
            return 'abc123';
          });

      expect(await const AndroidDeviceIdentity().id(), 'abc123');
    });

    test('a null or empty ANDROID_ID is unavailable', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
      await expectLater(
        const AndroidDeviceIdentity().id(),
        throwsA(isA<DeviceIdentityUnavailable>()),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => '');
      await expectLater(
        const AndroidDeviceIdentity().id(),
        throwsA(isA<DeviceIdentityUnavailable>()),
      );
    });

    test('a missing plugin implementation is unavailable', () async {
      // No handler set: the messenger answers with MissingPluginException.
      await expectLater(
        const AndroidDeviceIdentity().id(),
        throwsA(isA<DeviceIdentityUnavailable>()),
      );
    });
  });
}
