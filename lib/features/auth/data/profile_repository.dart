import 'package:on_air/features/auth/domain/account_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class ProfileRecord {
  const ProfileRecord({
    this.status = AccountStatus.incomplete,
    this.authProviders = const {},
    this.hasPassword = true,
    this.fullName,
    this.phone,
    this.phoneVerified = false,
    this.email,
    this.emailVerified = false,
    this.acceptedTermsVersion,
    this.acceptedTermsAt,
  });

  /// `common_get_my_context` (contracts/supabase-auth.md A4). A missing
  /// payload falls back to the incomplete default; an unrecognized status
  /// stays `unknown` (forward-compatible).
  factory ProfileRecord.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProfileRecord();
    return ProfileRecord(
      status: AccountStatus.fromJson(json['profile_status'] as String?),
      authProviders:
          ((json['auth_providers'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<String>()
              .map(AuthProvider.fromJson)
              .whereType<AuthProvider>()
              .toSet(),
      hasPassword: json['has_password'] as bool? ?? true,
      fullName: json['full_name'] as String?,
      phone: json['phone_e164'] as String?,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      email: json['email'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      acceptedTermsVersion: json['accepted_terms_version'] as String?,
      acceptedTermsAt: json['accepted_terms_at'] == null
          ? null
          : DateTime.parse(json['accepted_terms_at'] as String).toUtc(),
    );
  }

  final AccountStatus status;
  final Set<AuthProvider> authProviders;
  final bool hasPassword;
  final String? fullName;
  final String? phone;
  final bool phoneVerified;
  final String? email;
  final bool emailVerified;
  final String? acceptedTermsVersion;
  final DateTime? acceptedTermsAt;
}

abstract interface class ProfileSource {
  Future<ProfileRecord> loadOwnProfile(String userId);
}

final class ProfileRepository implements ProfileSource {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ProfileRecord> loadOwnProfile(String userId) async {
    // The server-owned context decides completeness, providers and the
    // password flag (A4); the profiles table is no longer read directly.
    final row = await _client.rpc<dynamic>('common_get_my_context');
    return ProfileRecord.fromJson(row as Map<String, dynamic>?);
  }
}
