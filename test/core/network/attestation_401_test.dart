import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/network/dio_factory.dart';

/// Review fix 2: a 401 whose body carries a known code is that code — the
/// App Check failure must reach the «أكّد رقمك» notice, not trigger a token
/// refresh loop. A bare 401 keeps the refresh + retry + UNAUTHENTICATED path.
final class _Tokens implements SessionTokenSource {
  String token = 'old';
  int refreshes = 0;

  @override
  Future<String?> currentToken() async => token;

  @override
  Future<String?> refreshToken() async {
    refreshes++;
    return token = 'new';
  }
}

final class _Adapter implements HttpClientAdapter {
  _Adapter(this.bodies);

  final List<String> bodies;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      bodies.length > 1 ? bodies.removeAt(0) : bodies.first,
      401,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'a 401 APP_ATTESTATION_FAILED maps to the attestation code with no retry',
    () async {
      final tokens = _Tokens();
      const attestationBody =
          '{"error":{"code":"APP_ATTESTATION_FAILED",'
          '"message_key":"otp.attestation_failed","request_id":"req_a"}}';
      final adapter = _Adapter([attestationBody]);
      final dio = createNodeDio(
        baseUrl: 'https://api.example.invalid',
        tokens: tokens,
      )..httpClientAdapter = adapter;

      await expectLater(
        dio.post<void>('/v1/otp/send', data: <String, dynamic>{}),
        throwsA(
          isA<DioException>().having(
            (error) => error.error,
            'error',
            isA<ApiError>().having(
              (error) => error.code,
              'code',
              ErrorCode.appAttestationFailed,
            ),
          ),
        ),
      );

      expect(tokens.refreshes, 0, reason: 'no refresh for an app failure');
      expect(adapter.requests, hasLength(1), reason: 'no retry');
    },
  );

  test(
    'a bare 401 still refreshes, retries, and ends UNAUTHENTICATED',
    () async {
      final tokens = _Tokens();
      const firstBody =
          '{"error":{"code":"UNAUTHENTICATED",'
          '"message_key":"error.unauthenticated","request_id":"req_1"}}';
      const secondBody =
          '{"error":{"code":"UNAUTHENTICATED",'
          '"message_key":"error.unauthenticated","request_id":"req_2"}}';
      final adapter = _Adapter([firstBody, secondBody]);
      final dio = createNodeDio(
        baseUrl: 'https://api.example.invalid',
        tokens: tokens,
      )..httpClientAdapter = adapter;

      await expectLater(
        dio.post<void>('/v1/otp/send', data: <String, dynamic>{}),
        throwsA(
          isA<DioException>().having(
            (error) => error.error,
            'error',
            isA<ApiError>().having(
              (error) => error.code,
              'code',
              ErrorCode.unauthenticated,
            ),
          ),
        ),
      );

      expect(tokens.refreshes, 1, reason: 'the session token was stale');
      expect(adapter.requests, hasLength(2), reason: 'one retry after refresh');
    },
  );
}
