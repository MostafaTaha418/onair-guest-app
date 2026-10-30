import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  ApiError errorOf(String code) => ErrorMapper.fromCode(code);

  test('maps the G2 codes to their enum and message key', () {
    final cases = <String, (ErrorCode, String)>{
      'ACCOUNT_SUSPENDED': (
        ErrorCode.accountSuspended,
        'errorAccountSuspended',
      ),
      'PHONE_ALREADY_USED': (
        ErrorCode.phoneAlreadyUsed,
        'authPhoneAlreadyUsed',
      ),
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
    };
    for (final entry in cases.entries) {
      final error = errorOf(entry.key);
      expect(error.code, entry.value.$1, reason: entry.key);
      expect(error.messageKey, entry.value.$2, reason: entry.key);
      expect(ErrorMapper.hasCode(entry.key), isTrue, reason: entry.key);
    }
  });

  test('every G2 message key returns its own Arabic sentence', () {
    final cases = <ErrorCode, String Function()>{
      ErrorCode.accountSuspended: () => l10n.errorAccountSuspended,
      ErrorCode.phoneAlreadyUsed: () => l10n.authPhoneAlreadyUsed,
      ErrorCode.policyOutOfBounds: () => l10n.bookingPolicyOutOfBounds,
      ErrorCode.conflict: () => l10n.errorConflict,
      ErrorCode.invalidBookingState: () => l10n.bookingStateChanged,
      ErrorCode.duplicateOperation: () => l10n.errorDuplicateOperation,
      ErrorCode.paymentAmountMismatch: () => l10n.paymentVerificationIssue,
      ErrorCode.phoneNotVerified: () => l10n.bookingPhoneNotVerified,
      ErrorCode.emailNotVerified: () => l10n.bookingEmailNotVerified,
      ErrorCode.datesUnavailable: () => l10n.bookingDatesUnavailable,
      ErrorCode.guestsExceeded: () => l10n.bookingGuestsExceeded,
      ErrorCode.quoteExpired: () => l10n.bookingQuoteExpired,
      ErrorCode.termsChanged: () => l10n.authTermsChanged,
      ErrorCode.otpInvalid: () => l10n.authOtpInvalid,
      ErrorCode.otpExpired: () => l10n.authOtpExpired,
      ErrorCode.actionNotAllowed: () => l10n.errorActionNotAllowed,
    };
    for (final entry in cases.entries) {
      expect(
        apiErrorMessage(ApiError(code: entry.key, messageKey: ''), l10n),
        entry.value.call(),
        reason: entry.key.name,
      );
    }
  });

  test('rate limited shows the wait time as m:ss', () {
    const error = ApiError(
      code: ErrorCode.rateLimited,
      messageKey: 'authRateLimited',
      retryAfter: Duration(seconds: 90),
    );
    expect(apiErrorMessage(error, l10n), l10n.authRateLimited('1:30'));
  });

  test('existing messages keep their behaviour', () {
    expect(
      apiErrorMessage(
        const ApiError(code: ErrorCode.network, messageKey: ''),
        l10n,
      ),
      l10n.errorNoConnection,
    );
    expect(
      apiErrorMessage(
        const ApiError(code: ErrorCode.notFound, messageKey: ''),
        l10n,
      ),
      l10n.propertyNotAvailable,
    );
    expect(
      apiErrorMessage(
        const ApiError(code: ErrorCode.propertyNotAvailable, messageKey: ''),
        l10n,
      ),
      l10n.propertyNotAvailable,
    );
    expect(
      apiErrorMessage(
        const ApiError(code: ErrorCode.validationFailed, messageKey: ''),
        l10n,
      ),
      l10n.errorValidationFailed,
    );
  });
}
