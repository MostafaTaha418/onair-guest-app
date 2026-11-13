import 'package:on_air/design_system/components/social_sign_in_button.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';

export 'package:on_air/design_system/components/social_sign_in_button.dart'
    show SocialProvider;

/// Thrown when the guest closes the native sign-in sheet: no message, no
/// error state (FR-005).
final class SocialSignInCancelled implements Exception {
  const SocialSignInCancelled();
}

/// Thrown when the platform or provider cannot offer social sign-in (e.g.
/// Apple on Android, a missing Google configuration).
final class SocialSignInUnavailable implements Exception {
  const SocialSignInUnavailable();
}

final class SocialSignInResult {
  const SocialSignInResult({required this.account, this.providerFullName});

  final GuestAccount account;

  /// The Google display name, or the Apple first-authorization name. Held in
  /// memory only to pre-fill «أكّد رقمك»; never persisted.
  final String? providerFullName;
}

/// The native sign-in sheet's output. Memory only: it must never be logged
/// or persisted (Constitution IV) — the ID token goes straight to
/// `signInWithIdToken`.
final class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.idToken,
    this.accessToken,
    this.rawNonce,
    this.displayName,
    this.givenName,
    this.familyName,
  });

  final SocialProvider provider;

  /// The OpenID Connect ID token for `signInWithIdToken`.
  final String idToken;

  /// Google only, when the SDK provides one.
  final String? accessToken;

  /// Apple only: the raw nonce whose SHA-256 was sent to Apple.
  final String? rawNonce;

  /// Google display name (Apple splits it below).
  final String? displayName;
  final String? givenName;
  final String? familyName;
}
