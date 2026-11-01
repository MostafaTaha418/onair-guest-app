import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// One labelled amount row: label at the start, value at the end. With
/// [previousValue] the old amount is shown struck through before the new one
/// (quote re-price, FR-009); [highlighted] paints the warning background.
final class AmountRow extends StatelessWidget {
  const AmountRow({
    required this.label,
    required this.value,
    this.previousValue,
    this.emphasized = false,
    this.highlighted = false,
    super.key,
  });

  final String label;
  final String value;
  final String? previousValue;
  final bool emphasized;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseStyle = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    final row = Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: Dimens.space4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: baseStyle?.copyWith(color: colors.textSecondary),
            ),
          ),
          if (previousValue != null) ...[
            Flexible(
              child: Text(
                previousValue!,
                style: baseStyle?.copyWith(
                  color: colors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
            const SizedBox(width: Dimens.space8),
          ],
          Flexible(
            child: Text(
              value,
              style: baseStyle?.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
    if (!highlighted) return row;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors['warningContainer'],
        borderRadius: BorderRadius.circular(Dimens.radiusChip),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: Dimens.space8,
        ),
        child: row,
      ),
    );
  }
}
