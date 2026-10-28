import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// A labeled minus/plus stepper with 48×48 touch targets (Constitution VI).
final class CounterStepper extends StatelessWidget {
  const CounterStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
    required this.decrementTooltip,
    required this.incrementTooltip,
    super.key,
  }) : assert(min <= max, 'min must not exceed max'),
       assert(
         value >= min && value <= max,
         'value must be within the [$min, $max] bounds',
       );

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;
  final String decrementTooltip;
  final String incrementTooltip;

  @override
  Widget build(BuildContext context) => Semantics(
    value: '$value',
    label: label,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: decrementTooltip,
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          constraints: const BoxConstraints(
            minWidth: Dimens.minTouchTarget,
            minHeight: Dimens.minTouchTarget,
          ),
        ),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        IconButton(
          tooltip: incrementTooltip,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          constraints: const BoxConstraints(
            minWidth: Dimens.minTouchTarget,
            minHeight: Dimens.minTouchTarget,
          ),
        ),
      ],
    ),
  );
}
