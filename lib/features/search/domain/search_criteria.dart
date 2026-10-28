import 'package:flutter/foundation.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/results_page.dart';

export 'package:on_air/features/listings/domain/results_page.dart'
    show SearchSort;

enum FilterChipKind { price, bedrooms, bathrooms, amenity, type }

/// One removable filter chip. Labels live in the UI layer only.
@immutable
final class FilterChipData {
  const FilterChipData({required this.kind, this.key});

  final FilterChipKind kind;

  /// The amenity or property-type key; null for price/bedrooms/bathrooms.
  final String? key;

  @override
  bool operator ==(Object other) =>
      other is FilterChipData && other.kind == kind && other.key == key;

  @override
  int get hashCode => Object.hash(kind, key);
}

/// One codec for the shared link, the `/search/results` location, and the
/// stored last search (research R13). Unknown keys are ignored; an invalid
/// value drops only its own field; past or inverted dates drop both and set
/// [datesDropped]. Carries no UI text.
@immutable
final class SearchCriteria {
  const SearchCriteria({
    this.locationId,
    this.locationLabel,
    this.stay,
    this.guests,
    this.priceMin,
    this.priceMax,
    this.minBedrooms,
    this.minBathrooms,
    this.amenityKeys = const {},
    this.propertyTypes = const {},
    this.sort,
    this.datesDropped = false,
  });

  /// No filters at all: "all published apartments".
  static const SearchCriteria empty = SearchCriteria();

  static final _uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _keyPattern = RegExp(r'^[a-z0-9_]{1,40}$');

  final String? locationId;

  /// Display only; never written to links (re-resolved when needed).
  final String? locationLabel;
  final StayRange? stay;
  final int? guests;
  final Money? priceMin;
  final Money? priceMax;
  final int? minBedrooms;
  final int? minBathrooms;
  final Set<String> amenityKeys;
  final Set<String> propertyTypes;
  final SearchSort? sort;

  /// True when the link carried dates that had to be dropped (US5 scenario 5);
  /// a display notice only, so it is excluded from [==].
  final bool datesDropped;

  // Parsing with validation and date rules; not a plain constructor.
  // ignore: prefer_constructors_over_static_methods
  static SearchCriteria fromQuery(
    Map<String, String> query, {
    required DateOnly today,
  }) {
    final rawLocation = query['loc'];
    final locationId = rawLocation != null && _uuidV4.hasMatch(rawLocation)
        ? rawLocation
        : null;

    final checkIn = DateOnly.tryParse(query['in']);
    final checkOut = DateOnly.tryParse(query['out']);
    final stay = StayRange.tryCreate(checkIn, checkOut, today);
    final datesDropped = (checkIn != null || checkOut != null) && stay == null;

    var priceMin = _price(query['pmin']);
    var priceMax = _price(query['pmax']);
    if (priceMin != null &&
        priceMax != null &&
        priceMin.amountMinor > priceMax.amountMinor) {
      final swap = priceMin;
      priceMin = priceMax;
      priceMax = swap;
    }

    return SearchCriteria(
      locationId: locationId,
      stay: stay,
      guests: _boundedInt(query['g'], 1, 50),
      priceMin: priceMin,
      priceMax: priceMax,
      minBedrooms: _zeroMeansAny(_boundedInt(query['bed'], 0, 20)),
      minBathrooms: _zeroMeansAny(_boundedInt(query['bath'], 0, 20)),
      amenityKeys: _keys(query['am']),
      propertyTypes: _keys(query['type']),
      sort: SearchSort.tryFrom(query['sort']),
      datesDropped: datesDropped,
    );
  }

  /// Canonical encoding: keys sorted, empty fields left out, so equal
  /// criteria give equal URLs.
  Map<String, String> toQuery() => {
    if (amenityKeys.isNotEmpty) 'am': (amenityKeys.toList()..sort()).join(','),
    if (minBathrooms != null) 'bath': '${minBathrooms!}',
    if (minBedrooms != null) 'bed': '${minBedrooms!}',
    if (guests != null) 'g': '${guests!}',
    if (stay != null) 'in': stay!.checkIn.toString(),
    'loc': ?locationId,
    if (stay != null) 'out': stay!.checkOut.toString(),
    if (priceMax != null) 'pmax': '${priceMax!.amountMinor}',
    if (priceMin != null) 'pmin': '${priceMin!.amountMinor}',
    if (sort != null) 'sort': sort!.wire,
    if (propertyTypes.isNotEmpty)
      'type': (propertyTypes.toList()..sort()).join(','),
  };

  PropertySearchParams toParams() => PropertySearchParams(
    locationId: locationId,
    stay: stay,
    guests: guests,
    priceMin: priceMin,
    priceMax: priceMax,
    minBedrooms: minBedrooms,
    minBathrooms: minBathrooms,
    amenityKeys: amenityKeys,
    propertyTypes: propertyTypes,
    sort: sort,
  );

  /// Location, dates, and guests are shown in the summary bar, not as chips.
  List<FilterChipData> get activeFilterChips => [
    if (priceMin != null || priceMax != null)
      const FilterChipData(kind: FilterChipKind.price),
    if (minBedrooms != null)
      const FilterChipData(kind: FilterChipKind.bedrooms),
    if (minBathrooms != null)
      const FilterChipData(kind: FilterChipKind.bathrooms),
    for (final key in amenityKeys)
      FilterChipData(kind: FilterChipKind.amenity, key: key),
    for (final key in propertyTypes)
      FilterChipData(kind: FilterChipKind.type, key: key),
  ];

  SearchCriteria withoutChip(FilterChipData chip) => SearchCriteria(
    locationId: locationId,
    locationLabel: locationLabel,
    stay: stay,
    guests: guests,
    priceMin: chip.kind == FilterChipKind.price ? null : priceMin,
    priceMax: chip.kind == FilterChipKind.price ? null : priceMax,
    minBedrooms: chip.kind == FilterChipKind.bedrooms ? null : minBedrooms,
    minBathrooms: chip.kind == FilterChipKind.bathrooms ? null : minBathrooms,
    amenityKeys: chip.kind == FilterChipKind.amenity
        ? ({...amenityKeys}..remove(chip.key))
        : amenityKeys,
    propertyTypes: chip.kind == FilterChipKind.type
        ? ({...propertyTypes}..remove(chip.key))
        : propertyTypes,
    sort: sort,
  );

  /// Clears the location and its label («كل الأماكن»).
  SearchCriteria withoutLocation() => SearchCriteria(
    stay: stay,
    guests: guests,
    priceMin: priceMin,
    priceMax: priceMax,
    minBedrooms: minBedrooms,
    minBathrooms: minBathrooms,
    amenityKeys: amenityKeys,
    propertyTypes: propertyTypes,
    sort: sort,
  );

  /// Sentinel so an explicit null replaces the old value (clearing a field).
  static const _unset = Object();

  SearchCriteria copyWith({
    Object? locationId = _unset,
    Object? locationLabel = _unset,
    StayRange? stay,
    Object? guests = _unset,
    Object? priceMin = _unset,
    Object? priceMax = _unset,
    Object? minBedrooms = _unset,
    Object? minBathrooms = _unset,
    Set<String>? amenityKeys,
    Set<String>? propertyTypes,
    Object? sort = _unset,
    bool? datesDropped,
  }) => SearchCriteria(
    locationId: locationId == _unset ? this.locationId : locationId as String?,
    locationLabel: locationLabel == _unset
        ? this.locationLabel
        : locationLabel as String?,
    stay: stay ?? this.stay,
    guests: guests == _unset ? this.guests : guests as int?,
    priceMin: priceMin == _unset ? this.priceMin : priceMin as Money?,
    priceMax: priceMax == _unset ? this.priceMax : priceMax as Money?,
    minBedrooms: minBedrooms == _unset ? this.minBedrooms : minBedrooms as int?,
    minBathrooms: minBathrooms == _unset
        ? this.minBathrooms
        : minBathrooms as int?,
    amenityKeys: amenityKeys ?? this.amenityKeys,
    propertyTypes: propertyTypes ?? this.propertyTypes,
    sort: sort == _unset ? this.sort : sort as SearchSort?,
    datesDropped: datesDropped ?? this.datesDropped,
  );

  static int? _boundedInt(String? raw, int min, int max) {
    final value = raw == null ? null : int.tryParse(raw);
    if (value == null || value < min || value > max) return null;
    return value;
  }

  static int? _zeroMeansAny(int? value) => value == 0 ? null : value;

  static Money? _price(String? raw) {
    final value = raw == null ? null : int.tryParse(raw);
    if (value == null || value < 0) return null;
    return Money(value);
  }

  static Set<String> _keys(String? raw) {
    if (raw == null) return const {};
    final keys = raw
        .split(',')
        .map((key) => key.trim())
        .where(_keyPattern.hasMatch)
        .toSet();
    return keys.length <= 30 ? keys : keys.take(30).toSet();
  }

  // [datesDropped] is a display notice, not filter state, so two criteria
  // that differ only in it are still the same search.
  @override
  bool operator ==(Object other) =>
      other is SearchCriteria &&
      other.locationId == locationId &&
      other.locationLabel == locationLabel &&
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
    locationLabel,
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
