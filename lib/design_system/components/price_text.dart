import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

/// A price with an optional caption (for example the stay total).
final class PriceText extends StatelessWidget {
  const PriceText({required this.price, this.caption, super.key});

  final String price;
  final String? caption;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        price,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.price.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
      if (caption != null)
        Text(
          caption!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
    ],
  );
}
