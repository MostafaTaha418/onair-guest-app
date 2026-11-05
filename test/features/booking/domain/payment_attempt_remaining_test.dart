import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/booking/domain/payment_attempt.dart';

void main() {
  final startedAt = DateTime.utc(2026, 11, 1, 10);

  test('remaining factory creates a remaining attempt', () {
    final attempt = PaymentAttempt.remaining(
      attemptKey: 'k',
      bookingId: 'b',
      startedAt: startedAt,
    );

    expect(attempt.kind, PaymentKind.remaining);
    expect(attempt.quoteId, isEmpty);
    expect(attempt.propertyId, isEmpty);
    expect(attempt.termsHash, isEmpty);
    expect(attempt.paymentId, isNull);
  });

  test('remaining attempt round trips through json', () {
    final attempt = PaymentAttempt.remaining(
      attemptKey: 'k',
      bookingId: 'b',
      startedAt: startedAt,
    );

    expect(attempt.toJson()['kind'], 'remaining');
    expect(PaymentAttempt.fromJson(attempt.toJson()), attempt);
  });

  test('legacy json without kind parses as initial', () {
    final attempt = PaymentAttempt.fromJson({
      'attempt_key': '11111111-2222-4333-8444-555555555555',
      'quote_id': '22222222-3333-4444-8555-666666666666',
      'property_id': '00000000-0000-4000-8000-00000000001f',
      'terms_hash': 'mock-terms-1',
      'booking_id': null,
      'payment_url': null,
      'payment_url_expires_at': null,
      'started_at': startedAt.toIso8601String(),
    });

    expect(attempt.kind, PaymentKind.initial);
  });

  test('copyWith payment id keeps remaining kind', () {
    final attempt = PaymentAttempt.remaining(
      attemptKey: 'k',
      bookingId: 'b',
      startedAt: startedAt,
    ).copyWith(paymentId: 'p');

    expect(attempt.kind, PaymentKind.remaining);
    expect(attempt.paymentId, 'p');
  });
}
