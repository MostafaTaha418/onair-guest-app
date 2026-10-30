// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Codes the Guest App can receive (Backend Master Plan §11; copy in error-codes.md).
/// Clients map unknown values to INTERNAL.
///
@JsonEnum()
enum ErrorCode {
  @JsonValue('UNAUTHENTICATED')
  unauthenticated('UNAUTHENTICATED'),
  @JsonValue('PERMISSION_DENIED')
  permissionDenied('PERMISSION_DENIED'),
  @JsonValue('ACCOUNT_SUSPENDED')
  accountSuspended('ACCOUNT_SUSPENDED'),
  @JsonValue('VALIDATION_FAILED')
  validationFailed('VALIDATION_FAILED'),
  @JsonValue('NOT_FOUND')
  notFound('NOT_FOUND'),
  @JsonValue('ACTION_NOT_ALLOWED')
  actionNotAllowed('ACTION_NOT_ALLOWED'),
  @JsonValue('RATE_LIMITED')
  rateLimited('RATE_LIMITED'),
  @JsonValue('CONFLICT')
  conflict('CONFLICT'),
  @JsonValue('APP_VERSION_UNSUPPORTED')
  appVersionUnsupported('APP_VERSION_UNSUPPORTED'),
  @JsonValue('INTERNAL')
  internal('INTERNAL'),
  @JsonValue('PHONE_COUNTRY_NOT_SUPPORTED')
  phoneCountryNotSupported('PHONE_COUNTRY_NOT_SUPPORTED'),
  @JsonValue('PHONE_ALREADY_USED')
  phoneAlreadyUsed('PHONE_ALREADY_USED'),
  @JsonValue('PHONE_NOT_VERIFIED')
  phoneNotVerified('PHONE_NOT_VERIFIED'),
  @JsonValue('EMAIL_NOT_VERIFIED')
  emailNotVerified('EMAIL_NOT_VERIFIED'),
  @JsonValue('OTP_INVALID')
  otpInvalid('OTP_INVALID'),
  @JsonValue('OTP_EXPIRED')
  otpExpired('OTP_EXPIRED'),
  @JsonValue('TERMS_CHANGED')
  termsChanged('TERMS_CHANGED'),
  @JsonValue('PROFILE_INCOMPLETE')
  profileIncomplete('PROFILE_INCOMPLETE'),
  @JsonValue('ACCOUNT_HAS_ACTIVE_BOOKINGS')
  accountHasActiveBookings('ACCOUNT_HAS_ACTIVE_BOOKINGS'),
  @JsonValue('PROPERTY_NOT_AVAILABLE')
  propertyNotAvailable('PROPERTY_NOT_AVAILABLE'),
  @JsonValue('DATES_UNAVAILABLE')
  datesUnavailable('DATES_UNAVAILABLE'),
  @JsonValue('GUESTS_EXCEEDED')
  guestsExceeded('GUESTS_EXCEEDED'),
  @JsonValue('QUOTE_EXPIRED')
  quoteExpired('QUOTE_EXPIRED'),
  @JsonValue('INVALID_BOOKING_STATE')
  invalidBookingState('INVALID_BOOKING_STATE'),
  @JsonValue('REMAINING_NOT_PAID')
  remainingNotPaid('REMAINING_NOT_PAID'),
  @JsonValue('CANCELLATION_TERMS_CHANGED')
  cancellationTermsChanged('CANCELLATION_TERMS_CHANGED'),
  @JsonValue('REVIEW_NOT_ALLOWED')
  reviewNotAllowed('REVIEW_NOT_ALLOWED'),
  @JsonValue('PAYMENT_AMOUNT_MISMATCH')
  paymentAmountMismatch('PAYMENT_AMOUNT_MISMATCH'),
  @JsonValue('COLLECTOR_NOT_AUTHORIZED')
  collectorNotAuthorized('COLLECTOR_NOT_AUTHORIZED'),
  @JsonValue('CASH_NOT_ALLOWED')
  cashNotAllowed('CASH_NOT_ALLOWED'),
  @JsonValue('DUPLICATE_OPERATION')
  duplicateOperation('DUPLICATE_OPERATION'),

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
