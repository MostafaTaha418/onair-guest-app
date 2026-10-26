// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_registration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceRegistration _$DeviceRegistrationFromJson(Map<String, dynamic> json) =>
    _DeviceRegistration(
      token: json['token'] as String,
      platform: DeviceRegistrationPlatform.fromJson(json['platform'] as String),
      locale: DeviceRegistrationLocale.fromJson(json['locale'] as String),
    );

Map<String, dynamic> _$DeviceRegistrationToJson(_DeviceRegistration instance) =>
    <String, dynamic>{
      'token': instance.token,
      'platform': _$DeviceRegistrationPlatformEnumMap[instance.platform]!,
      'locale': _$DeviceRegistrationLocaleEnumMap[instance.locale]!,
    };

const _$DeviceRegistrationPlatformEnumMap = {
  DeviceRegistrationPlatform.android: 'android',
  DeviceRegistrationPlatform.ios: 'ios',
  DeviceRegistrationPlatform.$unknown: r'$unknown',
};

const _$DeviceRegistrationLocaleEnumMap = {
  DeviceRegistrationLocale.ar: 'ar',
  DeviceRegistrationLocale.en: 'en',
  DeviceRegistrationLocale.$unknown: r'$unknown',
};
