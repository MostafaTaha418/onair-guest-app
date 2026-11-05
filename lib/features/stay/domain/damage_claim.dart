import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';

@immutable
final class EvidenceRef {
  const EvidenceRef({
    required this.attachmentId,
    required this.kind,
    this.width,
    this.height,
  });

  factory EvidenceRef.fromJson(Map<String, dynamic> json) => EvidenceRef(
    attachmentId: json['attachment_id'] as String,
    kind: json['kind'] as String? ?? 'image',
    width: json['width'] as int?,
    height: json['height'] as int?,
  );

  final String attachmentId;
  final String kind;
  final int? width;
  final int? height;

  @override
  bool operator ==(Object other) =>
      other is EvidenceRef &&
      other.attachmentId == attachmentId &&
      other.kind == kind &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(attachmentId, kind, width, height);
}

enum ClaimDecision {
  accept,
  dispute;

  String get wire => name;
}

@immutable
final class ClaimResponse {
  const ClaimResponse({
    required this.decision,
    required this.note,
    required this.respondedAt,
  });

  factory ClaimResponse.fromJson(Map<String, dynamic> json) => ClaimResponse(
    decision: json['decision'] == 'dispute'
        ? ClaimDecision.dispute
        : ClaimDecision.accept,
    note: json['note'] as String?,
    respondedAt: DateTime.parse(json['responded_at'] as String),
  );

  final ClaimDecision decision;
  final String? note;
  final DateTime respondedAt;

  @override
  bool operator ==(Object other) =>
      other is ClaimResponse &&
      other.decision == decision &&
      other.note == note &&
      other.respondedAt == respondedAt;

  @override
  int get hashCode => Object.hash(decision, note, respondedAt);
}

enum ClaimOutcome {
  guestPays,
  partial,
  noCharge,
  withdrawn,
  unknown;

  static ClaimOutcome fromWire(String? value) => switch (value) {
    'guest_pays' => guestPays,
    'partial' => partial,
    'no_charge' => noCharge,
    'withdrawn' => withdrawn,
    _ => unknown,
  };
}

@immutable
final class ClaimResolution {
  const ClaimResolution({
    required this.outcome,
    required this.amount,
    required this.decidedAt,
  });

  factory ClaimResolution.fromJson(Map<String, dynamic> json) =>
      ClaimResolution(
        outcome: ClaimOutcome.fromWire(json['outcome_code'] as String?),
        amount: json['amount_minor'] == null
            ? null
            : Money(json['amount_minor'] as int),
        decidedAt: DateTime.parse(json['decided_at'] as String),
      );

  final ClaimOutcome outcome;
  final Money? amount;
  final DateTime decidedAt;

  @override
  bool operator ==(Object other) =>
      other is ClaimResolution &&
      other.outcome == outcome &&
      other.amount == amount &&
      other.decidedAt == decidedAt;

  @override
  int get hashCode => Object.hash(outcome, amount, decidedAt);
}

@immutable
final class DamageClaim {
  const DamageClaim({
    required this.id,
    required this.bookingId,
    required this.description,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.evidence,
    required this.response,
    required this.supportCaseNumber,
    required this.resolution,
  });

  factory DamageClaim.fromJson(Map<String, dynamic> json) => DamageClaim(
    id: json['id'] as String,
    bookingId: json['booking_id'] as String,
    description: json['description'] as String,
    amount: Money(json['amount_minor'] as int),
    status: DamageClaimStatus.fromWire(json['status'] as String?),
    createdAt: DateTime.parse(json['created_at'] as String),
    evidence: [
      for (final evidence in json['evidence'] as List? ?? const [])
        EvidenceRef.fromJson(Map<String, dynamic>.from(evidence as Map)),
    ],
    response: json['guest_response'] == null
        ? null
        : ClaimResponse.fromJson(
            Map<String, dynamic>.from(json['guest_response'] as Map),
          ),
    supportCaseNumber: json['support_case_number'] as String?,
    resolution: json['resolution'] == null
        ? null
        : ClaimResolution.fromJson(
            Map<String, dynamic>.from(json['resolution'] as Map),
          ),
  );

  final String id;
  final String bookingId;
  final String description;
  final Money amount;
  final DamageClaimStatus status;
  final DateTime createdAt;
  final List<EvidenceRef> evidence;
  final ClaimResponse? response;
  final String? supportCaseNumber;
  final ClaimResolution? resolution;

  @override
  bool operator ==(Object other) =>
      other is DamageClaim &&
      other.id == id &&
      other.bookingId == bookingId &&
      other.description == description &&
      other.amount == amount &&
      other.status == status &&
      other.createdAt == createdAt &&
      listEquals(other.evidence, evidence) &&
      other.response == response &&
      other.supportCaseNumber == supportCaseNumber &&
      other.resolution == resolution;

  @override
  int get hashCode => Object.hashAll([
    id,
    bookingId,
    description,
    amount,
    status,
    createdAt,
    Object.hashAll(evidence),
    response,
    supportCaseNumber,
    resolution,
  ]);
}

abstract final class ClaimLimits {
  static const disputeMin = 10;
  static const disputeMax = 1000;

  static bool validDisputeNote(String note) {
    final trimmed = note.trim();
    return trimmed.length >= disputeMin && trimmed.length <= disputeMax;
  }
}
