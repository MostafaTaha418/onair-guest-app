import 'package:on_air/core/auth/profile_gate.dart';
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
    'CANCELLATION_TERMS_CHANGED': (
      ErrorCode.cancellationTermsChanged,
      'cancellationTermsChanged',
    ),
    'REMAINING_NOT_PAID': (
      ErrorCode.remainingNotPaid,
      'stayRemainingNotPaid',
    ),
    'CASH_NOT_ALLOWED': (ErrorCode.cashNotAllowed, 'stayCashNotAllowed'),
    'CASH_AMOUNT_CHANGED': (
      ErrorCode.cashAmountChanged,
      'stayCashAmountChanged',
    ),
    'CLAIM_ALREADY_ANSWERED': (
      ErrorCode.claimAlreadyAnswered,
      'claimAlreadyAnswered',
    ),
    'OFFER_NOT_AVAILABLE': (
      ErrorCode.offerNotAvailable,
      'offerNotAvailable',
    ),
    'PROFILE_ALREADY_COMPLETE': (
      ErrorCode.profileAlreadyComplete,
      'authProfileIncomplete',
    ),
    'OTP_SEND_BLOCKED': (ErrorCode.otpSendBlocked, 'otpBlockedUntil'),
    'PHONE_NOT_ON_WHATSAPP': (
      ErrorCode.phoneNotOnWhatsApp,
      'whatsappNotOnWhatsApp',
    ),
    'APP_ATTESTATION_FAILED': (
      ErrorCode.appAttestationFailed,
      'otpAttestationFailed',
    ),
    'OTP_TEMPORARILY_UNAVAILABLE': (
      ErrorCode.otpTemporarilyUnavailable,
      'otpTemporarilyUnavailable',
    ),
    'OTP_SUPERSEDED': (ErrorCode.otpSuperseded, 'whatsappUseLatestCode'),
    'OTP_ATTEMPTS_EXCEEDED': (
      ErrorCode.otpAttemptsExceeded,
      'otpAttemptsExceeded',
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
    // The server is the gate's authority: these two codes mean the session's
    // account state changed, so AuthCubit re-reads it and the router can
    // redirect (research R9).
    if (mapping.$1 == ErrorCode.profileIncomplete ||
        mapping.$1 == ErrorCode.phoneNotVerified) {
      ProfileGate.notify();
    }
    return ApiError(
      code: mapping.$1,
      messageKey: mapping.$2,
      requestId: requestId,
      details: details,
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
