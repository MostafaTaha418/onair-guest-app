import 'package:dio/dio.dart';
import 'package:on_air/core/device/app_attestation.dart';
import 'package:on_air/core/device/device_identity.dart';

/// Adds the abuse-protection headers to the WhatsApp OTP send route only
/// (research R3/R4, data-model §6): `X-Device-Id` and the limited-use
/// `X-Firebase-AppCheck` token. Every other route is untouched.
final class OtpSendInterceptor extends Interceptor {
  OtpSendInterceptor({
    required this._deviceIdentity,
    required this._attestation,
  });

  final DeviceIdentity _deviceIdentity;
  final AppAttestation _attestation;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method == 'POST' && options.path.endsWith('/v1/otp/send')) {
      try {
        options.headers['X-Device-Id'] = await _deviceIdentity.id();
      } on DeviceIdentityUnavailable {
        // The request still goes out; the server applies its own limits.
      }
      final token = await _attestation.limitedUseToken();
      if (token != null) {
        options.headers['X-Firebase-AppCheck'] = token;
      }
    }
    handler.next(options);
  }
}
