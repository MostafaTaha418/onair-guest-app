// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'device_registration_locale.dart';
import 'device_registration_platform.dart';

part 'device_registration.freezed.dart';
part 'device_registration.g.dart';

@Freezed()
abstract class DeviceRegistration with _$DeviceRegistration {
  const factory DeviceRegistration({
    required String token,
    required DeviceRegistrationPlatform platform,
    required DeviceRegistrationLocale locale,
  }) = _DeviceRegistration;

  factory DeviceRegistration.fromJson(Map<String, Object?> json) =>
      _$DeviceRegistrationFromJson(json);
}
