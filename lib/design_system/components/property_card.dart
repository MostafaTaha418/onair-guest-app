import 'package:flutter/material.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/rating_badge.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Photo-led listing card. Directional layout mirrors the reference in RTL.
/// Optional badges and facts only appear when the caller has real data.
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
    this.availabilityLabel,
    this.availabilityIsBlocked = false,
    this.offerLabel,
    this.attributeLabels = const [],
    this.onFavoriteTap,
    this.isFavorite = false,
    this.favoriteBusy = false,
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
  final String? availabilityLabel;
  final bool availabilityIsBlocked;
  final String? offerLabel;
  final List<String> attributeLabels;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final bool favoriteBusy;
  final String? heroTag;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimens.radiusCard);
    return Material(
      color: colors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OnAirNetworkImage(
                      variants: imageVariants,
                      heroTag: heroTag,
                      borderRadius: BorderRadius.zero,
                    ),
                    if (availabilityLabel != null || offerLabel != null)
                      PositionedDirectional(
                        top: Dimens.space12,
                        start: Dimens.space12,
                        end: Dimens.space12,
                        child: Row(
                          children: [
                            if (availabilityLabel != null)
                              Flexible(
                                child: _PhotoBadge(
                                  label: availabilityLabel!,
                                  color: availabilityIsBlocked
                                      ? colors['destructiveDark']
                                      : colors['availableBadge'],
                                ),
                              ),
                            const Spacer(),
                            if (offerLabel != null)
                              Flexible(
                                child: _PhotoBadge(
                                  label: offerLabel!,
                                  color: colors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(Dimens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.propertyTitle.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimens.space12),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              priceText,
                              maxLines: 2,
                              textAlign: TextAlign.end,
                              style: context.textStyles.price.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? colors['primaryMuted']
                                    : colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimens.space4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        ),
                        if (ratingText != null) ...[
                          const SizedBox(width: Dimens.space8),
                          RatingBadge(
                            ratingText: ratingText!,
                            semanticsLabel: ratingSemantics ?? ratingText!,
                          ),
                        ],
                      ],
                    ),
                    if (stayTotalText != null) ...[
                      const SizedBox(height: Dimens.space4),
                      Text(
                        stayTotalText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (attributeLabels.isNotEmpty) ...[
                      const SizedBox(height: Dimens.space16),
                      Wrap(
                        spacing: Dimens.space8,
                        runSpacing: Dimens.space8,
                        children: [
                          for (final label in attributeLabels)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors['badgeNavActive'],
                                borderRadius: BorderRadius.circular(
                                  Dimens.radiusChip,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimens.space12,
                                  vertical: Dimens.space4,
                                ),
                                child: Text(
                                  label,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.primary,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: Dimens.space16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: Dimens.minTouchTarget,
                            child: FilledButton(
                              onPressed: onTap,
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).propertyViewDetails,
                              ),
                            ),
                          ),
                        ),
                        if (onFavoriteTap != null) ...[
                          const SizedBox(width: Dimens.space12),
                          SizedBox.square(
                            dimension: Dimens.minTouchTarget,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surface,
                                border: Border.all(color: colors.border),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: IconButton(
                                onPressed: favoriteBusy ? null : onFavoriteTap,
                                icon: Icon(
                                  isFavorite
                                      ? AppIcons.favorite
                                      : AppIcons.favoriteBorder,
                                  color: colors['favorite'],
                                ),
                                tooltip: isFavorite
                                    ? AppLocalizations.of(
                                        context,
                                      ).favoriteRemove
                                    : AppLocalizations.of(context).favoriteAdd,
                              ),
                            ),
                          ),
                        ],
                      ],
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

final class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(Dimens.radiusChip),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.colors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
