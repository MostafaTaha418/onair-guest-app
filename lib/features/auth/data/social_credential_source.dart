import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:on_air/features/auth/domain/social_identity.dart';

/// Produces the native social credentials for `signInWithIdToken`
/// (research R1/R2). The credential is memory-only.
abstract interface class SocialCredentialSource {
  Future<SocialCredential> google();
  Future<SocialCredential> apple();
}

final class GoogleAppleCredentialSource implements SocialCredentialSource {
  GoogleAppleCredentialSource({this.serverClientId, this.iosClientId});

  /// The Web client ID (the token audience Supabase validates); required on
  /// Android, optional on iOS where [iosClientId] takes over.
  final String? serverClientId;
  final String? iosClientId;

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? iosClientId
          : null,
    );
    _initialized = true;
  }

  @override
  Future<SocialCredential> google() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        // The server cannot validate the sign-in without the ID token.
        throw StateError('Google sign-in returned no ID token');
      }
      return SocialCredential(
        provider: SocialProvider.google,
        idToken: idToken,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialSignInCancelled();
      }
      rethrow;
    }
  }

  // US2 (T039) fills this in with the Apple nonce flow.
  @override
  Future<SocialCredential> apple() async =>
      throw const SocialSignInUnavailable();
}
