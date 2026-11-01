import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';

/// One payment row of a booking (data-model §9). Labels avoid accounting
/// terms; the amount is the server's value, never recomputed.
@immutable
final class PaymentLine {
  const PaymentLine({
    required this.id,
    required this.purpose,
    required this.method,
    required this.status,
    required this.amount,
    this.paidAt,
  });

  factory PaymentLine.fromJson(Map<String, dynamic> json) => PaymentLine(
    id: json['id'] as String,
    purpose: json['purpose'] as String,
    method: json['method'] as String,
    status: json['status'] as String,
    amount: Money(json['amount_minor'] as int),
    paidAt: json['paid_at'] == null
        ? null
        : DateTime.parse(json['paid_at'] as String),
  );

  final String id;
  final String purpose;
  final String method;
  final String status;
  final Money amount;
  final DateTime? paidAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'purpose': purpose,
    'method': method,
    'status': status,
    'amount_minor': amount.amountMinor,
    'paid_at': paidAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is PaymentLine &&
      other.id == id &&
      other.purpose == purpose &&
      other.method == method &&
      other.status == status &&
      other.amount == amount &&
      other.paidAt == paidAt;

  @override
  int get hashCode => Object.hash(id, purpose, method, status, amount, paidAt);
}

/// The latest refund of a booking (data-model §9). "Refunded" copy is shown
/// only for [RefundStage.verified] (AC-042).
@immutable
final class RefundInfo {
  const RefundInfo({
    required this.id,
    required this.amount,
    required this.stage,
    this.updatedAt,
  });

  factory RefundInfo.fromJson(Map<String, dynamic> json) => RefundInfo(
    id: json['id'] as String,
    amount: Money(json['amount_minor'] as int),
    stage: RefundStage.fromWire(json['status'] as String?),
    updatedAt: json['updated_at'] == null
        ? null
        : DateTime.parse(json['updated_at'] as String),
  );

  final String id;
  final Money amount;
  final RefundStage stage;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount_minor': amount.amountMinor,
    'status': stage.wire,
    'updated_at': updatedAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is RefundInfo &&
      other.id == id &&
      other.amount == amount &&
      other.stage == stage &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, amount, stage, updatedAt);
}

/// One timeline row of a booking (data-model §9); only `visibility = all`
/// events reach the guest.
@immutable
final class BookingEvent {
  const BookingEvent({
    required this.eventType,
    required this.toStatus,
    required this.createdAt,
    this.note,
  });

  factory BookingEvent.fromJson(Map<String, dynamic> json) => BookingEvent(
    eventType: json['event_type'] as String,
    toStatus: json['to_status'] == null
        ? null
        : BookingStatus.fromWire(json['to_status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    note: json['note'] as String?,
  );

  final String eventType;
  final BookingStatus? toStatus;
  final DateTime createdAt;
  final String? note;

  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    'to_status': toStatus?.wire,
    'created_at': createdAt.toIso8601String(),
    'note': note,
  };

  @override
  bool operator ==(Object other) =>
      other is BookingEvent &&
      other.eventType == eventType &&
      other.toStatus == toStatus &&
      other.createdAt == createdAt &&
      other.note == note;

  @override
  int get hashCode => Object.hash(eventType, toStatus, createdAt, note);
}

/// The property card shown on the booking details screen (contract delta D1).
@immutable
final class BookingProperty {
  const BookingProperty({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.areaName,
    required this.cityName,
    required this.addressText,
    required this.checkInTime,
    required this.checkOutTime,
  });

  factory BookingProperty.fromJson(Map<String, dynamic> json) =>
      BookingProperty(
        id: json['id'] as String,
        title: json['title'] as String,
        coverImage: json['cover_image'] == null
            ? null
            : ListingImage.fromJson(
                Map<String, dynamic>.from(json['cover_image'] as Map),
              ),
        areaName: json['area_name'] as String,
        cityName: json['city_name'] as String,
        addressText: json['address_text'] as String?,
        checkInTime: json['check_in_time'] as String?,
        checkOutTime: json['check_out_time'] as String?,
      );

  final String id;
  final String title;
  final ListingImage? coverImage;
  final String areaName;
  final String cityName;
  final String? addressText;
  final String? checkInTime;
  final String? checkOutTime;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'cover_image': coverImage == null
        ? null
        : {
            'variants': [
              for (final variant in coverImage!.variants)
                {'width': variant.width, 'url': variant.url.toString()},
            ],
            'blurhash': coverImage!.blurhash,
          },
    'area_name': areaName,
    'city_name': cityName,
    'address_text': addressText,
    'check_in_time': checkInTime,
    'check_out_time': checkOutTime,
  };

  @override
  bool operator ==(Object other) =>
      other is BookingProperty &&
      other.id == id &&
      other.title == title &&
      other.coverImage == coverImage &&
      other.areaName == areaName &&
      other.cityName == cityName &&
      other.addressText == addressText &&
      other.checkInTime == checkInTime &&
      other.checkOutTime == checkOutTime;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    coverImage,
    areaName,
    cityName,
    addressText,
    checkInTime,
    checkOutTime,
  );
}
