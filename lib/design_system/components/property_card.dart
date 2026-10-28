import 'package:flutter/material.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/price_text.dart';
import 'package:on_air/design_system/components/rating_badge.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// A result card: photo, title, subtitle (area • city), price, and optional
/// rating. Takes primitives only — the caller formats every string.
final class PropertyCard extends StatelessWidget {
  const PropertyCard({
    required this.title,
    required this.subtitle,
    required this.imageVariants,
    required this.priceText,
    required this.onTap,
    this.stayTotalText,
    this.ratingText,
    this.ratingSemantics,
    this.heroTag,
    this.width = double.infinity,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<ImageVariant> imageVariants;
  final String priceText;
  final String? stayTotalText;
  final String? ratingText;
  final String? ratingSemantics;
  final String? heroTag;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimens.radiusCard);
    return Semantics(
      container: true,
      button: true,
      child: Material(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: context.colors['subtleBorder']),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: OnAirNetworkImage(
                    variants: imageVariants,
                    heroTag: heroTag,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.all(Dimens.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textStyles.propertyTitle.copyWith(
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Dimens.space4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Dimens.space8),
                      Row(
                        children: [
                          Expanded(
                            child: PriceText(
                              price: priceText,
                              caption: stayTotalText,
                            ),
                          ),
                          if (ratingText != null)
                            RatingBadge(
                              ratingText: ratingText!,
                              semanticsLabel: ratingSemantics ?? ratingText!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
