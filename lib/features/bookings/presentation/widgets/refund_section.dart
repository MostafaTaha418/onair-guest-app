import 'package:flutter/material.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/booking_flow_kit.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
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
    final current = switch (refund.stage) {
      RefundStage.requested => 0,
      RefundStage.approved => 1,
      RefundStage.executed => 2,
      RefundStage.verified => 3,
      _ => 0,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowSectionTitle(l10n.refundTitle),
        const SizedBox(height: Dimens.space12),
        FlowCard(
          padding: const EdgeInsetsDirectional.fromSTEB(
            Dimens.space8,
            6,
            Dimens.space8,
            Dimens.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FlowDataRow(
                label: l10n.refundAmount,
                value: MoneyFormatter().format(refund.amount),
                emphasized: true,
              ),
              const SizedBox(height: Dimens.space12),
              RefundProgress(
                stageLabels: [
                  l10n.refundStageRequested,
                  l10n.refundStageApproved,
                  l10n.refundStageExecuting,
                  l10n.refundStageVerified,
                ],
                currentIndex: current,
                failed: failed,
              ),
            ],
          ),
        ),
        if (failed) ...[
          const SizedBox(height: Dimens.space12),
          FlowNoticeCard(
            icon: AppIcons.supportAgent,
            tone: FlowTone.rejected,
            message: l10n.refundProblemHint,
          ),
        ],
      ],
    );
  }
}

/// Dots joined by a track whose success fill grows to the current stage.
/// Stages up to [currentIndex] are reached (a check); a failed refund marks
/// the current stage instead. Every stage keeps its visible label, so color
/// never carries it alone.
final class RefundProgress extends StatelessWidget {
  const RefundProgress({
    required this.stageLabels,
    required this.currentIndex,
    this.failed = false,
    super.key,
  });

  final List<String> stageLabels;
  final int currentIndex;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = FlowPalette.of(context);
    final count = stageLabels.length;
    final fill = count < 2 ? 0.0 : currentIndex / (count - 1);
    return Semantics(
      container: true,
      child: Stack(
        children: [
          PositionedDirectional(
            top: 13,
            start: 0,
            end: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cell = constraints.maxWidth / count;
                final track = constraints.maxWidth - cell;
                return Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: cell / 2,
                  ),
                  child: Stack(
                    children: [
                      Container(height: 2, color: palette.border2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: fill),
                        duration: flowDuration(context, 600),
                        curve: flowEmphasized,
                        builder: (context, t, _) => Container(
                          width: track * t,
                          height: 2,
                          color: colors['success'],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < count; i++)
                Expanded(child: _stepDot(context, i)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepDot(BuildContext context, int index) {
    final colors = context.colors;
    final palette = FlowPalette.of(context);
    final failedHere = failed && index == currentIndex;
    final done = index <= currentIndex && !failedHere;
    final (tone, icon) = failedHere
        ? (FlowTone.rejected, AppIcons.close)
        : done
        ? (FlowTone.success, AppIcons.check)
        : (FlowTone.cancelled, AppIcons.radioButtonUnchecked);
    return Column(
      children: [
        FlowToneCircle(icon: icon, tone: tone, size: 28, iconSize: 16),
        const SizedBox(height: 6),
        Text(
          stageLabels[index],
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: done || failedHere
                ? colors.textPrimary
                : palette.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
