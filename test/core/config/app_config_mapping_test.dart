import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/config/app_config.dart';

void main() {
  test('reads the live guest app config columns', () {
    final config = AppConfig.fromJson(const {
      'min_build_guest_android': 1,
      'min_build_guest_ios': 2,
      'support_phone': null,
      'guest_terms_version': '1',
    });

    expect(config.minSupportedBuildAndroid, 1);
    expect(config.minSupportedBuildIos, 2);
    expect(config.supportPhone, '');
    expect(config.currentTermsVersion, '1');
  });
}
