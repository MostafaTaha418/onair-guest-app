import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/property/domain/policy_text.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Localized sentence for one policy line (Master Plan §7.2).
String policyLineText(PolicyLine line, AppLocalizations l10n) => switch (line) {
  DepositPercentLine(:final percentText) => l10n.policyDepositPercent(
    percentText,
  ),
  DepositFixedLine(:final amount) => l10n.policyDepositFixed(
    MoneyFormatter().format(amount),
  ),
  DepositFullLine() => l10n.policyDepositFull,
  FreeCancellationLine(:final hours) => l10n.policyFreeCancellation(hours),
  AfterDeadlineLine() => l10n.policyAfterDeadline,
  FullyPaidLateLine() => l10n.policyFullyPaidLate,
};
