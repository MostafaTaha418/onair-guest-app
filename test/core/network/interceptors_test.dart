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
  _Adapter(this.statuses);

  final List<int> statuses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final status = statuses.removeAt(0);
    return ResponseBody.fromString(
      status == 200 ? '{}' : '{"code":"UNAUTHENTICATED"}',
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
