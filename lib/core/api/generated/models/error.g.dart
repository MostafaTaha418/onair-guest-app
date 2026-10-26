// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Error _$ErrorFromJson(Map<String, dynamic> json) => _Error(
  code: ErrorCode.fromJson(json['code'] as String),
  messageKey: json['message_key'] as String,
  requestId: json['request_id'] as String,
  details: json['details'] == null
      ? null
      : Details.fromJson(json['details'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ErrorToJson(_Error instance) => <String, dynamic>{
  'code': _$ErrorCodeEnumMap[instance.code]!,
  'message_key': instance.messageKey,
  'request_id': instance.requestId,
  'details': instance.details,
};

const _$ErrorCodeEnumMap = {
  ErrorCode.unauthenticated: 'UNAUTHENTICATED',
  ErrorCode.phoneNotVerified: 'PHONE_NOT_VERIFIED',
  ErrorCode.emailNotVerified: 'EMAIL_NOT_VERIFIED',
  ErrorCode.phoneCountryNotSupported: 'PHONE_COUNTRY_NOT_SUPPORTED',
  ErrorCode.profileIncomplete: 'PROFILE_INCOMPLETE',
  ErrorCode.datesUnavailable: 'DATES_UNAVAILABLE',
  ErrorCode.guestsExceeded: 'GUESTS_EXCEEDED',
  ErrorCode.quoteExpired: 'QUOTE_EXPIRED',
  ErrorCode.termsChanged: 'TERMS_CHANGED',
  ErrorCode.propertyNotAvailable: 'PROPERTY_NOT_AVAILABLE',
  ErrorCode.actionNotAllowed: 'ACTION_NOT_ALLOWED',
  ErrorCode.rateLimited: 'RATE_LIMITED',
  ErrorCode.otpInvalid: 'OTP_INVALID',
  ErrorCode.otpExpired: 'OTP_EXPIRED',
  ErrorCode.collectorNotAuthorized: 'COLLECTOR_NOT_AUTHORIZED',
  ErrorCode.appVersionUnsupported: 'APP_VERSION_UNSUPPORTED',
  ErrorCode.validationFailed: 'VALIDATION_FAILED',
  ErrorCode.internal: 'INTERNAL',
  ErrorCode.$unknown: r'$unknown',
};
