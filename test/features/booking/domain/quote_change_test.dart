import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/domain/quote_change.dart';

BookingQuote _quote({
  String quoteId = 'q1',
  int nightlyMinor = 150000,
  int totalMinor = 450000,
  int payNowMinor = 112500,
  int remainingMinor = 337500,
  DateTime? remainingDueAt,
  String termsHash = 'terms-1',
  DateTime? expiresAt,
}) => BookingQuote(
  quoteId: quoteId,
  propertyId: '00000000-0000-4000-8000-00000000001f',
  stay: StayRange(DateOnly.parse('2026-11-20'), DateOnly.parse('2026-11-23')),
  nights: 3,
  guests: 2,
  nightly: Money(nightlyMinor),
  total: Money(totalMinor),
  payNow: Money(payNowMinor),
  remaining: Money(remainingMinor),
  remainingDueAt: remainingDueAt,
  termsHash: termsHash,
  policySummary: null,
  expiresAt: expiresAt ?? DateTime.utc(2026, 11, 1, 10, 15),
);

void main() {
  test('identical amounts, dates, and terms have no changes', () {
    final change = QuoteChange.between(_quote(), _quote(quoteId: 'q2'));
    expect(change.hasChanges, isFalse);
    expect(change.changedFields, isEmpty);
  });

  test('each money field difference is reported on its own', () {
    expect(
      QuoteChange.between(
        _quote(),
        _quote(nightlyMinor: 160000),
      ).changedFields,
      {QuoteField.nightly},
    );
    expect(
      QuoteChange.between(_quote(), _quote(totalMinor: 480000)).changedFields,
      {QuoteField.total},
    );
    expect(
      QuoteChange.between(_quote(), _quote(payNowMinor: 120000)).changedFields,
      {QuoteField.payNow},
    );
    expect(
      QuoteChange.between(
        _quote(),
        _quote(remainingMinor: 360000),
      ).changedFields,
      {QuoteField.remaining},
    );
  });

  test('the due date and the terms hash are compared too', () {
    expect(
      QuoteChange.between(
        _quote(),
        _quote(remainingDueAt: DateTime.utc(2026, 11, 19, 20)),
      ).changedFields,
      {QuoteField.remainingDueAt},
    );
    expect(
      QuoteChange.between(_quote(), _quote(termsHash: 'terms-2')).changedFields,
      {QuoteField.termsHash},
    );
  });

  test('a new quote id or expiry alone is not a change', () {
    final change = QuoteChange.between(
      _quote(),
      _quote(
        quoteId: 'q2',
        expiresAt: DateTime.utc(2026, 11, 1, 10, 30),
      ),
    );
    expect(change.hasChanges, isFalse);
  });
}
