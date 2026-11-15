import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/auth/data/social_credential_source.dart';

void main() {
  group('generateRawNonce (T038)', () {
    test('is unpadded URL-safe base64 of 32 secure-random bytes', () {
      final raw = generateRawNonce();

      // 32 bytes → 43 unpadded base64Url characters.
      expect(raw, hasLength(43));
      expect(raw, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
      expect(base64Url.decode(base64Url.normalize(raw)), hasLength(32));
    });

    test('two calls never repeat', () {
      final seen = {for (var i = 0; i < 25; i++) generateRawNonce()};
      expect(seen, hasLength(25));
    });
  });

  group('sha256Hex (T038)', () {
    test('matches the known SHA-256 of a fixed input', () {
      // The expected value is computed here with the same `crypto` package
      // the app uses, then compared against the helper under test.
      const input = 'on-air-apple-nonce';
      final expected = sha256.convert(utf8.encode(input)).toString();
      expect(sha256Hex(input), expected);
    });

    test('is the 64-char digest Apple verifies against the raw nonce', () {
      final raw = generateRawNonce();
      expect(sha256Hex(raw).length, 64);
      expect(sha256Hex(raw), isNot(sha256Hex('$raw ')));
    });
  });
}
