import 'package:flutter/material.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/refund_stage_tracker.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_parts.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// US4: the refund's own progress, shown apart from the booking status.
/// «تم رد المبلغ» appears only after the server's final check (AC-042) —
/// this section only ever mirrors `refund.stage` from the server.
final class RefundSection extends StatelessWidget {
  const RefundSection({required this.refund, super.key});

  final RefundInfo refund;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failed =
        refund.stage == RefundStage.failed ||
        refund.stage == RefundStage.cancelled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.refundTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: Dimens.space8),
        AmountRow(
          label: l10n.refundAmount,
          value: MoneyFormatter().format(refund.amount),
        ),
        const SizedBox(height: Dimens.space12),
        RefundStageTracker(
          stageLabels: [
            l10n.refundStageRequested,
            l10n.refundStageApproved,
            l10n.refundStageExecuting,
            l10n.refundStageVerified,
          ],
          currentIndex: switch (refund.stage) {
            RefundStage.requested => 0,
            RefundStage.approved => 1,
            RefundStage.executed => 2,
            RefundStage.verified => 3,
            _ => 0,
          },
          failed: failed,
        ),
        if (failed) ...[
          const SizedBox(height: Dimens.space12),
          NoticeCard(
            icon: Icons.support_agent,
            message: l10n.refundProblemHint,
          ),
        ],
      ],
    );
  }
}
