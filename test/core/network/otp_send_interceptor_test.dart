import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/device/app_attestation.dart';
import 'package:on_air/core/device/device_identity.dart';
import 'package:on_air/core/network/otp_send_interceptor.dart';

final class _FakeIdentity implements DeviceIdentity {
  @override
  Future<String> id() async => 'dev-1';
}

final class _FakeAttestation implements AppAttestation {
  String? token = 'att-1';

  @override
  Future<String?> limitedUseToken() async => token;
}

/// Records every request and answers with an empty 200.
final class _CapturingAdapter implements HttpClientAdapter {
  final sent = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent.add(options);
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_CapturingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
    ..httpClientAdapter = adapter
    ..interceptors.add(
      OtpSendInterceptor(
        deviceIdentity: _FakeIdentity(),
        attestation: _FakeAttestation(),
      ),
    );
  return dio;
}

void main() {
  test(
    'POST /v1/otp/send carries the device id and the App Check token',
    () async {
      final adapter = _CapturingAdapter();
      final dio = _dio(adapter);

      final response = await dio.post<void>(
        '/v1/otp/send',
        data: <String, dynamic>{},
      );

      expect(response.statusCode, 200);
      expect(adapter.sent.single.headers['X-Device-Id'], 'dev-1');
      expect(adapter.sent.single.headers['X-Firebase-AppCheck'], 'att-1');
    },
  );

  test('every other route goes out without the two headers', () async {
    final adapter = _CapturingAdapter();
    final dio = _dio(adapter);

    await dio.post<void>(
      '/v1/guest/bookings/start-payment',
      data: <String, dynamic>{},
    );
    await dio.get<void>('/v1/otp/send');

    for (final options in adapter.sent) {
      expect(
        options.headers.containsKey('X-Device-Id'),
        isFalse,
        reason: options.path,
      );
      expect(
        options.headers.containsKey('X-Firebase-AppCheck'),
        isFalse,
        reason: options.path,
      );
    }
    expect(adapter.sent, hasLength(2));
  });

  test('a null attestation token omits only its own header', () async {
    final adapter = _CapturingAdapter();

    final dioNoToken = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        OtpSendInterceptor(
          deviceIdentity: _FakeIdentity(),
          attestation: _FakeAttestation()..token = null,
        ),
      );

    final response = await dioNoToken.post<void>(
      '/v1/otp/send',
      data: <String, dynamic>{},
    );

    expect(response.statusCode, 200);
    expect(adapter.sent.single.headers['X-Device-Id'], 'dev-1');
    expect(
      adapter.sent.single.headers.containsKey('X-Firebase-AppCheck'),
      isFalse,
    );
  });
}
