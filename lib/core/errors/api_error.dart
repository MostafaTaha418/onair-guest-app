enum ErrorCode {
  unauthenticated,
  phoneCountryNotSupported,
  otpInvalid,
  otpExpired,
  rateLimited,
  validationFailed,
  termsChanged,
  profileIncomplete,
  appVersionUnsupported,
  phoneNotVerified,
  emailNotVerified,
  datesUnavailable,
  guestsExceeded,
  quoteExpired,
  propertyNotAvailable,
  actionNotAllowed,
  collectorNotAuthorized,
  internal,
  network,
  cancelled,
}

final class ApiError {
  const ApiError({
    required this.code,
    required this.messageKey,
    this.requestId,
    this.retryAfter,
  });

  final ErrorCode code;
  final String messageKey;
  final String? requestId;
  final Duration? retryAfter;
}

final class AppFailure {
  const AppFailure(this.error);

  final ApiError error;
}
