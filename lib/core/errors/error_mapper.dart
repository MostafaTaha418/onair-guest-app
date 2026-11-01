import 'package:on_air/core/errors/api_error.dart';

abstract final class ErrorMapper {
  static const _keys = <String, (ErrorCode, String)>{
    'UNAUTHENTICATED': (ErrorCode.unauthenticated, 'errorUnauthenticated'),
    'PHONE_COUNTRY_NOT_SUPPORTED': (
      ErrorCode.phoneCountryNotSupported,
      'authPhoneCountryNotSupported',
    ),
    'OTP_INVALID': (ErrorCode.otpInvalid, 'authOtpInvalid'),
    'OTP_EXPIRED': (ErrorCode.otpExpired, 'authOtpExpired'),
    'RATE_LIMITED': (ErrorCode.rateLimited, 'authRateLimited'),
    'VALIDATION_FAILED': (ErrorCode.validationFailed, 'errorValidationFailed'),
    'TERMS_CHANGED': (ErrorCode.termsChanged, 'authTermsChanged'),
    'PROFILE_INCOMPLETE': (
      ErrorCode.profileIncomplete,
      'authProfileIncomplete',
    ),
    'APP_VERSION_UNSUPPORTED': (
      ErrorCode.appVersionUnsupported,
      'appUpdateRequired',
    ),
    'PHONE_NOT_VERIFIED': (
      ErrorCode.phoneNotVerified,
      'bookingPhoneNotVerified',
    ),
    'EMAIL_NOT_VERIFIED': (
      ErrorCode.emailNotVerified,
      'bookingEmailNotVerified',
    ),
    'DATES_UNAVAILABLE': (
      ErrorCode.datesUnavailable,
      'bookingDatesUnavailable',
    ),
    'GUESTS_EXCEEDED': (ErrorCode.guestsExceeded, 'bookingGuestsExceeded'),
    'QUOTE_EXPIRED': (ErrorCode.quoteExpired, 'bookingQuoteExpired'),
    'NOT_FOUND': (ErrorCode.notFound, 'propertyNotAvailable'),
    'PROPERTY_NOT_AVAILABLE': (
      ErrorCode.propertyNotAvailable,
      'propertyNotAvailable',
    ),
    'ACTION_NOT_ALLOWED': (ErrorCode.actionNotAllowed, 'errorActionNotAllowed'),
    'COLLECTOR_NOT_AUTHORIZED': (
      ErrorCode.collectorNotAuthorized,
      'stayCollectorNotAuthorized',
    ),
    'ACCOUNT_SUSPENDED': (ErrorCode.accountSuspended, 'errorAccountSuspended'),
    'PHONE_ALREADY_USED': (ErrorCode.phoneAlreadyUsed, 'authPhoneAlreadyUsed'),
    'POLICY_OUT_OF_BOUNDS': (
      ErrorCode.policyOutOfBounds,
      'bookingPolicyOutOfBounds',
    ),
    'CONFLICT': (ErrorCode.conflict, 'errorConflict'),
    'INVALID_BOOKING_STATE': (
      ErrorCode.invalidBookingState,
      'bookingStateChanged',
    ),
    'DUPLICATE_OPERATION': (
      ErrorCode.duplicateOperation,
      'errorDuplicateOperation',
    ),
    'PAYMENT_AMOUNT_MISMATCH': (
      ErrorCode.paymentAmountMismatch,
      'paymentVerificationIssue',
    ),
    'INTERNAL': (ErrorCode.internal, 'errorUnexpected'),
  };

  static ApiError fromCode(
    String code, {
    String? requestId,
    Map<String, dynamic>? details,
    String? retryAfterHeader,
  }) {
    final mapping = _keys[code] ?? _keys['INTERNAL']!;
    final seconds =
        _retrySeconds(details?['retry_after_seconds']) ??
        _retrySeconds(retryAfterHeader);
    return ApiError(
      code: mapping.$1,
      messageKey: mapping.$2,
      requestId: requestId,
      retryAfter: seconds == null ? null : Duration(seconds: seconds),
    );
  }

  static ApiError noResponse() => const ApiError(
    code: ErrorCode.network,
    messageKey: 'errorNoConnection',
  );

  /// Whether [code] has a mapping. Supabase raises every error as `P0001`
  /// with the real code in the message, so callers check before mapping.
  static bool hasCode(String code) => _keys.containsKey(code);

  static int? _retrySeconds(Object? value) {
    final parsed = int.tryParse('$value');
    return parsed == null || parsed < 0 ? null : parsed;
  }
}
