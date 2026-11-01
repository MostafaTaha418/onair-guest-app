import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/property_details.dart';

/// The server's priced answer for one apartment + dates + guests (data-model
/// §2). Every amount comes from the server; nothing is derived here.
@immutable
final class BookingQuote {
  const BookingQuote({
    required this.quoteId,
    required this.propertyId,
    required this.stay,
    required this.nights,
    required this.guests,
    required this.nightly,
    required this.total,
    required this.payNow,
    required this.remaining,
    required this.remainingDueAt,
    required this.termsHash,
    required this.policySummary,
    required this.expiresAt,
  });

  factory BookingQuote.fromJson(Map<String, dynamic> json) => BookingQuote(
    quoteId: json['quote_id'] as String,
    propertyId: json['property_id'] as String,
    stay: StayRange(
      DateOnly.parse(json['check_in'] as String),
      DateOnly.parse(json['check_out'] as String),
    ),
    nights: json['nights'] as int,
    guests: json['guests_count'] as int,
    nightly: Money(json['nightly_minor'] as int),
    total: Money(json['total_minor'] as int),
    payNow: Money(json['pay_now_minor'] as int),
    remaining: Money(json['remaining_minor'] as int),
    remainingDueAt: json['remaining_due_at'] == null
        ? null
        : DateTime.parse(json['remaining_due_at'] as String),
    termsHash: json['terms_hash'] as String,
    policySummary: json['policy_summary'] == null
        ? null
        : PolicySummary.fromJson(
            Map<String, dynamic>.from(json['policy_summary'] as Map),
          ),
    expiresAt: DateTime.parse(json['expires_at'] as String),
  );

  final String quoteId;
  final String propertyId;
  final StayRange stay;
  final int nights;
  final int guests;
  final Money nightly;
  final Money total;
  final Money payNow;
  final Money remaining;
  final DateTime? remainingDueAt;
  final String termsHash;
  final PolicySummary? policySummary;
  final DateTime expiresAt;

  /// Zero remaining means the full amount is due now.
  bool get isFullPayment => remaining.amountMinor == 0;

  Map<String, dynamic> toJson() => {
    'quote_id': quoteId,
    'property_id': propertyId,
    'check_in': stay.checkIn.toString(),
    'check_out': stay.checkOut.toString(),
    'nights': nights,
    'guests_count': guests,
    'nightly_minor': nightly.amountMinor,
    'total_minor': total.amountMinor,
    'pay_now_minor': payNow.amountMinor,
    'remaining_minor': remaining.amountMinor,
    'remaining_due_at': remainingDueAt?.toIso8601String(),
    'terms_hash': termsHash,
    'policy_summary': policySummary == null
        ? null
        : {
            'deposit_type': policySummary!.depositType.name,
            'deposit_percent_bp': policySummary!.depositPercentBp,
            'deposit_amount_minor': policySummary!.depositAmount?.amountMinor,
            'free_cancellation_hours': policySummary!.freeCancellationHours,
          },
    'expires_at': expiresAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is BookingQuote &&
      other.quoteId == quoteId &&
      other.propertyId == propertyId &&
      other.stay == stay &&
      other.nights == nights &&
      other.guests == guests &&
      other.nightly == nightly &&
      other.total == total &&
      other.payNow == payNow &&
      other.remaining == remaining &&
      other.remainingDueAt == remainingDueAt &&
      other.termsHash == termsHash &&
      other.policySummary == policySummary &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(
    quoteId,
    propertyId,
    stay,
    nights,
    guests,
    nightly,
    total,
    payNow,
    remaining,
    remainingDueAt,
    termsHash,
    policySummary,
    expiresAt,
  );
}
