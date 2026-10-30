import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));

  ApiError errorOf(ErrorCode code) =>
      ApiError(code: code, messageKey: 'unused', requestId: 'request-1');

  test('network maps to the no-connection message', () {
    expect(
      apiErrorMessage(errorOf(ErrorCode.network), l10n),
      l10n.errorNoConnection,
    );
  });

  test('notFound and propertyNotAvailable share the neutral message', () {
    expect(
      apiErrorMessage(errorOf(ErrorCode.notFound), l10n),
      l10n.propertyNotAvailable,
    );
    expect(
      apiErrorMessage(errorOf(ErrorCode.propertyNotAvailable), l10n),
      l10n.propertyNotAvailable,
    );
  });

  test('validationFailed maps to the validation message', () {
    expect(
      apiErrorMessage(errorOf(ErrorCode.validationFailed), l10n),
      l10n.errorValidationFailed,
    );
  });

  test('internal uses the message without an inline reference', () {
    // ErrorView renders the reference number separately.
    expect(
      apiErrorMessage(errorOf(ErrorCode.internal), l10n),
      l10n.errorUnexpectedNoRef,
    );
  });

  test('any other code falls back to the unexpected-error message', () {
    expect(
      apiErrorMessage(errorOf(ErrorCode.unauthenticated), l10n),
      l10n.errorUnexpectedNoRef,
    );
  });

  test('rate limited shows its own wait time (zero when absent)', () {
    // G2 gives the rate-limit code its own message; without server metadata
    // the wait renders as 0:00.
    expect(
      apiErrorMessage(errorOf(ErrorCode.rateLimited), l10n),
      l10n.authRateLimited('0:00'),
    );
  });
}
