import 'package:on_air/core/config/app_config.dart';
import 'package:on_air/core/config/app_config_repository.dart';

final class FakeAppConfigRepository implements AppConfigSource {
  FakeAppConfigRepository(this.config);
  AppConfig config;
  int loadCount = 0;
  @override
  Future<AppConfig> load({bool refresh = false}) async {
    loadCount++;
    return config;
  }

  @override
  void clearCache() {
    loadCount = 0;
  }
}
