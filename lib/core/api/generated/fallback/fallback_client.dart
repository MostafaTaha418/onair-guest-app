// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/device_registration.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  /// Register or refresh this device's push token for the signed-in user
  @POST('/v1/devices')
  Future<void> registerDeviceToken({
    @Header('x-request-id') required String xRequestId,
    @Body() required DeviceRegistration body,
  });

  /// Remove this device's push token for the signed-in user (called at sign-out)
  @DELETE('/v1/devices/{token}')
  Future<void> unregisterDeviceToken({
    @Header('x-request-id') required String xRequestId,
    @Path('token') required String token,
  });
}
