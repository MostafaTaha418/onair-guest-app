import 'package:flutter/foundation.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';

/// One list card of My Bookings (data-model §7). Amounts live on the details
/// model only; the card shows dates, title, and status.
@immutable
final class BookingSummary {
  const BookingSummary({
    required this.id,
    required this.code,
    required this.propertyId,
    required this.title,
    required this.coverImage,
    required this.stay,
    required this.status,
    required this.refundStage,
    required this.ownerResponseDeadline,
    required this.createdAt,
  });

  factory BookingSummary.fromJson(Map<String, dynamic> json) => BookingSummary(
    id: json['id'] as String,
    code: json['code'] as String,
    propertyId: json['property_id'] as String,
    title: json['title'] as String,
    coverImage: json['cover_image'] == null
        ? null
        : ListingImage.fromJson(
            Map<String, dynamic>.from(json['cover_image'] as Map),
          ),
    // Server data may carry past dates, so the plain constructor is used;
    // `tryCreate` would drop everything before today.
    stay: StayRange(
      DateOnly.parse(json['check_in'] as String),
      DateOnly.parse(json['check_out'] as String),
    ),
    status: BookingStatus.fromWire(json['status'] as String?),
    // No refund row stays null; an unknown stage string maps to unknown.
    refundStage: json['refund_status'] == null
        ? null
        : RefundStage.fromWire(json['refund_status'] as String),
    ownerResponseDeadline: json['owner_response_deadline'] == null
        ? null
        : DateTime.parse(json['owner_response_deadline'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String code;
  final String propertyId;
  final String title;
  final ListingImage? coverImage;
  final StayRange stay;
  final BookingStatus status;
  final RefundStage? refundStage;
  final DateTime? ownerResponseDeadline;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'property_id': propertyId,
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
    'check_in': stay.checkIn.toString(),
    'check_out': stay.checkOut.toString(),
    'status': status.wire,
    'refund_status': refundStage?.wire,
    'owner_response_deadline': ownerResponseDeadline?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is BookingSummary &&
      other.id == id &&
      other.code == code &&
      other.propertyId == propertyId &&
      other.title == title &&
      other.coverImage == coverImage &&
      other.stay == stay &&
      other.status == status &&
      other.refundStage == refundStage &&
      other.ownerResponseDeadline == ownerResponseDeadline &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    code,
    propertyId,
    title,
    coverImage,
    stay,
    status,
    refundStage,
    ownerResponseDeadline,
    createdAt,
  );
}

/// One server page of a tab (contract delta D2).
@immutable
final class BookingsPage {
  const BookingsPage({required this.items, required this.nextCursor});

  factory BookingsPage.fromJson(Map<String, dynamic> json) => BookingsPage(
    items: [
      for (final raw in json['items'] as List? ?? const [])
        BookingSummary.fromJson(Map<String, dynamic>.from(raw as Map)),
    ],
    nextCursor: json['next_cursor'] as String?,
  );

  final List<BookingSummary> items;
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      other is BookingsPage &&
      listEquals(other.items, items) &&
      other.nextCursor == nextCursor;

  @override
  int get hashCode => Object.hash(Object.hashAll(items), nextCursor);
}
