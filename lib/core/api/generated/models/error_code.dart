// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// See error-codes.md. Clients map unknown values to INTERNAL.
@JsonEnum()
enum ErrorCode {
  @JsonValue('UNAUTHENTICATED')
  unauthenticated('UNAUTHENTICATED'),
  @JsonValue('PHONE_NOT_VERIFIED')
  phoneNotVerified('PHONE_NOT_VERIFIED'),
  @JsonValue('EMAIL_NOT_VERIFIED')
  emailNotVerified('EMAIL_NOT_VERIFIED'),
  @JsonValue('PHONE_COUNTRY_NOT_SUPPORTED')
  phoneCountryNotSupported('PHONE_COUNTRY_NOT_SUPPORTED'),
  @JsonValue('PROFILE_INCOMPLETE')
  profileIncomplete('PROFILE_INCOMPLETE'),
  @JsonValue('DATES_UNAVAILABLE')
  datesUnavailable('DATES_UNAVAILABLE'),
  @JsonValue('GUESTS_EXCEEDED')
  guestsExceeded('GUESTS_EXCEEDED'),
  @JsonValue('QUOTE_EXPIRED')
  quoteExpired('QUOTE_EXPIRED'),
  @JsonValue('TERMS_CHANGED')
  termsChanged('TERMS_CHANGED'),
  @JsonValue('PROPERTY_NOT_AVAILABLE')
  propertyNotAvailable('PROPERTY_NOT_AVAILABLE'),
  @JsonValue('ACTION_NOT_ALLOWED')
  actionNotAllowed('ACTION_NOT_ALLOWED'),
  @JsonValue('RATE_LIMITED')
  rateLimited('RATE_LIMITED'),
  @JsonValue('OTP_INVALID')
  otpInvalid('OTP_INVALID'),
  @JsonValue('OTP_EXPIRED')
  otpExpired('OTP_EXPIRED'),
  @JsonValue('COLLECTOR_NOT_AUTHORIZED')
  collectorNotAuthorized('COLLECTOR_NOT_AUTHORIZED'),
  @JsonValue('APP_VERSION_UNSUPPORTED')
  appVersionUnsupported('APP_VERSION_UNSUPPORTED'),
  @JsonValue('VALIDATION_FAILED')
  validationFailed('VALIDATION_FAILED'),
  @JsonValue('INTERNAL')
  internal('INTERNAL'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ErrorCode(this.json);

  factory ErrorCode.fromJson(String json) => values.firstWhere(
    (e) => e.json == json,
    orElse: () => $unknown,
  );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<ErrorCode> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
