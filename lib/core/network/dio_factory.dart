import 'package:dio/dio.dart';
import 'package:on_air/core/device/app_attestation.dart';
import 'package:on_air/core/device/device_identity.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/network/otp_send_interceptor.dart';
import 'package:uuid/uuid.dart';

abstract interface class SessionTokenSource {
  Future<String?> currentToken();
  Future<String?> refreshToken();
}

Dio createNodeDio({
  required String baseUrl,
  required SessionTokenSource tokens,
  DeviceIdentity? deviceIdentity,
  AppAttestation? attestation,
}) {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null || uri.scheme != 'https') {
    throw ArgumentError.value(baseUrl, 'baseUrl', 'HTTPS required');
  }
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  dio.interceptors.addAll([
    RequestIdInterceptor(),
    AuthInterceptor(tokens),
    if (deviceIdentity != null && attestation != null)
      OtpSendInterceptor(
        deviceIdentity: deviceIdentity,
        attestation: attestation,
      ),
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
    // An app-level failure rides a 401 too (APP_ATTESTATION_FAILED): the
    // session is fine, so refreshing and replaying would loop (review
    // fix 2).
    final body = ErrorInterceptor.errorBodyOf(err.response?.data);
    if ('${body['code']}' == 'APP_ATTESTATION_FAILED') {
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
    final body = errorBodyOf(response?.data);
    final mapped = switch (err.type) {
      DioExceptionType.cancel => const ApiError(
        code: ErrorCode.cancelled,
        messageKey: 'errorCancelled',
      ),
      _ when response == null => ErrorMapper.noResponse(),
      // A 401 with a known code is that code (the App Check failure rides
      // one); only a bare 401 means the session ended (review fix 2).
      _ => ErrorMapper.fromCode(
        response.statusCode == 401 && !ErrorMapper.hasCode('${body['code']}')
            ? 'UNAUTHENTICATED'
            : '${body['code']}',
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

  /// Returns the inner object of the unified ErrorResponse
  /// (`{"error": {"code", "message_key", "request_id", "details"}}`,
  /// contracts/node-api.openapi.yaml). Anything else yields an empty map, so
  /// the code falls back to INTERNAL.
  static Map<String, dynamic> errorBodyOf(Object? data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) return error;
    }
    return const <String, dynamic>{};
  }
}
