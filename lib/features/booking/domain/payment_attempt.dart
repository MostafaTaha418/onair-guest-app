import 'package:flutter/foundation.dart';

/// The open payment attempt (data-model §4). One record exists at a time,
/// keyed `payment_attempt.current` in secure storage; it is saved before the
/// first start request and deleted only on a final outcome, sign-out, or
/// "Try again".
@immutable
final class PaymentAttempt {
  const PaymentAttempt({
    required this.attemptKey,
    required this.quoteId,
    required this.propertyId,
    required this.termsHash,
    required this.startedAt,
    this.bookingId,
    this.paymentUrl,
    this.paymentUrlExpiresAt,
  });

  factory PaymentAttempt.fromJson(Map<String, dynamic> json) => PaymentAttempt(
    attemptKey: json['attempt_key'] as String,
    quoteId: json['quote_id'] as String,
    propertyId: json['property_id'] as String,
    termsHash: json['terms_hash'] as String,
    bookingId: json['booking_id'] as String?,
    paymentUrl: json['payment_url'] as String?,
    paymentUrlExpiresAt: json['payment_url_expires_at'] == null
        ? null
        : DateTime.parse(json['payment_url_expires_at'] as String),
    startedAt: DateTime.parse(json['started_at'] as String),
  );

  final String attemptKey;
  final String quoteId;
  final String propertyId;
  final String termsHash;
  final String? bookingId;
  final String? paymentUrl;
  final DateTime? paymentUrlExpiresAt;
  final DateTime startedAt;

  PaymentAttempt copyWith({
    String? bookingId,
    String? paymentUrl,
    DateTime? paymentUrlExpiresAt,
  }) => PaymentAttempt(
    attemptKey: attemptKey,
    quoteId: quoteId,
    propertyId: propertyId,
    termsHash: termsHash,
    startedAt: startedAt,
    bookingId: bookingId ?? this.bookingId,
    paymentUrl: paymentUrl ?? this.paymentUrl,
    paymentUrlExpiresAt: paymentUrlExpiresAt ?? this.paymentUrlExpiresAt,
  );

  Map<String, dynamic> toJson() => {
    'attempt_key': attemptKey,
    'quote_id': quoteId,
    'property_id': propertyId,
    'terms_hash': termsHash,
    'booking_id': bookingId,
    'payment_url': paymentUrl,
    'payment_url_expires_at': paymentUrlExpiresAt?.toIso8601String(),
    'started_at': startedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is PaymentAttempt &&
      other.attemptKey == attemptKey &&
      other.quoteId == quoteId &&
      other.propertyId == propertyId &&
      other.termsHash == termsHash &&
      other.bookingId == bookingId &&
      other.paymentUrl == paymentUrl &&
      other.paymentUrlExpiresAt == paymentUrlExpiresAt &&
      other.startedAt == startedAt;

  @override
  int get hashCode => Object.hash(
    attemptKey,
    quoteId,
    propertyId,
    termsHash,
    bookingId,
    paymentUrl,
    paymentUrlExpiresAt,
    startedAt,
  );
}
