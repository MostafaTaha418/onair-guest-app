import 'dart:convert';

final class EnvConfig {
  EnvConfig._({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.nodeApiBaseUrl,
    required this.linkDomain,
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
    if (key.contains('service_role') || _jwtRole(key) == 'service_role') {
      throw ArgumentError.value(
        '[redacted]',
        'SUPABASE_ANON_KEY',
        'Service role forbidden',
      );
    }
    final domain = requiredValue('LINK_DOMAIN');
    if (domain.contains('/') || domain.contains(':') || domain.contains(' ')) {
      throw ArgumentError.value(domain, 'LINK_DOMAIN');
    }
    return EnvConfig._(
      flavor: flavor,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: key,
      nodeApiBaseUrl: nodeApiBaseUrl,
      linkDomain: domain,
    );
  }

  factory EnvConfig.fromEnvironment() => EnvConfig.fromMap({
    'FLAVOR': const String.fromEnvironment('FLAVOR'),
    'SUPABASE_URL': const String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_ANON_KEY': const String.fromEnvironment('SUPABASE_ANON_KEY'),
    'NODE_API_BASE_URL': const String.fromEnvironment('NODE_API_BASE_URL'),
    'LINK_DOMAIN': const String.fromEnvironment('LINK_DOMAIN'),
  });

  final String flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String nodeApiBaseUrl;
  final String linkDomain;

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
