import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// A star with the rating next to it. Callers do not render it when there is
/// no rating (research R16).
final class RatingBadge extends StatelessWidget {
  const RatingBadge({
    required this.ratingText,
    required this.semanticsLabel,
    super.key,
  });

  final String ratingText;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: Dimens.space16,
          color: context.colors['star'],
        ),
        const SizedBox(width: Dimens.space4),
        Text(
          ratingText,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
