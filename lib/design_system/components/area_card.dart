import 'package:flutter/material.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// A Home destination card: the photo fills a 140×170 tile with a
/// bottom-to-top scrim, the area name, and a pill with the listing count.
final class AreaCard extends StatelessWidget {
  const AreaCard({
    required this.title,
    required this.countLabel,
    required this.imageVariants,
    required this.onTap,
    super.key,
  });

  final String title;
  final String countLabel;
  final List<ImageVariant> imageVariants;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 140,
      height: 170,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              OnAirNetworkImage(variants: imageVariants),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      colors['primaryDark'].withValues(alpha: 0.7),
                      colors['primaryDark'].withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(Dimens.space12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.areaCardTitle.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: Dimens.space4),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: Dimens.space8,
                        vertical: Dimens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: colors['badgeNavActive'],
                        borderRadius: BorderRadius.circular(Dimens.radiusChip),
                      ),
                      child: Text(
                        countLabel,
                        style: context.textStyles.areaBadge.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
