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
  ErrorCode.permissionDenied: 'PERMISSION_DENIED',
  ErrorCode.accountSuspended: 'ACCOUNT_SUSPENDED',
  ErrorCode.validationFailed: 'VALIDATION_FAILED',
  ErrorCode.notFound: 'NOT_FOUND',
  ErrorCode.actionNotAllowed: 'ACTION_NOT_ALLOWED',
  ErrorCode.rateLimited: 'RATE_LIMITED',
  ErrorCode.conflict: 'CONFLICT',
  ErrorCode.appVersionUnsupported: 'APP_VERSION_UNSUPPORTED',
  ErrorCode.internal: 'INTERNAL',
  ErrorCode.phoneCountryNotSupported: 'PHONE_COUNTRY_NOT_SUPPORTED',
  ErrorCode.phoneAlreadyUsed: 'PHONE_ALREADY_USED',
  ErrorCode.phoneNotVerified: 'PHONE_NOT_VERIFIED',
  ErrorCode.emailNotVerified: 'EMAIL_NOT_VERIFIED',
  ErrorCode.otpInvalid: 'OTP_INVALID',
  ErrorCode.otpExpired: 'OTP_EXPIRED',
  ErrorCode.termsChanged: 'TERMS_CHANGED',
  ErrorCode.profileIncomplete: 'PROFILE_INCOMPLETE',
  ErrorCode.accountHasActiveBookings: 'ACCOUNT_HAS_ACTIVE_BOOKINGS',
  ErrorCode.propertyNotAvailable: 'PROPERTY_NOT_AVAILABLE',
  ErrorCode.datesUnavailable: 'DATES_UNAVAILABLE',
  ErrorCode.guestsExceeded: 'GUESTS_EXCEEDED',
  ErrorCode.quoteExpired: 'QUOTE_EXPIRED',
  ErrorCode.invalidBookingState: 'INVALID_BOOKING_STATE',
  ErrorCode.remainingNotPaid: 'REMAINING_NOT_PAID',
  ErrorCode.cancellationTermsChanged: 'CANCELLATION_TERMS_CHANGED',
  ErrorCode.reviewNotAllowed: 'REVIEW_NOT_ALLOWED',
  ErrorCode.paymentAmountMismatch: 'PAYMENT_AMOUNT_MISMATCH',
  ErrorCode.collectorNotAuthorized: 'COLLECTOR_NOT_AUTHORIZED',
  ErrorCode.cashNotAllowed: 'CASH_NOT_ALLOWED',
  ErrorCode.duplicateOperation: 'DUPLICATE_OPERATION',
  ErrorCode.$unknown: r'$unknown',
};
