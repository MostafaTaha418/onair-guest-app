import 'package:supabase_flutter/supabase_flutter.dart';

final class ProfileRecord {
  const ProfileRecord({
    this.fullName,
    this.phone,
    this.phoneVerified = false,
    this.acceptedTermsVersion,
    this.acceptedTermsAt,
  });

  factory ProfileRecord.fromJson(Map<String, dynamic>? json) => ProfileRecord(
    fullName: json?['full_name'] as String?,
    phone: json?['phone_e164'] as String?,
    phoneVerified: json?['phone_verified_at'] != null,
    acceptedTermsVersion: json?['accepted_terms_version'] as String?,
    acceptedTermsAt: json?['accepted_terms_at'] == null
        ? null
        : DateTime.parse(json!['accepted_terms_at'] as String).toUtc(),
  );

  final String? fullName;
  final String? phone;
  final bool phoneVerified;
  final String? acceptedTermsVersion;
  final DateTime? acceptedTermsAt;
}

abstract interface class ProfileSource {
  Future<ProfileRecord> loadOwnProfile(String userId);
  Future<ProfileRecord> completeProfile(String name, String termsVersion);
}

final class ProfileRepository implements ProfileSource {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'full_name,phone_e164,phone_verified_at,'
      'accepted_terms_version,accepted_terms_at';

  @override
  Future<ProfileRecord> loadOwnProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select(_columns)
        .eq('id', userId)
        .maybeSingle();
    return ProfileRecord.fromJson(row);
  }

  @override
  Future<ProfileRecord> completeProfile(
    String name,
    String termsVersion,
  ) async {
    final row = await _client
        .rpc<dynamic>(
          'complete_guest_profile',
          params: {'full_name': name.trim(), 'terms_version': termsVersion},
        )
        .single();
    return ProfileRecord.fromJson(row);
  }
}
