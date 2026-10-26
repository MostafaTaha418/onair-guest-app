import 'package:on_air/core/api/generated/fallback/fallback_client.dart';
import 'package:on_air/core/api/generated/models/device_registration.dart';
import 'package:on_air/core/api/generated/models/device_registration_locale.dart';
import 'package:on_air/core/api/generated/models/device_registration_platform.dart';
import 'package:uuid/uuid.dart';

enum DevicePlatform { android, ios }

abstract interface class DeviceTokenRepository {
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
    required String locale,
  });

  Future<void> unregisterDeviceToken(String token);
}

final class DeviceRepository implements DeviceTokenRepository {
  DeviceRepository(this._client, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final FallbackClient _client;
  final Uuid _uuid;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
    required String locale,
  }) => _client.registerDeviceToken(
    xRequestId: _uuid.v4(),
    body: DeviceRegistration(
      token: token,
      platform: switch (platform) {
        DevicePlatform.android => DeviceRegistrationPlatform.android,
        DevicePlatform.ios => DeviceRegistrationPlatform.ios,
      },
      locale: switch (locale) {
        'ar' => DeviceRegistrationLocale.ar,
        'en' => DeviceRegistrationLocale.en,
        _ => throw ArgumentError.value(locale, 'locale', 'Must be ar or en'),
      },
    ),
  );

  @override
  Future<void> unregisterDeviceToken(String token) =>
      _client.unregisterDeviceToken(xRequestId: _uuid.v4(), token: token);
}
