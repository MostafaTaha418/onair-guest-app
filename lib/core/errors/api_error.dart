enum ErrorCode {
  unauthenticated,
  phoneCountryNotSupported,
  otpInvalid,
  otpExpired,
  rateLimited,
  validationFailed,
  termsChanged,
  profileIncomplete,
  profileAlreadyComplete,
  appVersionUnsupported,
  phoneNotVerified,
  emailNotVerified,
  datesUnavailable,
  guestsExceeded,
  quoteExpired,
  notFound,
  propertyNotAvailable,
  actionNotAllowed,
  collectorNotAuthorized,
  accountSuspended,
  phoneAlreadyUsed,
  policyOutOfBounds,
  conflict,
  invalidBookingState,
  duplicateOperation,
  paymentAmountMismatch,
  cancellationTermsChanged,
  remainingNotPaid,
  cashNotAllowed,
  cashAmountChanged,
  claimAlreadyAnswered,
  offerNotAvailable,
  otpSendBlocked,
  phoneNotOnWhatsApp,
  appAttestationFailed,
  otpTemporarilyUnavailable,
  otpSuperseded,
  otpAttemptsExceeded,
  internal,
  network,
  cancelled,
}

final class ApiError {
  const ApiError({
    required this.code,
    required this.messageKey,
    this.requestId,
    this.details,
    this.retryAfter,
  });

  final ErrorCode code;
  final String messageKey;
  final String? requestId;

  /// Server-provided payload (e.g. `next_send_at`, `blocked_until`) that the
  /// UI renders verbatim — the app never computes the ladder (Constitution II).
  final Map<String, dynamic>? details;
  final Duration? retryAfter;
}

final class AppFailure implements Exception {
  const AppFailure(this.error);

  final ApiError error;
}
