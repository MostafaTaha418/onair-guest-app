import 'package:on_air/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AppConfigSource {
  Future<AppConfig> load({bool refresh = false});
  void clearCache();
}

final class AppConfigRepository implements AppConfigSource {
  AppConfigRepository(this._client);

  final SupabaseClient _client;
  AppConfig? _cached;

  @override
  Future<AppConfig> load({bool refresh = false}) async {
    if (!refresh && _cached != null) return _cached!;
    final row = await _client
        .from('app_config')
        .select(
          'min_supported_build_android,min_supported_build_ios,'
          'support_phone,current_terms_version',
        )
        .limit(1)
        .single();
    return _cached = AppConfig.fromJson(row);
  }

  @override
  void clearCache() => _cached = null;
}
