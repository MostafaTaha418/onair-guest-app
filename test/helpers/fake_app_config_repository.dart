import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';

final class FakeAppConfigRepository implements AppConfigSource {
  FakeAppConfigRepository(this.config);
  AppConfig config;
  int loadCount = 0;

  /// When set, `load` throws this instead of serving the config — the
  /// offline-config scenarios (review fix 9).
  Exception? loadError;
  @override
  Future<AppConfig> load({bool refresh = false}) async {
    loadCount++;
    if (loadError case final error?) throw error;
    return config;
  }

  @override
  void clearCache() {
    loadCount = 0;
  }
}
