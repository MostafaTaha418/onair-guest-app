import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/features/support/domain/support_case.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The leading glyph for a case card, picked from the case type so a guest can
/// scan the list by subject (booking, payment, …) at a glance.
IconData supportTypeIcon(CaseType type) => switch (type) {
  CaseType.booking => Icons.event_outlined,
  CaseType.payment => Icons.credit_card_outlined,
  CaseType.refund => Icons.replay,
  CaseType.propertyIssue => Icons.home_outlined,
  CaseType.other => Icons.chat_bubble_outline,
  CaseType.damageDispute => Icons.gavel_outlined,
  CaseType.complaint => Icons.report_problem_outlined,
  CaseType.stayException => Icons.event_busy_outlined,
  _ => Icons.help_outline,
};

String supportTypeLabel(CaseType type, AppLocalizations l10n) => switch (type) {
  CaseType.booking => l10n.supportTypeBooking,
  CaseType.payment => l10n.supportTypePayment,
  CaseType.refund => l10n.supportTypeRefund,
  CaseType.propertyIssue => l10n.supportTypePropertyIssue,
  CaseType.other => l10n.supportTypeOther,
  CaseType.damageDispute => l10n.supportTypeDamageDispute,
  CaseType.complaint => l10n.supportTypeComplaint,
  CaseType.stayException => l10n.supportTypeStayException,
  _ => l10n.supportTypeUnknown,
};

SupportCaseStatus supportStatus(CaseStatus status) => switch (status) {
  CaseStatus.open => SupportCaseStatus.open,
  CaseStatus.inProgress => SupportCaseStatus.inProgress,
  CaseStatus.waitingUser => SupportCaseStatus.waitingUser,
  CaseStatus.resolved => SupportCaseStatus.resolved,
  CaseStatus.closed => SupportCaseStatus.closed,
  _ => SupportCaseStatus.unknown,
};

String supportRelativeTime(DateTime value, DateTime now) {
  final difference = now.toUtc().difference(value.toUtc());
  if (difference.inMinutes < 1) return 'الآن';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  return '${difference.inDays}d';
}
