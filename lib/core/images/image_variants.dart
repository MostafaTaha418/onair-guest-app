import 'package:flutter/foundation.dart';

/// One photo size on the CDN, as returned by the server (research R8).
@immutable
final class ImageVariant {
  const ImageVariant({required this.width, required this.url});

  factory ImageVariant.fromJson(Map<String, dynamic> json) => ImageVariant(
    width: json['width'] as int,
    url: Uri.parse(json['url'] as String),
  );

  final int width;
  final Uri url;

  @override
  bool operator ==(Object other) =>
      other is ImageVariant && other.width == width && other.url == url;

  @override
  int get hashCode => Object.hash(width, url);
}

abstract final class ImageVariants {
  /// The smallest variant at least `logicalWidth × devicePixelRatio` wide, or
  /// the widest when none qualifies. An empty list returns null and the caller
  /// shows the placeholder.
  static ImageVariant? pick({
    required List<ImageVariant> variants,
    required double logicalWidth,
    required double devicePixelRatio,
  }) {
    if (variants.isEmpty) return null;
    final needed = logicalWidth * devicePixelRatio;
    ImageVariant? smallestSufficient;
    var widest = variants.first;
    for (final variant in variants) {
      if (variant.width > widest.width) widest = variant;
      if (variant.width >= needed &&
          (smallestSufficient == null ||
              variant.width < smallestSufficient.width)) {
        smallestSufficient = variant;
      }
    }
    return smallestSufficient ?? widest;
  }
}
