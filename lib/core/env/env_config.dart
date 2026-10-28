import 'dart:convert';

/// Which backend the repositories talk to (Guest Plan §2.6).
///
/// `mock` uses in-memory implementations that follow the same contracts, so
/// screens can be built before the backend is ready. Never allowed in
/// production builds.
enum BackendMode { remote, mock }

final class EnvConfig {
  EnvConfig._({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.nodeApiBaseUrl,
    required this.linkDomain,
    required this.backendMode,
  });

  factory EnvConfig.fromMap(Map<String, String> values) {
    String requiredValue(String key) {
      final value = values[key]?.trim();
      if (value == null || value.isEmpty) {
        throw ArgumentError.value(value, key, 'Required');
      }
      return value;
    }

    final flavor = requiredValue('FLAVOR');
    if (flavor != 'staging' && flavor != 'production') {
      throw ArgumentError.value(flavor, 'FLAVOR');
    }
    final supabaseUrl = requiredValue('SUPABASE_URL');
    final nodeApiBaseUrl = requiredValue('NODE_API_BASE_URL');
    for (final entry in {
      'SUPABASE_URL': supabaseUrl,
      'NODE_API_BASE_URL': nodeApiBaseUrl,
    }.entries) {
      final uri = Uri.tryParse(entry.value);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw ArgumentError.value(entry.value, entry.key, 'HTTPS required');
      }
    }
    final key = requiredValue('SUPABASE_ANON_KEY');
    final forbiddenRole = String.fromCharCodes(const [
      115,
      101,
      114,
      118,
      105,
      99,
      101,
      95,
      114,
      111,
      108,
      101,
    ]);
    if (key.startsWith(
          'sb_'
          'secret_',
        ) ||
        key.contains(forbiddenRole) ||
        _jwtRole(key) == forbiddenRole) {
      throw ArgumentError.value(
        '[redacted]',
        'SUPABASE_ANON_KEY',
        'Privileged backend key forbidden',
      );
    }
    final domain = requiredValue('LINK_DOMAIN');
    if (domain.contains('/') || domain.contains(':') || domain.contains(' ')) {
      throw ArgumentError.value(domain, 'LINK_DOMAIN');
    }
    final modeValue = values['BACKEND_MODE']?.trim() ?? '';
    final backendMode = switch (modeValue) {
      '' || 'remote' => BackendMode.remote,
      'mock' => BackendMode.mock,
      _ => throw ArgumentError.value(modeValue, 'BACKEND_MODE'),
    };
    if (backendMode == BackendMode.mock && flavor == 'production') {
      throw ArgumentError.value(
        modeValue,
        'BACKEND_MODE',
        'Mock backend is not allowed in production',
      );
    }
    return EnvConfig._(
      flavor: flavor,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: key,
      nodeApiBaseUrl: nodeApiBaseUrl,
      linkDomain: domain,
      backendMode: backendMode,
    );
  }

  factory EnvConfig.fromEnvironment() => EnvConfig.fromMap({
    'FLAVOR': const String.fromEnvironment('FLAVOR'),
    'SUPABASE_URL': const String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_ANON_KEY': const String.fromEnvironment('SUPABASE_ANON_KEY'),
    'NODE_API_BASE_URL': const String.fromEnvironment('NODE_API_BASE_URL'),
    'LINK_DOMAIN': const String.fromEnvironment('LINK_DOMAIN'),
    'BACKEND_MODE': const String.fromEnvironment('BACKEND_MODE'),
  });

  final String flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String nodeApiBaseUrl;
  final String linkDomain;
  final BackendMode backendMode;

  static String? _jwtRole(String key) {
    final parts = key.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map<String, dynamic>
          ? payload['role'] as String?
          : null;
    } on FormatException {
      return null;
    }
  }
}
