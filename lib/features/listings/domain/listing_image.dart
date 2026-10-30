import 'package:flutter/foundation.dart';
import 'package:on_air/core/images/image_variants.dart';

/// A photo with its server-provided size variants (research R8), sorted by
/// width ascending.
@immutable
final class ListingImage {
  const ListingImage({required this.variants, this.blurhash});

  factory ListingImage.fromJson(Map<String, dynamic> json) {
    final variants = [
      for (final raw in json['variants'] as List<dynamic>? ?? const [])
        ImageVariant.fromJson(Map<String, dynamic>.from(raw as Map)),
    ]..sort((a, b) => a.width.compareTo(b.width));
    return ListingImage(
      variants: variants,
      blurhash: json['blurhash'] as String?,
    );
  }

  final List<ImageVariant> variants;
  final String? blurhash;

  @override
  bool operator ==(Object other) =>
      other is ListingImage &&
      other.blurhash == blurhash &&
      listEquals(other.variants, variants);

  @override
  int get hashCode => Object.hash(blurhash, Object.hashAll(variants));
}
