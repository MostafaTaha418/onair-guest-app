import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/bookings/domain/booking_parts.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/listings/domain/property_details.dart';

/// Everything the booking details screen shows, straight from
/// `guest_get_booking` (data-model §8). No amount is ever computed here.
@immutable
final class BookingDetails {
  const BookingDetails({
    required this.id,
    required this.code,
    required this.status,
    required this.property,
    required this.stay,
    required this.nights,
    required this.guests,
    required this.nightly,
    required this.total,
    required this.payNow,
    required this.paid,
    required this.remaining,
    required this.remainingDueAt,
    required this.ownerResponseDeadline,
    required this.paymentState,
    required this.payments,
    required this.refund,
    required this.termsSnapshot,
    required this.accessInstructions,
    required this.availableActions,
    required this.events,
    required this.createdAt,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) => BookingDetails(
    id: json['id'] as String,
    code: json['code'] as String,
    status: BookingStatus.fromWire(json['status'] as String?),
    property: BookingProperty.fromJson(
      Map<String, dynamic>.from(json['property'] as Map),
    ),
    // Server data may carry past dates; the plain constructor never
    // checks them against today.
    stay: StayRange(
      DateOnly.parse(json['check_in'] as String),
      DateOnly.parse(json['check_out'] as String),
    ),
    nights: json['nights'] as int,
    guests: json['guests_count'] as int,
    nightly: Money(json['nightly_minor'] as int),
    total: Money(json['total_minor'] as int),
    payNow: Money(json['pay_now_minor'] as int),
    paid: Money(json['paid_minor'] as int),
    remaining: Money(json['remaining_minor'] as int),
    remainingDueAt: json['remaining_due_at'] == null
        ? null
        : DateTime.parse(json['remaining_due_at'] as String),
    ownerResponseDeadline: json['owner_response_deadline'] == null
        ? null
        : DateTime.parse(json['owner_response_deadline'] as String),
    paymentState: PaymentState.fromWire(json['payment_state'] as String?),
    payments: [
      for (final raw in json['payments'] as List? ?? const [])
        PaymentLine.fromJson(Map<String, dynamic>.from(raw as Map)),
    ],
    refund: json['refund'] == null
        ? null
        : RefundInfo.fromJson(Map<String, dynamic>.from(json['refund'] as Map)),
    termsSnapshot: json['terms_snapshot'] == null
        ? null
        : _termsFromJson(
            Map<String, dynamic>.from(json['terms_snapshot'] as Map),
          ),
    accessInstructions: json['access_instructions'] as String?,
    availableActions: [
      for (final code in json['available_actions'] as List? ?? const [])
        code as String,
    ],
    events: [
      for (final raw in json['events'] as List? ?? const [])
        BookingEvent.fromJson(Map<String, dynamic>.from(raw as Map)),
    ],
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  static PolicySummary? _termsFromJson(Map<String, dynamic> terms) =>
      terms['policy_summary'] == null
      ? null
      : PolicySummary.fromJson(
          Map<String, dynamic>.from(terms['policy_summary'] as Map),
        );

  final String id;
  final String code;
  final BookingStatus status;
  final BookingProperty property;
  final StayRange stay;
  final int nights;
  final int guests;
  final Money nightly;
  final Money total;
  final Money payNow;
  final Money paid;
  final Money remaining;
  final DateTime? remainingDueAt;
  final DateTime? ownerResponseDeadline;
  final PaymentState paymentState;
  final List<PaymentLine> payments;
  final RefundInfo? refund;

  /// The terms saved at booking time, not the current ones (data-model §8).
  final PolicySummary? termsSnapshot;
  final String? accessInstructions;
  final List<String> availableActions;
  final List<BookingEvent> events;
  final DateTime createdAt;

  /// The JSON cache never receives the arrival instructions (hard rule 11);
  /// they go only to the secure store.
  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'code': code,
    'status': status.wire,
    'property': property.toJson(),
    'check_in': stay.checkIn.toString(),
    'check_out': stay.checkOut.toString(),
    'nights': nights,
    'guests_count': guests,
    'nightly_minor': nightly.amountMinor,
    'total_minor': total.amountMinor,
    'pay_now_minor': payNow.amountMinor,
    'paid_minor': paid.amountMinor,
    'remaining_minor': remaining.amountMinor,
    'remaining_due_at': remainingDueAt?.toIso8601String(),
    'owner_response_deadline': ownerResponseDeadline?.toIso8601String(),
    'payment_state': paymentState.name,
    'payments': [for (final line in payments) line.toJson()],
    'refund': refund?.toJson(),
    'terms_snapshot': termsSnapshot == null
        ? null
        : {
            'policy_summary': {
              'deposit_type': termsSnapshot!.depositType.name,
              'deposit_percent_bp': termsSnapshot!.depositPercentBp,
              'deposit_amount_minor': termsSnapshot!.depositAmount?.amountMinor,
              'free_cancellation_hours': termsSnapshot!.freeCancellationHours,
            },
          },
    'available_actions': availableActions,
    'events': [for (final event in events) event.toJson()],
    'created_at': createdAt.toIso8601String(),
  };

  BookingDetails copyWithoutInstructions() => BookingDetails(
    id: id,
    code: code,
    status: status,
    property: property,
    stay: stay,
    nights: nights,
    guests: guests,
    nightly: nightly,
    total: total,
    payNow: payNow,
    paid: paid,
    remaining: remaining,
    remainingDueAt: remainingDueAt,
    ownerResponseDeadline: ownerResponseDeadline,
    paymentState: paymentState,
    payments: payments,
    refund: refund,
    termsSnapshot: termsSnapshot,
    accessInstructions: null,
    availableActions: availableActions,
    events: events,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is BookingDetails &&
      other.id == id &&
      other.code == code &&
      other.status == status &&
      other.property == property &&
      other.stay == stay &&
      other.nights == nights &&
      other.guests == guests &&
      other.nightly == nightly &&
      other.total == total &&
      other.payNow == payNow &&
      other.paid == paid &&
      other.remaining == remaining &&
      other.remainingDueAt == remainingDueAt &&
      other.ownerResponseDeadline == ownerResponseDeadline &&
      other.paymentState == paymentState &&
      listEquals(other.payments, payments) &&
      other.refund == refund &&
      other.termsSnapshot == termsSnapshot &&
      other.accessInstructions == accessInstructions &&
      listEquals(other.availableActions, availableActions) &&
      listEquals(other.events, events) &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    code,
    status,
    property,
    stay,
    nights,
    guests,
    nightly,
    total,
    payNow,
    paid,
    remaining,
    remainingDueAt,
    ownerResponseDeadline,
    paymentState,
    Object.hashAll(payments),
    refund,
    termsSnapshot,
    accessInstructions,
    Object.hashAll(availableActions),
    Object.hashAll(events),
    createdAt,
  ]);
}
