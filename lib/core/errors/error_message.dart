import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The user-facing message for an [ApiError].
///
/// Each code renders its own localized sentence; the rate-limit wait is
/// appended as `m:ss` (90 s → «1:30»). Everything unmapped is an unexpected
/// error whose reference number `ErrorView` renders separately.
String apiErrorMessage(ApiError error, AppLocalizations l10n) =>
    switch (error.code) {
      ErrorCode.network => l10n.errorNoConnection,
      ErrorCode.notFound ||
      ErrorCode.propertyNotAvailable => l10n.propertyNotAvailable,
      ErrorCode.validationFailed => l10n.errorValidationFailed,
      ErrorCode.accountSuspended => l10n.errorAccountSuspended,
      ErrorCode.phoneAlreadyUsed => l10n.authPhoneAlreadyUsed,
      ErrorCode.policyOutOfBounds => l10n.bookingPolicyOutOfBounds,
      ErrorCode.conflict => l10n.errorConflict,
      ErrorCode.invalidBookingState => l10n.bookingStateChanged,
      ErrorCode.duplicateOperation => l10n.errorDuplicateOperation,
      ErrorCode.paymentAmountMismatch => l10n.paymentVerificationIssue,
      ErrorCode.phoneNotVerified => l10n.bookingPhoneNotVerified,
      ErrorCode.emailNotVerified => l10n.bookingEmailNotVerified,
      ErrorCode.datesUnavailable => l10n.bookingDatesUnavailable,
      ErrorCode.guestsExceeded => l10n.bookingGuestsExceeded,
      ErrorCode.quoteExpired => l10n.bookingQuoteExpired,
      ErrorCode.termsChanged => l10n.authTermsChanged,
      ErrorCode.otpInvalid => l10n.authOtpInvalid,
      ErrorCode.otpExpired => l10n.authOtpExpired,
      ErrorCode.phoneCountryNotSupported => l10n.authPhoneCountryNotSupported,
      ErrorCode.actionNotAllowed => l10n.errorActionNotAllowed,
      ErrorCode.collectorNotAuthorized => l10n.stayCollectorNotAuthorized,
      ErrorCode.cancellationTermsChanged => l10n.cancellationTermsChanged,
      ErrorCode.remainingNotPaid => l10n.stayRemainingNotPaid,
      ErrorCode.cashNotAllowed => l10n.stayCashNotAllowed,
      ErrorCode.cashAmountChanged => l10n.stayCashAmountChanged,
      ErrorCode.claimAlreadyAnswered => l10n.claimAlreadyAnswered,
      ErrorCode.offerNotAvailable => l10n.offerNotAvailable,
      ErrorCode.rateLimited => l10n.authRateLimited(
        _waitText(error.retryAfter),
      ),
      _ => l10n.errorUnexpectedNoRef,
    };

String _waitText(Duration? retryAfter) {
  final totalSeconds = retryAfter?.inSeconds ?? 0;
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// The user-facing message for an error `messageKey` riding a UI state (the
/// «أكّد رقمك» steps carry a key, not an [ApiError]). Covers every key
/// `ErrorMapper` can return plus the local validation keys; unknown keys
/// fall back to the no-reference unexpected text.
///
/// [requestId] renders with `errorUnexpected` when the server sent one
/// (Constitution VIII).
String localizedErrorText(
  String key,
  AppLocalizations l10n, {
  String? requestId,
}) => switch (key) {
  'errorUnauthenticated' => l10n.errorUnauthenticated,
  'authPhoneCountryNotSupported' => l10n.authPhoneCountryNotSupported,
  'authOtpInvalid' => l10n.authOtpInvalid,
  'authOtpExpired' => l10n.authOtpExpired,
  'authRateLimited' => l10n.authRateLimited(_waitText(null)),
  'errorValidationFailed' => l10n.errorValidationFailed,
  'authTermsChanged' => l10n.authTermsChanged,
  'authProfileIncomplete' => l10n.authProfileIncomplete,
  'appUpdateRequired' => l10n.appUpdateRequired,
  'bookingPhoneNotVerified' => l10n.bookingPhoneNotVerified,
  'bookingEmailNotVerified' => l10n.bookingEmailNotVerified,
  'bookingDatesUnavailable' => l10n.bookingDatesUnavailable,
  'bookingGuestsExceeded' => l10n.bookingGuestsExceeded,
  'bookingQuoteExpired' => l10n.bookingQuoteExpired,
  'propertyNotAvailable' => l10n.propertyNotAvailable,
  'errorActionNotAllowed' => l10n.errorActionNotAllowed,
  'stayCollectorNotAuthorized' => l10n.stayCollectorNotAuthorized,
  'errorAccountSuspended' => l10n.errorAccountSuspended,
  'authPhoneAlreadyUsed' => l10n.authPhoneAlreadyUsed,
  'bookingPolicyOutOfBounds' => l10n.bookingPolicyOutOfBounds,
  'errorConflict' => l10n.errorConflict,
  'bookingStateChanged' => l10n.bookingStateChanged,
  'errorDuplicateOperation' => l10n.errorDuplicateOperation,
  'paymentVerificationIssue' => l10n.paymentVerificationIssue,
  'cancellationTermsChanged' => l10n.cancellationTermsChanged,
  'stayRemainingNotPaid' => l10n.stayRemainingNotPaid,
  'stayCashNotAllowed' => l10n.stayCashNotAllowed,
  'stayCashAmountChanged' => l10n.stayCashAmountChanged,
  'claimAlreadyAnswered' => l10n.claimAlreadyAnswered,
  'offerNotAvailable' => l10n.offerNotAvailable,
  // The block date rides the state only when the server sent one; the
  // malformed-payload fallback renders without one (Constitution II).
  'otpBlockedUntil' => l10n.otpBlockedUntil('—'),
  'whatsappNotOnWhatsApp' => l10n.whatsappNotOnWhatsApp,
  'otpAttestationFailed' => l10n.otpAttestationFailed,
  'otpTemporarilyUnavailable' => l10n.otpTemporarilyUnavailable,
  'whatsappUseLatestCode' => l10n.whatsappUseLatestCode,
  'otpAttemptsExceeded' => l10n.otpAttemptsExceeded,
  'errorNoConnection' => l10n.errorNoConnection,
  'errorUnexpectedNoRef' => l10n.errorUnexpectedNoRef,
  // Local validation keys the cubit sets on the steps.
  'authFieldRequired' => l10n.authFieldRequired,
  'authNameInvalid' => l10n.authNameInvalid,
  'authPhoneInvalid' => l10n.authPhoneInvalid,
  // `INTERNAL` rides this key; the reference number appears when the server
  // sent one (Constitution VIII).
  'errorUnexpected' =>
    requestId == null
        ? l10n.errorUnexpectedNoRef
        : l10n.errorUnexpected(requestId),
  _ => l10n.errorUnexpectedNoRef,
};
