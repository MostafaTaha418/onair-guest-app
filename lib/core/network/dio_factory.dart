import 'package:dio/dio.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:uuid/uuid.dart';

abstract interface class SessionTokenSource {
  Future<String?> currentToken();
  Future<String?> refreshToken();
}

Dio createNodeDio({
  required String baseUrl,
  required SessionTokenSource tokens,
}) {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null || uri.scheme != 'https') {
    throw ArgumentError.value(baseUrl, 'baseUrl', 'HTTPS required');
  }
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  dio.interceptors.addAll([
    RequestIdInterceptor(),
    AuthInterceptor(tokens),
    RefreshRetryInterceptor(dio, tokens),
    ErrorInterceptor(),
  ]);
  return dio;
}

final class RequestIdInterceptor extends Interceptor {
  static const _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('x-request-id', _uuid.v4);
    handler.next(options);
  }
}

final class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens);

  final SessionTokenSource _tokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.currentToken();
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

final class RefreshRetryInterceptor extends Interceptor {
  RefreshRetryInterceptor(this._dio, this._tokens);

  final Dio _dio;
  final SessionTokenSource _tokens;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['authRetried'] == true) {
      handler.next(err);
      return;
    }
    try {
      final token = await _tokens.refreshToken();
      if (token == null) {
        handler.next(err);
        return;
      }
      final original = err.requestOptions;
      final retry = original.copyWith(
        headers: {...original.headers, 'Authorization': 'Bearer $token'},
        extra: {...original.extra, 'authRetried': true},
      );
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

final class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiError) {
      handler.next(err);
      return;
    }
    final response = err.response;
    final data = response?.data;
    final body = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final mapped = switch (err.type) {
      DioExceptionType.cancel => const ApiError(
        code: ErrorCode.cancelled,
        messageKey: 'errorCancelled',
      ),
      _ when response == null => ErrorMapper.noResponse(),
      _ => ErrorMapper.fromCode(
        response.statusCode == 401 ? 'UNAUTHENTICATED' : '${body['code']}',
        requestId:
            body['request_id'] as String? ??
            response.headers.value('x-request-id'),
        details: body['details'] is Map<String, dynamic>
            ? body['details'] as Map<String, dynamic>
            : null,
        retryAfterHeader: response.headers.value('retry-after'),
      ),
    };
    handler.next(err.copyWith(error: mapped));
  }
}
