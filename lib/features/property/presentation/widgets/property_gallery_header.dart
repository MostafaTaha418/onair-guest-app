import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
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
    this.heroTag,
    this.actions = const [],
    super.key,
  });

  final String propertyId;
  final List<ListingImage> images;

  /// The card cover's variants from `GoRouterState.extra`; when absent the
  /// header falls back to the first image's own variants.
  final List<ImageVariant>? heroVariants;

  /// The tapped card's Hero tag, carried on the first photo so it morphs from
  /// the results list (research R9, SC-006). Null on a deep link.
  final String? heroTag;

  /// Slot for the app-bar actions; US5 adds Share here.
  final List<Widget> actions;

  @override
  State<PropertyGalleryHeader> createState() => _PropertyGalleryHeaderState();
}

final class _PropertyGalleryHeaderState extends State<PropertyGalleryHeader> {
  final PageController _pageController = PageController();
  int _current = 0;
  bool _openingGallery = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openGallery(int index) async {
    if (_openingGallery) return;
    _openingGallery = true;
    try {
      await context.push<void>(
        Uri(
          path: AppRoutes.propertyGallery(widget.propertyId),
          queryParameters: {'index': '$index'},
        ).toString(),
        extra: widget.images,
      );
    } finally {
      _openingGallery = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final total = widget.images.length;
    return RepaintBoundary(
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.08,
            child: total == 0
                ? ColoredBox(color: colors['detailCard'])
                : PageView.builder(
                    controller: _pageController,
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
                        onTap: () => _openGallery(index),
                        child: OnAirNetworkImage(
                          variants: variants,
                          heroTag: index == 0 ? widget.heroTag : null,
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.screenSide,
                Dimens.space8,
                Dimens.screenSide,
                0,
              ),
              child: Row(
                children: [
                  Material(
                    color: colors.surface,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? AppIcons.chevronRight
                            : AppIcons.chevronLeft,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  for (final action in widget.actions)
                    Material(
                      color: colors.surface,
                      shape: const CircleBorder(),
                      child: action,
                    ),
                ],
              ),
            ),
          ),
          if (total > 1)
            PositionedDirectional(
              bottom: Dimens.space16,
              start: Dimens.space16,
              end: Dimens.space16,
              child: Center(
                child: Semantics(
                  label: l10n.galleryPhotoPosition(_current + 1, total),
                  excludeSemantics: true,
                  // A soft scrim so the dots stay legible over bright photos.
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: Dimens.space12,
                      vertical: Dimens.space8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(Dimens.radiusChip),
                    ),
                    child: _GalleryDots(
                      controller: _pageController,
                      count: total,
                      activeColor: colors['vipGold'],
                      inactiveColor: colors.surface.withValues(alpha: 0.65),
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

/// The photo-pager indicator: a row of dots where the active one stretches
/// into a pill. It follows the [PageController] offset frame by frame, so the
/// active dot slides and the colour cross-fades smoothly mid-swipe instead of
/// snapping on page change. A [FittedBox] keeps many dots inside the photo.
final class _GalleryDots extends StatelessWidget {
  const _GalleryDots({
    required this.controller,
    required this.count,
    required this.activeColor,
    required this.inactiveColor,
  });

  final PageController controller;
  final int count;
  final Color activeColor;
  final Color inactiveColor;

  static const double _dotHeight = 7;
  static const double _minWidth = 7;
  static const double _maxWidth = 22;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final page =
              controller.hasClients && controller.position.haveDimensions
              ? (controller.page ?? controller.initialPage.toDouble())
              : controller.initialPage.toDouble();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++) _dot(i, page),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(int index, double page) {
    // 1 when this dot is the active page, falling to 0 one page away, so the
    // two dots either side of a drag share the stretch and colour.
    final t = (1 - (page - index).abs()).clamp(0.0, 1.0);
    return Container(
      width: _minWidth + (_maxWidth - _minWidth) * t,
      height: _dotHeight,
      margin: const EdgeInsetsDirectional.symmetric(horizontal: _gap / 2),
      decoration: BoxDecoration(
        color: Color.lerp(inactiveColor, activeColor, t),
        borderRadius: BorderRadius.circular(_dotHeight),
      ),
    );
  }
}
