import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/listings/domain/property_details.dart';

/// One sentence of the policy section (Master Plan §7.2). The UI maps each
/// line to localized text; no money is ever computed here.
sealed class PolicyLine {
  const PolicyLine();
}

@immutable
final class DepositPercentLine extends PolicyLine {
  const DepositPercentLine({required this.percentText});

  /// bp/100; one decimal only when the value is not whole (1250 → '12.5').
  final String percentText;

  @override
  bool operator ==(Object other) =>
      other is DepositPercentLine && other.percentText == percentText;

  @override
  int get hashCode => percentText.hashCode;
}

@immutable
final class DepositFixedLine extends PolicyLine {
  const DepositFixedLine(this.amount);

  final Money amount;

  @override
  bool operator ==(Object other) =>
      other is DepositFixedLine && other.amount == amount;

  @override
  int get hashCode => amount.hashCode;
}

final class DepositFullLine extends PolicyLine {
  const DepositFullLine();
}

@immutable
final class FreeCancellationLine extends PolicyLine {
  const FreeCancellationLine({required this.hours});

  final int hours;

  @override
  bool operator ==(Object other) =>
      other is FreeCancellationLine && other.hours == hours;

  @override
  int get hashCode => hours.hashCode;
}

final class AfterDeadlineLine extends PolicyLine {
  const AfterDeadlineLine();
}

final class FullyPaidLateLine extends PolicyLine {
  const FullyPaidLateLine();
}

/// The ordered policy sentences: the deposit line for the policy type, then
/// always free cancellation, after-deadline, and fully-paid-late lines.
/// Percentages and amounts are shown as received (data-model "PolicySummary").
List<PolicyLine> policyLines(PolicySummary policy) => [
  switch (policy.depositType) {
    DepositType.percent => DepositPercentLine(
      percentText: _percentText(policy.depositPercentBp),
    ),
    DepositType.fixed => DepositFixedLine(policy.depositAmount ?? Money(0)),
    DepositType.full => const DepositFullLine(),
  },
  FreeCancellationLine(hours: policy.freeCancellationHours),
  const AfterDeadlineLine(),
  const FullyPaidLateLine(),
];

/// 2500 bp → '25'; 1250 bp → '12.5'.
String _percentText(int? bp) {
  final value = (bp ?? 0) / 100;
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}
