import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';

enum SearchSort {
  priceAsc('price_asc'),
  priceDesc('price_desc'),
  newest('newest');

  const SearchSort(this.wire);

  final String wire;

  static SearchSort? tryFrom(String? value) {
    for (final sort in values) {
      if (sort.wire == value) return sort;
    }
    return null;
  }
}

@immutable
final class PropertySearchParams {
  const PropertySearchParams({
    this.locationId,
    this.stay,
    this.guests,
    this.priceMin,
    this.priceMax,
    this.minBedrooms,
    this.minBathrooms,
    this.amenityKeys = const {},
    this.propertyTypes = const {},
    this.sort,
  });

  final String? locationId;
  final StayRange? stay;
  final int? guests;
  final Money? priceMin;
  final Money? priceMax;
  final int? minBedrooms;
  final int? minBathrooms;
  final Set<String> amenityKeys;
  final Set<String> propertyTypes;
  final SearchSort? sort;

  @override
  bool operator ==(Object other) =>
      other is PropertySearchParams &&
      other.locationId == locationId &&
      other.stay == stay &&
      other.guests == guests &&
      other.priceMin == priceMin &&
      other.priceMax == priceMax &&
      other.minBedrooms == minBedrooms &&
      other.minBathrooms == minBathrooms &&
      setEquals(other.amenityKeys, amenityKeys) &&
      setEquals(other.propertyTypes, propertyTypes) &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(
    locationId,
    stay,
    guests,
    priceMin,
    priceMax,
    minBedrooms,
    minBathrooms,
    Object.hashAllUnordered(amenityKeys),
    Object.hashAllUnordered(propertyTypes),
    sort,
  );
}

@immutable
final class ResultsPage {
  const ResultsPage({
    required this.items,
    required this.nextCursor,
    required this.totalCount,
  });

  factory ResultsPage.fromJson(Map<String, dynamic> json) => ResultsPage(
    items: [
      for (final raw in json['items'] as List? ?? const [])
        ListingCard.fromJson(Map<String, dynamic>.from(raw as Map)),
    ],
    nextCursor: json['next_cursor'] as String?,
    totalCount: json['total_count'] as int,
  );

  /// A null [nextCursor] means the end of the list.
  final List<ListingCard> items;
  final String? nextCursor;
  final int totalCount;

  @override
  bool operator ==(Object other) =>
      other is ResultsPage &&
      listEquals(other.items, items) &&
      other.nextCursor == nextCursor &&
      other.totalCount == totalCount;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    nextCursor,
    totalCount,
  );
}
