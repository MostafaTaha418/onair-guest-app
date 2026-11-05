import 'package:flutter/foundation.dart';
import 'package:on_air/features/bookings/domain/booking_parts.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';

@immutable
final class CancellationResult {
  const CancellationResult({required this.status, required this.refund});

  factory CancellationResult.fromJson(Map<String, dynamic> json) =>
      CancellationResult(
        status: json['status'] as String,
        refund: json['refund'] == null
            ? null
            : RefundInfo.fromJson(
                Map<String, dynamic>.from(json['refund'] as Map),
              ),
      );

  final String status;
  final RefundInfo? refund;

  @override
  bool operator ==(Object other) =>
      other is CancellationResult &&
      other.status == status &&
      other.refund == refund;

  @override
  int get hashCode => Object.hash(status, refund);
}

@immutable
final class ClaimAnswerResult {
  const ClaimAnswerResult({
    required this.status,
    required this.supportCaseNumber,
  });

  factory ClaimAnswerResult.fromJson(Map<String, dynamic> json) =>
      ClaimAnswerResult(
        status: DamageClaimStatus.fromWire(json['status'] as String?),
        supportCaseNumber: json['support_case_number'] as String?,
      );

  final DamageClaimStatus status;
  final String? supportCaseNumber;

  @override
  bool operator ==(Object other) =>
      other is ClaimAnswerResult &&
      other.status == status &&
      other.supportCaseNumber == supportCaseNumber;

  @override
  int get hashCode => Object.hash(status, supportCaseNumber);
}

@immutable
final class OfferAnswerResult {
  const OfferAnswerResult({required this.status, required this.newBookingId});

  factory OfferAnswerResult.fromJson(Map<String, dynamic> json) =>
      OfferAnswerResult(
        status: OfferStatus.fromWire(json['status'] as String?),
        newBookingId: json['new_booking_id'] as String?,
      );

  final OfferStatus status;
  final String? newBookingId;

  @override
  bool operator ==(Object other) =>
      other is OfferAnswerResult &&
      other.status == status &&
      other.newBookingId == newBookingId;

  @override
  int get hashCode => Object.hash(status, newBookingId);
}

@immutable
final class FileUrl {
  const FileUrl({required this.url, required this.expiresAt});

  final Uri url;
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      other is FileUrl && other.url == url && other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(url, expiresAt);
}
