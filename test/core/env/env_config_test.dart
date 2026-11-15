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

  test('accepts publishable keys and rejects backend secret keys', () {
    expect(
      EnvConfig.fromMap(
        values(
          'sb_'
          'publishable_testPublicKey123',
        ),
      ).flavor,
      'staging',
    );
    expect(
      () => EnvConfig.fromMap(
        values(
          'sb_'
          'secret_testBackendKey123',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('backend mode defaults to remote and accepts mock on staging', () {
    expect(EnvConfig.fromMap(values(anon)).backendMode, BackendMode.remote);
    expect(
      EnvConfig.fromMap(values(anon)..['BACKEND_MODE'] = 'mock').backendMode,
      BackendMode.mock,
    );
  });

  test('mock backend is rejected in production and unknown modes fail', () {
    expect(
      () => EnvConfig.fromMap(
        values(anon)
          ..['FLAVOR'] = 'production'
          ..['BACKEND_MODE'] = 'mock',
      ),
      throwsArgumentError,
    );
    expect(
      () => EnvConfig.fromMap(values(anon)..['BACKEND_MODE'] = 'fake'),
      throwsArgumentError,
    );
  });

  test('google client ids are optional and nullable when missing', () {
    final config = EnvConfig.fromMap(values(anon));
    expect(config.googleServerClientId, isNull);
    expect(config.googleIosClientId, isNull);
  });

  test('empty google client ids become null', () {
    final config = EnvConfig.fromMap(
      values(anon)
        ..['GOOGLE_SERVER_CLIENT_ID'] = '   '
        ..['GOOGLE_IOS_CLIENT_ID'] = '',
    );
    expect(config.googleServerClientId, isNull);
    expect(config.googleIosClientId, isNull);
  });

  test('google client id values are kept when provided', () {
    final config = EnvConfig.fromMap(
      values(anon)
        ..['GOOGLE_SERVER_CLIENT_ID'] = '1234.apps.googleusercontent.com'
        ..['GOOGLE_IOS_CLIENT_ID'] = '5678.apps.googleusercontent.com',
    );
    expect(config.googleServerClientId, '1234.apps.googleusercontent.com');
    expect(config.googleIosClientId, '5678.apps.googleusercontent.com');
  });

  test('google client ids must not contain a secret', () {
    expect(
      () => EnvConfig.fromMap(
        values(anon)..['GOOGLE_SERVER_CLIENT_ID'] = 'GOCSPX-SecretValue',
      ),
      throwsArgumentError,
    );
    expect(
      () => EnvConfig.fromMap(
        values(anon)
          ..['GOOGLE_IOS_CLIENT_ID'] = 'SECRET.apps.googleusercontent.com',
      ),
      throwsArgumentError,
    );
  });
}
