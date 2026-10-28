import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';

@immutable
final class Amenity {
  const Amenity({required this.key, required this.label, required this.icon});

  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
    key: json['key'] as String,
    label: json['label'] as String,
    icon: json['icon'] as String?,
  );

  final String key;
  final String label;
  final String? icon;

  Map<String, dynamic> toJson() => {'key': key, 'label': label, 'icon': icon};

  @override
  bool operator ==(Object other) =>
      other is Amenity &&
      other.key == key &&
      other.label == label &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(key, label, icon);
}

@immutable
final class PropertyTypeOption {
  const PropertyTypeOption({required this.key, required this.label});

  factory PropertyTypeOption.fromJson(Map<String, dynamic> json) =>
      PropertyTypeOption(
        key: json['key'] as String,
        label: json['label'] as String,
      );

  final String key;
  final String label;

  Map<String, dynamic> toJson() => {'key': key, 'label': label};

  @override
  bool operator ==(Object other) =>
      other is PropertyTypeOption && other.key == key && other.label == label;

  @override
  int get hashCode => Object.hash(key, label);
}

/// Amenities, property types, and nightly price bounds, cached long and
/// refreshed when [version] changes (research R7).
@immutable
final class ReferenceData {
  const ReferenceData({
    required this.version,
    required this.amenities,
    required this.propertyTypes,
    required this.priceMin,
    required this.priceMax,
    required this.priceStep,
  });

  factory ReferenceData.fromJson(Map<String, dynamic> json) {
    final bounds = Map<String, dynamic>.from(json['price_bounds'] as Map);
    return ReferenceData(
      version: json['version'] as String,
      amenities: [
        for (final raw in json['amenities'] as List? ?? const [])
          Amenity.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      propertyTypes: [
        for (final raw in json['property_types'] as List? ?? const [])
          PropertyTypeOption.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      priceMin: Money(
        bounds['min_minor'] as int,
        currency: bounds['currency'] as String? ?? 'EGP',
      ),
      priceMax: Money(
        bounds['max_minor'] as int,
        currency: bounds['currency'] as String? ?? 'EGP',
      ),
      priceStep: json['price_step_minor'] == null
          ? Money(5000)
          : Money(json['price_step_minor'] as int),
    );
  }

  final String version;
  final List<Amenity> amenities;
  final List<PropertyTypeOption> propertyTypes;
  final Money priceMin;
  final Money priceMax;
  final Money priceStep;

  Map<String, dynamic> toJson() => {
    'version': version,
    'amenities': [for (final amenity in amenities) amenity.toJson()],
    'property_types': [
      for (final type in propertyTypes) type.toJson(),
    ],
    'price_bounds': {
      'min_minor': priceMin.amountMinor,
      'max_minor': priceMax.amountMinor,
      'currency': priceMin.currency,
    },
    'price_step_minor': priceStep.amountMinor,
  };

  @override
  bool operator ==(Object other) =>
      other is ReferenceData &&
      other.version == version &&
      listEquals(other.amenities, amenities) &&
      listEquals(other.propertyTypes, propertyTypes) &&
      other.priceMin == priceMin &&
      other.priceMax == priceMax &&
      other.priceStep == priceStep;

  @override
  int get hashCode => Object.hash(
    version,
    Object.hashAll(amenities),
    Object.hashAll(propertyTypes),
    priceMin,
    priceMax,
    priceStep,
  );
}
