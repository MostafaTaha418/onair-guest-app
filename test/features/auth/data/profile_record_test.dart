import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/auth/data/profile_repository.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';

void main() {
  test('parses the full common_get_my_context payload (data-model §1)', () {
    final record = ProfileRecord.fromJson(const {
      'profile_status': 'active',
      'auth_providers': ['email', 'google'],
      'has_password': false,
      'email': 'guest@example.com',
      'email_verified': true,
      'full_name': 'Guest Name',
      'phone_e164': '+201012345678',
      'phone_verified': true,
      'accepted_terms_version': 'v1',
      'accepted_terms_at': '2026-11-01T10:00:00Z',
    });

    expect(record.status, AccountStatus.active);
    expect(record.authProviders, {AuthProvider.email, AuthProvider.google});
    expect(record.hasPassword, isFalse);
    expect(record.email, 'guest@example.com');
    expect(record.emailVerified, isTrue);
    expect(record.fullName, 'Guest Name');
    expect(record.phone, '+201012345678');
    expect(record.phoneVerified, isTrue);
    expect(record.acceptedTermsVersion, 'v1');
    expect(record.acceptedTermsAt, DateTime.utc(2026, 11, 1, 10));
  });

  test('unknown providers are ignored', () {
    final record = ProfileRecord.fromJson(const {
      'profile_status': 'active',
      'auth_providers': ['google', 'something_new'],
    });
    expect(record.authProviders, {AuthProvider.google});
  });

  test('missing optional fields fall back to an unknown account', () {
    final record = ProfileRecord.fromJson(null);

    // Only an explicit 'incomplete' enters «أكّد رقمك» (review fix 6); a
    // missing payload or field is unknown — the server decides.
    expect(record.status, AccountStatus.unknown);
    expect(record.authProviders, isEmpty);
    expect(record.hasPassword, isTrue);
    expect(record.email, isNull);
    expect(record.emailVerified, isFalse);
    expect(record.fullName, isNull);
    expect(record.phone, isNull);
    expect(record.phoneVerified, isFalse);
    expect(record.acceptedTermsVersion, isNull);
    expect(record.acceptedTermsAt, isNull);
  });
}
