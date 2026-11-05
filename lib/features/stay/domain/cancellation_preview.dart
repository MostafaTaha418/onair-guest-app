import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';

enum PolicyCase {
  free,
  depositLost,
  noRefund,
  unknown;

  static PolicyCase fromWire(String? value) => switch (value) {
    'free' => free,
    'deposit_lost' => depositLost,
    'no_refund' => noRefund,
    _ => unknown,
  };
}

@immutable
final class CancellationPreview {
  const CancellationPreview({
    required this.refund,
    required this.nonRefundable,
    required this.policyCase,
    required this.freeCancellationUntil,
    required this.previewToken,
    required this.validUntil,
  });

  factory CancellationPreview.fromJson(Map<String, dynamic> json) =>
      CancellationPreview(
        refund: Money(json['refund_minor'] as int),
        nonRefundable: Money(json['non_refundable_minor'] as int),
        policyCase: PolicyCase.fromWire(json['policy_case'] as String?),
        freeCancellationUntil: json['free_cancellation_until'] == null
            ? null
            : DateTime.parse(json['free_cancellation_until'] as String),
        previewToken: json['preview_token'] as String? ?? '',
        validUntil: json['valid_until'] == null
            ? null
            : DateTime.parse(json['valid_until'] as String),
      );

  final Money refund;
  final Money nonRefundable;
  final PolicyCase policyCase;
  final DateTime? freeCancellationUntil;
  final String previewToken;
  final DateTime? validUntil;

  @override
  bool operator ==(Object other) =>
      other is CancellationPreview &&
      other.refund == refund &&
      other.nonRefundable == nonRefundable &&
      other.policyCase == policyCase &&
      other.freeCancellationUntil == freeCancellationUntil &&
      other.previewToken == previewToken &&
      other.validUntil == validUntil;

  @override
  int get hashCode => Object.hash(
    refund,
    nonRefundable,
    policyCase,
    freeCancellationUntil,
    previewToken,
    validUntil,
  );
}

@immutable
final class PreviewChange {
  const PreviewChange({
    this.refund = false,
    this.nonRefundable = false,
    this.policyCase = false,
  });

  factory PreviewChange.between(
    CancellationPreview first,
    CancellationPreview second,
  ) => PreviewChange(
    refund: first.refund != second.refund,
    nonRefundable: first.nonRefundable != second.nonRefundable,
    policyCase: first.policyCase != second.policyCase,
  );

  static const none = PreviewChange();

  final bool refund;
  final bool nonRefundable;
  final bool policyCase;
  bool get any => refund || nonRefundable || policyCase;

  @override
  bool operator ==(Object other) =>
      other is PreviewChange &&
      other.refund == refund &&
      other.nonRefundable == nonRefundable &&
      other.policyCase == policyCase;

  @override
  int get hashCode => Object.hash(refund, nonRefundable, policyCase);
}

enum CancellationReason {
  changeOfPlans,
  foundOtherPlace,
  travelProblem,
  other;

  static const noteMaxLength = 300;

  String get wire => switch (this) {
    changeOfPlans => 'change_of_plans',
    foundOtherPlace => 'found_other_place',
    travelProblem => 'travel_problem',
    other => 'other',
  };
}
