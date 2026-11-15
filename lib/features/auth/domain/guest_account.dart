import 'package:flutter/foundation.dart';
import 'package:on_air/features/auth/domain/account_enums.dart';

@immutable
final class GuestAccount {
  GuestAccount({
    required this.id,
    required this.status,
    this.phone,
    this.phoneVerified = false,
    this.email,
    this.emailVerified = false,
    String? fullName,
    this.authProviders = const {},
    this.hasPassword = true,
    this.acceptedTermsVersion,
    this.acceptedTermsAt,
  }) : fullName = fullName?.trim(),
       // The email is always set for real accounts (server context); it stays
       // nullable only for legacy test fixtures.
       assert(
         status != AccountStatus.active || phone != null,
         'active account without phone',
       ) {
    if (phone != null && !RegExp(r'^\+201[0125]\d{8}$').hasMatch(phone!)) {
      throw ArgumentError.value(phone, 'phone');
    }
    if (this.fullName != null &&
        (this.fullName!.length < 2 || this.fullName!.length > 80)) {
      throw ArgumentError.value(fullName, 'fullName');
    }
  }

  final String id;

  /// Server completeness state (`profiles.status`): only [AccountStatus.active]
  /// accounts are usable (S005).
  final AccountStatus status;
  final String? phone;
  final bool phoneVerified;

  /// Always set for real accounts; nullable only for legacy tests.
  final String? email;
  final bool emailVerified;
  final String? fullName;
  final Set<AuthProvider> authProviders;
  final bool hasPassword;
  final String? acceptedTermsVersion;
  final DateTime? acceptedTermsAt;

  /// The server owns completeness (Constitution II): no local name/terms
  /// computation any more.
  bool get isComplete => status == AccountStatus.active;

  /// Only an explicitly `incomplete` account is onboarding into «أكّد رقمك».
  /// `suspended`/`deleted` keep the session but never see the step, and an
  /// `unknown` (forward-compatible) status routes like `active` — the server
  /// still enforces `PROFILE_INCOMPLETE` (review fix 6).
  bool get needsPhoneStep => status == AccountStatus.incomplete;
}
