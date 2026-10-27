import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/network/dio_factory.dart';

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
  _Adapter(this.statuses, {this.errorBody});

  final List<int> statuses;
  final String? errorBody;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final status = statuses.removeAt(0);
    // Unified ErrorResponse from contracts/node-api.openapi.yaml.
    return ResponseBody.fromString(
      status == 200
          ? '{}'
          : errorBody ??
                '{"error":{"code":"UNAUTHENTICATED",'
                    '"message_key":"error.unauthenticated",'
                    '"request_id":"req_401"}}',
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('adds UUID v4 and bearer token; refreshes and retries one 401', () async {
    final tokens = _Tokens();
    final adapter = _Adapter([401, 200]);
    final dio = createNodeDio(
      baseUrl: 'https://api.example.invalid',
      tokens: tokens,
    )..httpClientAdapter = adapter;
    await dio.get<Map<String, dynamic>>('/ping');
    expect(tokens.refreshes, 1);
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.headers['Authorization'], 'Bearer old');
    expect(adapter.requests.last.headers['Authorization'], 'Bearer new');
    expect(
      adapter.requests.first.headers['x-request-id'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(
      adapter.requests.last.headers['x-request-id'],
      adapter.requests.first.headers['x-request-id'],
    );
  });

  test('second 401 surfaces UNAUTHENTICATED without another refresh', () async {
    final tokens = _Tokens();
    final adapter = _Adapter([401, 401]);
    final dio = createNodeDio(
      baseUrl: 'https://api.example.invalid',
      tokens: tokens,
    )..httpClientAdapter = adapter;
    await expectLater(
      dio.get<Map<String, dynamic>>('/ping'),
      throwsA(
        isA<DioException>().having(
          (e) => (e.error! as ApiError).code,
          'code',
          ErrorCode.unauthenticated,
        ),
      ),
    );
    expect(tokens.refreshes, 1);
  });

  test(
    'reads code, request id, and retry from the nested error body',
    () async {
      final adapter = _Adapter(
        [429],
        errorBody:
            '{"error":{"code":"RATE_LIMITED","message_key":"auth.rate_limited",'
            '"request_id":"req_123","details":{"retry_after_seconds":30}}}',
      );
      final dio = createNodeDio(
        baseUrl: 'https://api.example.invalid',
        tokens: _Tokens(),
      )..httpClientAdapter = adapter;
      await expectLater(
        dio.get<Map<String, dynamic>>('/ping'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error! as ApiError,
            'error',
            isA<ApiError>()
                .having((e) => e.code, 'code', ErrorCode.rateLimited)
                .having((e) => e.requestId, 'requestId', 'req_123')
                .having(
                  (e) => e.retryAfter,
                  'retryAfter',
                  const Duration(seconds: 30),
                ),
          ),
        ),
      );
    },
  );

  test('maps a business error code from the nested body', () async {
    final adapter = _Adapter(
      [409],
      errorBody:
          '{"error":{"code":"QUOTE_EXPIRED","message_key":"booking.quote_expired",'
          '"request_id":"req_409"}}',
    );
    final dio = createNodeDio(
      baseUrl: 'https://api.example.invalid',
      tokens: _Tokens(),
    )..httpClientAdapter = adapter;
    await expectLater(
      dio.get<Map<String, dynamic>>('/ping'),
      throwsA(
        isA<DioException>().having(
          (e) => (e.error! as ApiError).code,
          'code',
          ErrorCode.quoteExpired,
        ),
      ),
    );
  });

  test('server error body becomes ApiError', () async {
    final adapter = _Adapter([422]);
    final dio = createNodeDio(
      baseUrl: 'https://api.example.invalid',
      tokens: _Tokens(),
    )..httpClientAdapter = adapter;
    await expectLater(
      dio.get<Map<String, dynamic>>('/ping'),
      throwsA(
        isA<DioException>().having((e) => e.error, 'error', isA<ApiError>()),
      ),
    );
  });
}
