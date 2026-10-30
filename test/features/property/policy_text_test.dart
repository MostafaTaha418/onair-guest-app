import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/property/domain/policy_text.dart';

PolicySummary _policy(
  DepositType type, {
  int? bp,
  Money? amount,
  int freeCancellationHours = 72,
}) => PolicySummary(
  depositType: type,
  depositPercentBp: bp,
  depositAmount: amount,
  freeCancellationHours: freeCancellationHours,
);

void main() {
  test('percent policy starts with the percent line (2500 bp → 25)', () {
    final lines = policyLines(_policy(DepositType.percent, bp: 2500));

    expect(lines.first, const DepositPercentLine(percentText: '25'));
    expect(lines, hasLength(4));
  });

  test('fractional percent keeps one decimal (1250 bp → 12.5)', () {
    final lines = policyLines(_policy(DepositType.percent, bp: 1250));

    expect(lines.first, const DepositPercentLine(percentText: '12.5'));
  });

  test('fixed policy starts with the fixed line', () {
    final amount = Money(100000);
    final lines = policyLines(_policy(DepositType.fixed, amount: amount));

    expect(lines.first, DepositFixedLine(amount));
  });

  test('full-payment policy starts with the full line', () {
    final lines = policyLines(_policy(DepositType.full));

    expect(lines.first, const DepositFullLine());
  });

  test('the tail is always cancellation, after-deadline, fully-paid', () {
    final policies = [
      _policy(DepositType.percent, bp: 2500),
      _policy(DepositType.fixed, amount: Money(100000)),
      _policy(DepositType.full),
    ];
    for (final policy in policies) {
      final lines = policyLines(policy);
      expect(lines[1], const FreeCancellationLine(hours: 72));
      expect(lines[2], const AfterDeadlineLine());
      expect(lines[3], const FullyPaidLateLine());
    }
  });

  test('the free-cancellation hours come from the policy', () {
    final lines = policyLines(
      _policy(DepositType.full, freeCancellationHours: 24),
    );

    expect(lines[1], const FreeCancellationLine(hours: 24));
  });

  test('no money is computed — the fixed amount passes through untouched', () {
    final amount = Money(123456);
    final lines = policyLines(_policy(DepositType.fixed, amount: amount));

    expect((lines.first as DepositFixedLine).amount, amount);
  });
}
