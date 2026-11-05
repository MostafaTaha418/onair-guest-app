import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  const cases = <String, (ErrorCode, String)>{
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
    'COLLECTOR_NOT_AUTHORIZED': (
      ErrorCode.collectorNotAuthorized,
      'stayCollectorNotAuthorized',
    ),
  };

  test('maps every G3 error code', () {
    for (final entry in cases.entries) {
      final error = ErrorMapper.fromCode(entry.key);
      expect(error.code, entry.value.$1, reason: entry.key);
      expect(error.messageKey, entry.value.$2, reason: entry.key);
      expect(ErrorMapper.hasCode(entry.key), isTrue, reason: entry.key);
    }
  });

  group('apiErrorMessage', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    });

    test('uses the matching localized G3 message', () {
      final expected = <String, String>{
        'CANCELLATION_TERMS_CHANGED': l10n.cancellationTermsChanged,
        'REMAINING_NOT_PAID': l10n.stayRemainingNotPaid,
        'CASH_NOT_ALLOWED': l10n.stayCashNotAllowed,
        'CASH_AMOUNT_CHANGED': l10n.stayCashAmountChanged,
        'CLAIM_ALREADY_ANSWERED': l10n.claimAlreadyAnswered,
        'OFFER_NOT_AVAILABLE': l10n.offerNotAvailable,
        'COLLECTOR_NOT_AUTHORIZED': l10n.stayCollectorNotAuthorized,
      };
      for (final entry in expected.entries) {
        expect(
          apiErrorMessage(ErrorMapper.fromCode(entry.key), l10n),
          entry.value,
          reason: entry.key,
        );
      }
    });
  });
}
