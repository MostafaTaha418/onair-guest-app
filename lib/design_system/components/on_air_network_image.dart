import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:on_air/core/images/image_variants.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

/// A photo that picks the variant matching the rendered size
/// (width × devicePixelRatio) and decodes only that size (research R8).
final class OnAirNetworkImage extends StatelessWidget {
  const OnAirNetworkImage({
    required this.variants,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.semanticLabel,
    super.key,
  });

  final List<ImageVariant> variants;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// When set, the image participates in Hero transitions between the card
  /// and the details screen.
  final String? heroTag;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
          final picked = ImageVariants.pick(
            variants: variants,
            logicalWidth: constraints.maxWidth,
            devicePixelRatio: devicePixelRatio,
          );
          if (picked == null) return _placeholder(context);
          return CachedNetworkImage(
            imageUrl: picked.url.toString(),
            fit: fit,
            memCacheWidth: (constraints.maxWidth * devicePixelRatio).round(),
            placeholder: (_, _) => _placeholder(context),
            errorWidget: (_, _, _) => _errorBox(context),
          );
        },
      ),
    );
    final tag = heroTag;
    final hero = tag == null ? image : Hero(tag: tag, child: image);
    final label = semanticLabel;
    if (label == null) return hero;
    return Semantics(label: label, image: true, child: hero);
  }

  Widget _placeholder(BuildContext context) =>
      ColoredBox(color: context.colors['detailCard']);

  Widget _errorBox(BuildContext context) => ColoredBox(
    color: context.colors['detailCard'],
    child: Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: context.colors.textSecondary,
      ),
    ),
  );
}
