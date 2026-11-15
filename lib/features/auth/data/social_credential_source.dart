import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:on_air/features/auth/domain/social_identity.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// A fresh one-time nonce for Apple: 32 secure-random bytes as unpadded
/// base64Url (research R2). The SHA-256 hash goes to Apple; the raw value is
/// kept in memory only and sent to Supabase with the ID token.
String generateRawNonce() {
  final bytes = List<int>.generate(
    32,
    (_) => Random.secure().nextInt(256),
    growable: false,
  );
  return base64Url.encode(bytes).replaceAll('=', '');
}

String sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();

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

  @override
  Future<SocialCredential> apple() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      throw const SocialSignInUnavailable();
    }
    final raw = generateRawNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Hex(raw),
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        // The server cannot validate the sign-in without the identity token.
        throw StateError('Apple sign-in returned no identity token');
      }
      return SocialCredential(
        provider: SocialProvider.apple,
        idToken: idToken,
        rawNonce: raw,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const SocialSignInCancelled();
      }
      rethrow;
    }
  }
}
