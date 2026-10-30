import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The 4:3 photo pager on top of the details screen. Tapping a photo opens
/// the full gallery; the first photo keeps the card's Hero tag so the photo
/// morphs from the results list (research R9, SC-006).
final class PropertyGalleryHeader extends StatefulWidget {
  const PropertyGalleryHeader({
    required this.propertyId,
    required this.images,
    this.heroVariants,
    this.actions = const [],
    super.key,
  });

  final String propertyId;
  final List<ListingImage> images;

  /// The card cover's variants from `GoRouterState.extra`; when absent the
  /// header falls back to the first image's own variants.
  final List<ImageVariant>? heroVariants;

  /// Slot for the app-bar actions; US5 adds Share here.
  final List<Widget> actions;

  @override
  State<PropertyGalleryHeader> createState() => _PropertyGalleryHeaderState();
}

final class _PropertyGalleryHeaderState extends State<PropertyGalleryHeader> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final total = widget.images.length;
    return RepaintBoundary(
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: total == 0
                ? ColoredBox(color: colors['detailCard'])
                : PageView.builder(
                    itemCount: total,
                    onPageChanged: (index) => setState(() => _current = index),
                    itemBuilder: (context, index) {
                      final image = widget.images[index];
                      final variants = index == 0
                          ? (widget.heroVariants ?? image.variants)
                          : image.variants;
                      return GestureDetector(
                        // The images travel as `extra` so the gallery route
                        // never depends on the details screen's cubit.
                        onTap: () => context.push(
                          Uri(
                            path: AppRoutes.propertyGallery(widget.propertyId),
                            queryParameters: {'index': '$index'},
                          ).toString(),
                          extra: widget.images,
                        ),
                        child: OnAirNetworkImage(
                          variants: variants,
                          heroTag: index == 0
                              ? 'listing-${widget.propertyId}'
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).backButtonTooltip,
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.adaptive.arrow_back,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                ...widget.actions,
              ],
            ),
          ),
          if (total > 0)
            PositionedDirectional(
              bottom: Dimens.space12,
              end: Dimens.space12,
              child: Semantics(
                label: l10n.galleryPhotoPosition(_current + 1, total),
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: Dimens.space8,
                    vertical: Dimens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(Dimens.radiusChip),
                  ),
                  child: Text(
                    l10n.galleryPhotoPosition(_current + 1, total),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
