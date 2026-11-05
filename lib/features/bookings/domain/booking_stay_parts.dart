import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';

@immutable
final class StayAcknowledgements {
  const StayAcknowledgements({
    required this.keyLeftSafe,
    this.guestCheckInAt,
    this.hostCheckInAt,
    this.guestCheckOutAt,
    this.hostCheckOutAt,
  });

  factory StayAcknowledgements.fromJson(Map<String, dynamic> json) =>
      StayAcknowledgements(
        guestCheckInAt: _dateTime(json['guest_checkin_at']),
        hostCheckInAt: _dateTime(json['host_checkin_at']),
        guestCheckOutAt: _dateTime(json['guest_checkout_at']),
        hostCheckOutAt: _dateTime(json['host_checkout_at']),
        keyLeftSafe: json['key_left_safe'] as bool? ?? false,
      );

  static const empty = StayAcknowledgements(keyLeftSafe: false);

  final DateTime? guestCheckInAt;
  final DateTime? hostCheckInAt;
  final DateTime? guestCheckOutAt;
  final DateTime? hostCheckOutAt;
  final bool keyLeftSafe;

  bool get hasAny =>
      guestCheckInAt != null ||
      hostCheckInAt != null ||
      guestCheckOutAt != null ||
      hostCheckOutAt != null;

  Map<String, dynamic> toJson() => {
    'guest_checkin_at': guestCheckInAt?.toIso8601String(),
    'host_checkin_at': hostCheckInAt?.toIso8601String(),
    'guest_checkout_at': guestCheckOutAt?.toIso8601String(),
    'host_checkout_at': hostCheckOutAt?.toIso8601String(),
    'key_left_safe': keyLeftSafe,
  };

  @override
  bool operator ==(Object other) =>
      other is StayAcknowledgements &&
      other.guestCheckInAt == guestCheckInAt &&
      other.hostCheckInAt == hostCheckInAt &&
      other.guestCheckOutAt == guestCheckOutAt &&
      other.hostCheckOutAt == hostCheckOutAt &&
      other.keyLeftSafe == keyLeftSafe;

  @override
  int get hashCode => Object.hash(
    guestCheckInAt,
    hostCheckInAt,
    guestCheckOutAt,
    hostCheckOutAt,
    keyLeftSafe,
  );
}

enum CashOrigin {
  guest,
  collector,
  unknown;

  static CashOrigin fromWire(String? value) => switch (value) {
    'guest' => guest,
    'collector' => collector,
    _ => unknown,
  };

  String get wire => switch (this) {
    guest => 'guest',
    collector => 'collector',
    unknown => 'unknown',
  };
}

@immutable
final class CashRequest {
  const CashRequest({
    required this.paymentId,
    required this.challengeId,
    required this.collectorDisplayName,
    required this.amount,
    required this.maskedEmail,
    required this.codeExpiresAt,
    required this.origin,
    this.retryAfterSeconds = 0,
  });

  factory CashRequest.fromJson(Map<String, dynamic> json) => CashRequest(
    paymentId: json['payment_id'] as String,
    challengeId: json['challenge_id'] as String? ?? '',
    collectorDisplayName: json['collector_display_name'] as String,
    amount: Money(json['amount_minor'] as int),
    maskedEmail: json['masked_email'] as String,
    codeExpiresAt: _dateTime(json['code_expires_at']),
    retryAfterSeconds: json['retry_after_seconds'] as int? ?? 0,
    origin: CashOrigin.fromWire(json['origin'] as String?),
  );

  final String paymentId;
  final String challengeId;
  final String collectorDisplayName;
  final Money amount;
  final String maskedEmail;
  final DateTime? codeExpiresAt;
  final int retryAfterSeconds;
  final CashOrigin origin;

  Map<String, dynamic> toJson() => {
    'payment_id': paymentId,
    'challenge_id': challengeId,
    'collector_display_name': collectorDisplayName,
    'amount_minor': amount.amountMinor,
    'masked_email': maskedEmail,
    'code_expires_at': codeExpiresAt?.toIso8601String(),
    'retry_after_seconds': retryAfterSeconds,
    'origin': origin.wire,
  };

  Map<String, dynamic> toCacheJson() => {
    'payment_id': paymentId,
    'collector_display_name': collectorDisplayName,
    'amount_minor': amount.amountMinor,
    'masked_email': maskedEmail,
    'code_expires_at': codeExpiresAt?.toIso8601String(),
    'retry_after_seconds': retryAfterSeconds,
    'origin': origin.wire,
  };

  @override
  bool operator ==(Object other) =>
      other is CashRequest &&
      other.paymentId == paymentId &&
      other.challengeId == challengeId &&
      other.collectorDisplayName == collectorDisplayName &&
      other.amount == amount &&
      other.maskedEmail == maskedEmail &&
      other.codeExpiresAt == codeExpiresAt &&
      other.retryAfterSeconds == retryAfterSeconds &&
      other.origin == origin;

  @override
  int get hashCode => Object.hash(
    paymentId,
    challengeId,
    collectorDisplayName,
    amount,
    maskedEmail,
    codeExpiresAt,
    retryAfterSeconds,
    origin,
  );
}

@immutable
final class CashReceipt {
  const CashReceipt({
    required this.receiptNo,
    required this.collectorDisplayName,
    required this.confirmedAt,
  });

  factory CashReceipt.fromJson(Map<String, dynamic> json) => CashReceipt(
    receiptNo: json['receipt_no'] as String,
    collectorDisplayName: json['collector_display_name'] as String,
    confirmedAt: DateTime.parse(json['confirmed_at'] as String),
  );

  final String receiptNo;
  final String collectorDisplayName;
  final DateTime confirmedAt;

  Map<String, dynamic> toJson() => {
    'receipt_no': receiptNo,
    'collector_display_name': collectorDisplayName,
    'confirmed_at': confirmedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is CashReceipt &&
      other.receiptNo == receiptNo &&
      other.collectorDisplayName == collectorDisplayName &&
      other.confirmedAt == confirmedAt;

  @override
  int get hashCode => Object.hash(receiptNo, collectorDisplayName, confirmedAt);
}

enum DamageClaimStatus {
  open,
  guestAccepted,
  guestDisputed,
  inMediation,
  resolved,
  withdrawn,
  unknown;

  static DamageClaimStatus fromWire(String? value) => switch (value) {
    'open' => open,
    'guest_accepted' => guestAccepted,
    'guest_disputed' => guestDisputed,
    'in_mediation' => inMediation,
    'resolved' => resolved,
    'withdrawn' => withdrawn,
    _ => unknown,
  };

  String get wire => switch (this) {
    open => 'open',
    guestAccepted => 'guest_accepted',
    guestDisputed => 'guest_disputed',
    inMediation => 'in_mediation',
    resolved => 'resolved',
    withdrawn => 'withdrawn',
    unknown => 'unknown',
  };
}

@immutable
final class DamageClaimSummary {
  const DamageClaimSummary({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory DamageClaimSummary.fromJson(Map<String, dynamic> json) =>
      DamageClaimSummary(
        id: json['id'] as String,
        amount: Money(json['amount_minor'] as int),
        status: DamageClaimStatus.fromWire(json['status'] as String?),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final Money amount;
  final DamageClaimStatus status;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount_minor': amount.amountMinor,
    'status': status.wire,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is DamageClaimSummary &&
      other.id == id &&
      other.amount == amount &&
      other.status == status &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, amount, status, createdAt);
}

enum OfferStatus {
  pending,
  accepted,
  declined,
  expired,
  withdrawn,
  unknown;

  static OfferStatus fromWire(String? value) => switch (value) {
    'pending' => pending,
    'accepted' => accepted,
    'declined' => declined,
    'expired' => expired,
    'withdrawn' => withdrawn,
    _ => unknown,
  };

  String get wire => switch (this) {
    pending => 'pending',
    accepted => 'accepted',
    declined => 'declined',
    expired => 'expired',
    withdrawn => 'withdrawn',
    unknown => 'unknown',
  };
}

enum OfferDirection { guestPays, guestRefunded, none }

@immutable
final class ReplacementOffer {
  const ReplacementOffer({
    required this.id,
    required this.status,
    required this.propertyId,
    required this.propertyTitle,
    required this.areaName,
    required this.coverImage,
    required this.stay,
    required this.difference,
    required this.direction,
    required this.expiresAt,
  });

  factory ReplacementOffer.fromJson(Map<String, dynamic> json) {
    final property = Map<String, dynamic>.from(
      json['offered_property'] as Map,
    );
    final rawDifference = json['price_difference_minor'] as int;
    final direction = rawDifference > 0
        ? OfferDirection.guestPays
        : rawDifference < 0
        ? OfferDirection.guestRefunded
        : OfferDirection.none;
    return ReplacementOffer(
      id: json['id'] as String,
      status: OfferStatus.fromWire(json['status'] as String?),
      propertyId: property['id'] as String,
      propertyTitle: property['title'] as String,
      areaName: property['area_name'] as String,
      coverImage: property['cover_image'] == null
          ? null
          : ListingImage.fromJson(
              Map<String, dynamic>.from(property['cover_image'] as Map),
            ),
      stay: StayRange(
        DateOnly.parse(json['check_in'] as String),
        DateOnly.parse(json['check_out'] as String),
      ),
      difference: Money(rawDifference.abs()),
      direction: direction,
      expiresAt: _dateTime(json['expires_at']),
    );
  }

  final String id;
  final OfferStatus status;
  final String propertyId;
  final String propertyTitle;
  final String areaName;
  final ListingImage? coverImage;
  final StayRange stay;
  final Money difference;
  final OfferDirection direction;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() {
    final signedDifference = switch (direction) {
      OfferDirection.guestPays => difference.amountMinor,
      OfferDirection.guestRefunded => -difference.amountMinor,
      OfferDirection.none => 0,
    };
    return {
      'id': id,
      'status': status.wire,
      'offered_property': {
        'id': propertyId,
        'title': propertyTitle,
        'area_name': areaName,
        'cover_image': coverImage == null
            ? null
            : {
                'variants': [
                  for (final variant in coverImage!.variants)
                    {'width': variant.width, 'url': variant.url.toString()},
                ],
                'blurhash': coverImage!.blurhash,
              },
      },
      'check_in': stay.checkIn.toString(),
      'check_out': stay.checkOut.toString(),
      'price_difference_minor': signedDifference,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ReplacementOffer &&
      other.id == id &&
      other.status == status &&
      other.propertyId == propertyId &&
      other.propertyTitle == propertyTitle &&
      other.areaName == areaName &&
      other.coverImage == coverImage &&
      other.stay == stay &&
      other.difference == difference &&
      other.direction == direction &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(
    id,
    status,
    propertyId,
    propertyTitle,
    areaName,
    coverImage,
    stay,
    difference,
    direction,
    expiresAt,
  );
}

@immutable
final class CancellationInfo {
  const CancellationInfo({
    required this.cancelledAt,
    required this.byScope,
    required this.reasonCode,
  });

  factory CancellationInfo.fromJson(Map<String, dynamic> json) =>
      CancellationInfo(
        cancelledAt: DateTime.parse(json['cancelled_at'] as String),
        byScope: json['by_scope'] as String,
        reasonCode: json['reason_code'] as String?,
      );

  final DateTime cancelledAt;
  final String byScope;
  final String? reasonCode;

  Map<String, dynamic> toJson() => {
    'cancelled_at': cancelledAt.toIso8601String(),
    'by_scope': byScope,
    'reason_code': reasonCode,
  };

  @override
  bool operator ==(Object other) =>
      other is CancellationInfo &&
      other.cancelledAt == cancelledAt &&
      other.byScope == byScope &&
      other.reasonCode == reasonCode;

  @override
  int get hashCode => Object.hash(cancelledAt, byScope, reasonCode);
}

DateTime? _dateTime(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
