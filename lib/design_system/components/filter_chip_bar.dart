import 'package:flutter/material.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// A horizontal row of removable filter chips. Renders nothing when the list
/// is empty.
final class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    required this.chips,
    super.key,
  });

  final List<({String label, String removeTooltip, VoidCallback onRemove})>
  chips;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: Dimens.minTouchTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: Dimens.screenSide,
        ),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: Dimens.space8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return InputChip(
            label: Text(chip.label),
            onDeleted: chip.onRemove,
            deleteButtonTooltipMessage: chip.removeTooltip,
          );
        },
      ),
    );
  }
}
