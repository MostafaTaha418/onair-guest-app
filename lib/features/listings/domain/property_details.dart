import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/listing_image.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';

@immutable
final class StayRules {
  const StayRules({
    required this.checkInTime,
    required this.checkOutTime,
    required this.visitorsAllowed,
    required this.maxVisitors,
    required this.houseRules,
  });

  factory StayRules.fromJson(Map<String, dynamic> json) => StayRules(
    checkInTime: json['check_in_time'] as String,
    checkOutTime: json['check_out_time'] as String,
    visitorsAllowed: json['visitors_allowed'] as bool? ?? false,
    maxVisitors: json['max_visitors'] as int?,
    houseRules: json['house_rules'] as String?,
  );

  /// `HH:mm` at the apartment, displayed as Cairo time.
  final String checkInTime;
  final String checkOutTime;
  final bool visitorsAllowed;
  final int? maxVisitors;

  /// Owner text, rendered as plain text only — never HTML or links.
  final String? houseRules;

  @override
  bool operator ==(Object other) =>
      other is StayRules &&
      other.checkInTime == checkInTime &&
      other.checkOutTime == checkOutTime &&
      other.visitorsAllowed == visitorsAllowed &&
      other.maxVisitors == maxVisitors &&
      other.houseRules == houseRules;

  @override
  int get hashCode => Object.hash(
    checkInTime,
    checkOutTime,
    visitorsAllowed,
    maxVisitors,
    houseRules,
  );
}

enum DepositType { percent, fixed, full }

@immutable
final class PolicySummary {
  const PolicySummary({
    required this.depositType,
    required this.depositPercentBp,
    required this.depositAmount,
    required this.freeCancellationHours,
  });

  factory PolicySummary.fromJson(Map<String, dynamic> json) {
    final type = json['deposit_type'] as String?;
    return PolicySummary(
      depositType: switch (type) {
        'percent' => DepositType.percent,
        'fixed' => DepositType.fixed,
        'full' => DepositType.full,
        _ => throw FormatException('Unknown deposit type: $type'),
      },
      depositPercentBp: json['deposit_percent_bp'] as int?,
      depositAmount: json['deposit_amount_minor'] == null
          ? null
          : Money(
              json['deposit_amount_minor'] as int,
              currency: json['currency'] as String? ?? 'EGP',
            ),
      freeCancellationHours: json['free_cancellation_hours'] as int,
    );
  }

  final DepositType depositType;

  /// Basis points when [DepositType.percent] (2500 = 25%).
  final int? depositPercentBp;
  final Money? depositAmount;

  /// Hours before scheduled check-in.
  final int freeCancellationHours;

  @override
  bool operator ==(Object other) =>
      other is PolicySummary &&
      other.depositType == depositType &&
      other.depositPercentBp == depositPercentBp &&
      other.depositAmount == depositAmount &&
      other.freeCancellationHours == freeCancellationHours;

  @override
  int get hashCode => Object.hash(
    depositType,
    depositPercentBp,
    depositAmount,
    freeCancellationHours,
  );
}

/// Everything the details screen shows; the server returns the final price
/// only — no base price, margin, or coordinates exist on this model (D-001).
@immutable
final class PropertyDetails {
  const PropertyDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.areaName,
    required this.cityName,
    required this.governorateName,
    required this.addressText,
    required this.images,
    required this.bedrooms,
    required this.bathrooms,
    required this.maxGuests,
    required this.areaSqm,
    required this.amenities,
    required this.rules,
    required this.policy,
    required this.nightlyPrice,
    required this.ratingAvg,
    required this.reviewCount,
    required this.latestReviews,
    required this.termsVersion,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    final reviewCount = json['review_count'] as int? ?? 0;
    final latestReviews = [
      for (final raw in json['latest_reviews'] as List? ?? const [])
        ApprovedReview.fromJson(Map<String, dynamic>.from(raw as Map)),
    ].take(3).toList();
    return PropertyDetails(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      propertyType: json['property_type'] as String,
      areaName: json['area_name'] as String,
      cityName: json['city_name'] as String,
      governorateName: json['governorate_name'] as String,
      addressText: json['address_text'] as String?,
      images: [
        for (final raw in json['images'] as List? ?? const [])
          ListingImage.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      bedrooms: json['bedrooms'] as int,
      bathrooms: json['bathrooms'] as int,
      maxGuests: json['max_guests'] as int,
      areaSqm: json['area_sqm'] as int?,
      amenities: [
        for (final raw in json['amenities'] as List? ?? const [])
          Amenity.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      rules: StayRules.fromJson(
        Map<String, dynamic>.from(json['rules'] as Map),
      ),
      policy: PolicySummary.fromJson(
        Map<String, dynamic>.from(json['policy'] as Map),
      ),
      nightlyPrice: Money(
        json['nightly_price_minor'] as int,
        currency: json['currency'] as String? ?? 'EGP',
      ),
      ratingAvg: reviewCount == 0
          ? null
          : (json['rating_avg'] as num?)?.toDouble(),
      reviewCount: reviewCount,
      latestReviews: latestReviews,
      termsVersion: json['terms_version'] as String,
    );
  }

  final String id;
  final String title;
  final String description;
  final String propertyType;
  final String areaName;
  final String cityName;
  final String governorateName;

  /// Public address text (D-001); the row is hidden when null.
  final String? addressText;
  final List<ListingImage> images;
  final int bedrooms;
  final int bathrooms;
  final int maxGuests;
  final int? areaSqm;
  final List<Amenity> amenities;
  final StayRules rules;
  final PolicySummary policy;

  /// Final nightly price (base + margin are server-only).
  final Money nightlyPrice;
  final double? ratingAvg;
  final int reviewCount;
  final List<ApprovedReview> latestReviews;

  /// Opaque; carried by "Book now" (AC-013).
  final String termsVersion;

  @override
  bool operator ==(Object other) =>
      other is PropertyDetails &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.propertyType == propertyType &&
      other.areaName == areaName &&
      other.cityName == cityName &&
      other.governorateName == governorateName &&
      other.addressText == addressText &&
      listEquals(other.images, images) &&
      other.bedrooms == bedrooms &&
      other.bathrooms == bathrooms &&
      other.maxGuests == maxGuests &&
      other.areaSqm == areaSqm &&
      listEquals(other.amenities, amenities) &&
      other.rules == rules &&
      other.policy == policy &&
      other.nightlyPrice == nightlyPrice &&
      other.ratingAvg == ratingAvg &&
      other.reviewCount == reviewCount &&
      listEquals(other.latestReviews, latestReviews) &&
      other.termsVersion == termsVersion;

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    description,
    propertyType,
    areaName,
    cityName,
    governorateName,
    addressText,
    Object.hashAll(images),
    bedrooms,
    bathrooms,
    maxGuests,
    areaSqm,
    Object.hashAll(amenities),
    rules,
    policy,
    nightlyPrice,
    ratingAvg,
    reviewCount,
    Object.hashAll(latestReviews),
    termsVersion,
  ]);
}
