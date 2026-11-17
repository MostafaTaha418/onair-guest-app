import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/network/dio_factory.dart';
import 'package:on_air/core/network/user_agent.dart';

class _Tokens implements SessionTokenSource {
  @override
  Future<String?> currentToken() async => null;
  @override
  Future<String?> refreshToken() async => null;
}

void main() {
  test('builds the documented Android and iOS user agents', () async {
    for (final device in [
      const UserAgentDevice(
        platform: 'android',
        osVersion: '14',
        model: 'SM-A546',
      ),
      const UserAgentDevice(
        platform: 'ios',
        osVersion: '18.1',
        model: 'iPhone',
      ),
    ]) {
      final value = await UserAgentBuilder(
        loadVersion: () async => '1.2.3',
        loadDevice: () async => device,
      ).build();
      expect(
        value,
        'OnAirGuest/1.2.3 (${device.platform} ${device.osVersion}; ${device.model})',
      );
    }
  });

  test('Dio sends the supplied user agent header', () {
    final dio = createNodeDio(
      baseUrl: 'https://api.onair.test',
      tokens: _Tokens(),
      userAgent: 'OnAirGuest/1.0.0 (android 14; Pixel 8)',
    );
    expect(
      dio.options.headers['User-Agent'],
      'OnAirGuest/1.0.0 (android 14; Pixel 8)',
    );
  });
}
