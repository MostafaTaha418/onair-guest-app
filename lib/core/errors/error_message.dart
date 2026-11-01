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
