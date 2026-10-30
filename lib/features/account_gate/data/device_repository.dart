import 'package:supabase_flutter/supabase_flutter.dart';

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
  const DeviceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
    required String locale,
  }) async {
    if (locale != 'ar' && locale != 'en') {
      throw ArgumentError.value(locale, 'locale', 'Must be ar or en');
    }
    await _client.rpc<void>(
      'common_register_device',
      params: {
        'p_token': token,
        'p_app': 'guest',
        'p_platform': platform.name,
        'p_locale': locale,
      },
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await _client.rpc<void>(
      'common_unregister_device',
      params: {'p_token': token},
    );
  }
}
