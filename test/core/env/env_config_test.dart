import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/env/env_config.dart';

void main() {
  final anon =
      '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.'
      '${base64Url.encode(utf8.encode('{"role":"anon"}'))}.signature';
  final service =
      '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.'
      '${base64Url.encode(utf8.encode('{"role":"service_role"}'))}.signature';

  Map<String, String> values(String key) => {
    'FLAVOR': 'staging',
    'SUPABASE_URL': 'https://example.supabase.co',
    'SUPABASE_ANON_KEY': key,
    'NODE_API_BASE_URL': 'https://api.example.invalid',
    'LINK_DOMAIN': 'example.invalid',
  };

  test('requires every config key', () {
    expect(() => EnvConfig.fromMap({}), throwsArgumentError);
    expect(EnvConfig.fromMap(values(anon)).flavor, 'staging');
  });

  test('rejects non-HTTPS endpoints', () {
    expect(
      () => EnvConfig.fromMap(values(anon)..['SUPABASE_URL'] = 'http://x'),
      throwsArgumentError,
    );
    expect(
      () => EnvConfig.fromMap(values(anon)..['NODE_API_BASE_URL'] = 'http://x'),
      throwsArgumentError,
    );
  });

  test('rejects a service-role key', () {
    expect(() => EnvConfig.fromMap(values(service)), throwsArgumentError);
  });
}
