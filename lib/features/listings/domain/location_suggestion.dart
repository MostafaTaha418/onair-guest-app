import 'package:flutter/foundation.dart';

enum LocationLevel {
  governorate,
  city,
  area;

  static LocationLevel fromWire(String value) => switch (value) {
    'governorate' => governorate,
    'city' => city,
    'area' => area,
    _ => throw FormatException('Unknown location level: $value'),
  };
}

@immutable
final class LocationSuggestion {
  const LocationSuggestion({
    required this.id,
    required this.level,
    required this.name,
    required this.parentLabel,
    required this.listingCount,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) =>
      LocationSuggestion(
        id: json['id'] as String,
        level: LocationLevel.fromWire(json['level'] as String),
        name: json['name'] as String,
        parentLabel: json['parent_label'] as String?,
        listingCount: json['listing_count'] as int? ?? 0,
      );

  final String id;
  final LocationLevel level;
  final String name;
  final String? parentLabel;
  final int listingCount;

  @override
  bool operator ==(Object other) =>
      other is LocationSuggestion &&
      other.id == id &&
      other.level == level &&
      other.name == name &&
      other.parentLabel == parentLabel &&
      other.listingCount == listingCount;

  @override
  int get hashCode => Object.hash(id, level, name, parentLabel, listingCount);
}
