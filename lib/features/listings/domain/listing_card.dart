import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';

/// The server-computed total for the searched stay; present only when the
/// request carried dates.
@immutable
final class CardStay {
  const CardStay({required this.nights, required this.stayTotal});

  factory CardStay.fromJson(Map<String, dynamic> json) => CardStay(
    nights: json['nights'] as int,
    stayTotal: Money(
      json['stay_total_minor'] as int,
      currency: json['currency'] as String? ?? 'EGP',
    ),
  );

  final int nights;
  final Money stayTotal;

  @override
  bool operator ==(Object other) =>
      other is CardStay &&
      other.nights == nights &&
      other.stayTotal == stayTotal;

  @override
  int get hashCode => Object.hash(nights, stayTotal);
}

/// The short form of a published apartment, used by Home and Results.
@immutable
final class ListingCard {
  const ListingCard({
    required this.id,
    required this.title,
    required this.propertyType,
    required this.areaName,
    required this.cityName,
    required this.cover,
    required this.nightlyPrice,
    required this.ratingAvg,
    required this.reviewCount,
    required this.stay,
  });

  factory ListingCard.fromJson(Map<String, dynamic> json) {
    final reviewCount = json['review_count'] as int? ?? 0;
    return ListingCard(
      id: json['id'] as String,
      title: json['title'] as String,
      propertyType: json['property_type'] as String,
      areaName: json['area_name'] as String,
      cityName: json['city_name'] as String,
      cover: json['cover'] == null
          ? null
          : ListingImage.fromJson(
              Map<String, dynamic>.from(json['cover'] as Map),
            ),
      nightlyPrice: Money(
        json['nightly_price_minor'] as int,
        currency: json['currency'] as String? ?? 'EGP',
      ),
      ratingAvg: reviewCount == 0
          ? null
          : (json['rating_avg'] as num?)?.toDouble(),
      reviewCount: reviewCount,
      stay: json['stay'] == null
          ? null
          : CardStay.fromJson(Map<String, dynamic>.from(json['stay'] as Map)),
    );
  }

  final String id;
  final String title;
  final String propertyType;
  final String areaName;
  final String cityName;
  final ListingImage? cover;
  final Money nightlyPrice;
  final double? ratingAvg;
  final int reviewCount;
  final CardStay? stay;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'property_type': propertyType,
    'area_name': areaName,
    'city_name': cityName,
    'cover': cover == null
        ? null
        : {
            'variants': [
              for (final variant in cover!.variants)
                {'width': variant.width, 'url': variant.url.toString()},
            ],
            'blurhash': cover!.blurhash,
          },
    'nightly_price_minor': nightlyPrice.amountMinor,
    'currency': nightlyPrice.currency,
    'rating_avg': ratingAvg,
    'review_count': reviewCount,
  };

  @override
  bool operator ==(Object other) =>
      other is ListingCard &&
      other.id == id &&
      other.title == title &&
      other.propertyType == propertyType &&
      other.areaName == areaName &&
      other.cityName == cityName &&
      other.cover == cover &&
      other.nightlyPrice == nightlyPrice &&
      other.ratingAvg == ratingAvg &&
      other.reviewCount == reviewCount &&
      other.stay == stay;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    propertyType,
    areaName,
    cityName,
    cover,
    nightlyPrice,
    ratingAvg,
    reviewCount,
    stay,
  );
}
