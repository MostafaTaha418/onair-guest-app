import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:on_air/core/storage/secure_store.dart';
import 'package:uuid/uuid.dart';

/// A reinstall-stable identifier for the OTP send-limit keys (research R4).
/// Never logged and sent only on `POST /v1/otp/send`.
abstract interface class DeviceIdentity {
  Future<String> id();
}

final class DeviceIdentityUnavailable implements Exception {
  const DeviceIdentityUnavailable();
}

/// iOS: a random UUID created once and kept in the Keychain under
/// `device_install_id` with `first_unlock_this_device`, so it survives
/// reinstalls (R4). The Keychain entry is never cleared by the app.
final class KeychainDeviceIdentity implements DeviceIdentity {
  KeychainDeviceIdentity({SecureStore? store})
    : _store =
          store ??
          FlutterSecureStore(
            storage: const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            ),
          );

  final SecureStore _store;

  static const _key = 'device_install_id';
  static final _uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  @override
  Future<String> id() async {
    final existing = await _store.read(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _store.write(_key, id);
    return id;
  }

  /// Exposed for tests: the value must always look like a fresh v4 UUID.
  static bool isUuidV4(String value) => _uuidV4.hasMatch(value);
}

/// Android: `ANDROID_ID` read live over the `on_air/device_identity`
/// channel; nothing is stored.
final class AndroidDeviceIdentity implements DeviceIdentity {
  const AndroidDeviceIdentity();

  static const _channel = MethodChannel('on_air/device_identity');

  @override
  Future<String> id() async {
    String? value;
    try {
      value = await _channel.invokeMethod<String>('androidId');
    } on MissingPluginException {
      throw const DeviceIdentityUnavailable();
    } on PlatformException {
      throw const DeviceIdentityUnavailable();
    }
    if (value == null || value.isEmpty) {
      throw const DeviceIdentityUnavailable();
    }
    return value;
  }
}

/// The platform default: the Keychain identity on iOS, the Android one
/// otherwise (R4).
DeviceIdentity platformDeviceIdentity({SecureStore? iosStore}) =>
    defaultTargetPlatform == TargetPlatform.iOS
    ? KeychainDeviceIdentity(store: iosStore)
    : const AndroidDeviceIdentity();
