import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/design_system/tokens/on_air_colors.dart';

/// Horizontal refund steps (data-model §9). Steps up to [currentIndex] use
/// the success colors, later ones the muted text; a failed refund paints the
/// current step with the error color. Every label is visible text, so the
/// stage is never conveyed by color alone.
final class RefundStageTracker extends StatelessWidget {
  const RefundStageTracker({
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
    return Row(
      children: [
        for (var index = 0; index < stageLabels.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(height: 2, color: colors['borderDetail']),
            ),
          Column(
            children: [
              Icon(
                index <= currentIndex && !failed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: Dimens.space20,
                color: _stepColor(colors, index),
              ),
              const SizedBox(height: Dimens.space4),
              Text(
                stageLabels[index],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _stepColor(colors, index),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _stepColor(OnAirColors colors, int index) {
    if (failed && index == currentIndex) return colors.errorText;
    if (index <= currentIndex) return colors['onSuccessContainer'];
    return colors.textSecondary;
  }
}
