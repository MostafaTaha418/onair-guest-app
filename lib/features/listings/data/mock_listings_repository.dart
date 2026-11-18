import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/listings/domain/results_page.dart';

const _fixturesRoot = 'lib/features/listings/data/fixtures';

/// In-memory repository over the JSON fixtures (research R18). It applies the
/// same rules as the server: published only, full-stay availability (AC-012),
/// final-price filters, and Arabic-normalised location search.
final class MockListingsRepository implements ListingsRepository {
  MockListingsRepository({
    Future<String> Function(String path)? loader,
    Duration latency = const Duration(milliseconds: 300),
  }) : this._(loader ?? rootBundle.loadString, latency);

  MockListingsRepository._(this._loader, this._latency);

  final Future<String> Function(String path) _loader;
  final Duration _latency;

  List<Map<String, dynamic>>? _properties;
  Map<String, List<Map<String, dynamic>>>? _reviews;
  List<Map<String, dynamic>>? _locations;
  HomeFeed? _homeFeed;
  ReferenceData? _reference;

  Future<void> _delay() async {
    if (_latency > Duration.zero) {
      await Future<void>.delayed(_latency);
    }
  }

  Future<List<Map<String, dynamic>>> get properties async =>
      _properties ??= _decodeList(
        jsonDecode(await _loader('$_fixturesRoot/properties.json'))
            as List<dynamic>,
      );

  Future<Map<String, List<Map<String, dynamic>>>> get _reviewsJson async =>
      _reviews ??= {
        for (final entry in _decodeMap(
          jsonDecode(await _loader('$_fixturesRoot/reviews.json'))
              as Map<dynamic, dynamic>,
        ).entries)
          entry.key: _decodeList(entry.value as List<dynamic>),
      };

  Future<List<Map<String, dynamic>>> get locations async =>
      _locations ??= _decodeList(
        jsonDecode(await _loader('$_fixturesRoot/locations.json'))
            as List<dynamic>,
      );

  @override
  Future<HomeFeed> homeFeed() async {
    return _homeFeed ??= await _loadHomeFeed();
  }

  Future<HomeFeed> _loadHomeFeed() async {
    await _delay();
    return HomeFeed.fromJson(
      _decodeMap(
        jsonDecode(await _loader('$_fixturesRoot/home_feed.json'))
            as Map<dynamic, dynamic>,
      ),
    );
  }

  @override
  Future<ReferenceData> referenceData() async {
    return _reference ??= await _loadReference();
  }

  Future<ReferenceData> _loadReference() async {
    await _delay();
    return ReferenceData.fromJson(
      _decodeMap(
        jsonDecode(await _loader('$_fixturesRoot/reference.json'))
            as Map<dynamic, dynamic>,
      ),
    );
  }

  @override
  Future<ResultsPage> searchProperties(
    PropertySearchParams params, {
    String? cursor,
    int limit = 20,
  }) async {
    await _delay();
    final offset = _parseCursor(cursor);
    final matching = await _matchingCards(params);
    final items = matching.skip(offset).take(limit).toList();
    final nextCursor = offset + limit < matching.length
        ? '${offset + limit}'
        : null;
    return ResultsPage(
      items: items,
      nextCursor: nextCursor,
      totalCount: matching.length,
    );
  }

  @override
  Future<int> countProperties(PropertySearchParams params) async {
    await _delay();
    return (await _matchingCards(params)).length;
  }

  @override
  Future<List<LocationSuggestion>> searchLocations(String query) async {
    await _delay();
    final trimmed = query.trim();
    if (trimmed.length < 2 || trimmed.length > 60) return [];
    final wanted = normalizeArabic(trimmed);
    final byId = {
      for (final location in await locations)
        location['id'] as String: location,
    };
    String? parentLabelOf(Map<String, dynamic> location) {
      final parentId = location['parent_id'] as String?;
      if (parentId == null) return null;
      return byId[parentId]?['name'] as String?;
    }

    final matches =
        [
          for (final location in await locations)
            if (normalizeArabic(location['name'] as String).contains(wanted))
              LocationSuggestion(
                id: location['id'] as String,
                level: LocationLevel.fromWire(location['level'] as String),
                name: location['name'] as String,
                parentLabel: parentLabelOf(location),
                listingCount: location['listing_count'] as int? ?? 0,
              ),
        ]..sort((a, b) {
          final byMatch = _startsWithRank(b.name, wanted).compareTo(
            _startsWithRank(a.name, wanted),
          );
          if (byMatch != 0) return byMatch;
          return b.listingCount.compareTo(a.listingCount);
        });
    return matches;
  }

  @override
  Future<PropertyDetails> property(String id) async {
    await _delay();
    final all = await properties;
    for (final json in all) {
      if (json['id'] == id && json['_published'] == true) {
        return PropertyDetails.fromJson(_publishedJson(json));
      }
    }
    throw _notFound();
  }

  @override
  Future<Set<DateOnly>> unavailableNights(
    String id,
    DateOnly from,
    DateOnly to,
  ) async {
    await _delay();
    final all = await properties;
    for (final json in all) {
      if (json['id'] == id && json['_published'] == true) {
        final busy = _busyDates(json);
        final today = CairoTime.today();
        return {
          for (final night in busy)
            if (!night.isBefore(from) && night.isBefore(to)) night,
          // The past is unavailable like any other reason (contract §4).
          for (var night = from; night.isBefore(to); night = night.addDays(1))
            if (night.isBefore(today)) night,
        };
      }
    }
    throw _notFound();
  }

  @override
  Future<ReviewsPage> reviews(
    String id, {
    String? cursor,
    int limit = 20,
  }) async {
    await _delay();
    final all = await properties;
    final exists = all.any(
      (json) => json['id'] == id && json['_published'] == true,
    );
    if (!exists) throw _notFound();

    final approved =
        [
          for (final review
              in (await _reviewsJson)[id] ?? const <Map<String, dynamic>>[])
            if (review['status'] == 'approved')
              ApprovedReview.fromJson(
                Map<String, dynamic>.from(review),
              ),
        ]..sort(
          (a, b) => b.createdOn.toString().compareTo(a.createdOn.toString()),
        );
    final offset = _parseCursor(cursor);
    final items = approved.skip(offset).take(limit).toList();
    return ReviewsPage(
      items: items,
      nextCursor: offset + limit < approved.length ? '${offset + limit}' : null,
    );
  }

  // -- helpers ---------------------------------------------------------------

  Map<String, dynamic> _publishedJson(Map<String, dynamic> json) =>
      Map<String, dynamic>.from(json)
        ..removeWhere((key, _) => key.startsWith('_'));

  List<ListingCard> _cardsOf(Iterable<Map<String, dynamic>> jsons) => [
    for (final json in jsons)
      ListingCard.fromJson({
        ..._publishedJson(json),
        'cover': (json['images'] as List? ?? const []).isEmpty
            ? null
            : (json['images'] as List).first,
      }),
  ];

  Future<List<ListingCard>> _matchingCards(PropertySearchParams params) async {
    final all = await properties;
    final published = all.where((json) => json['_published'] == true).toList();
    final cards = _cardsOf(published);
    final busyDates = {
      for (final json in published) json['id'] as String: _busyDates(json),
    };
    final cardsWithStay = params.stay == null
        ? cards
        : [
            for (final card in cards)
              ListingCard(
                id: card.id,
                title: card.title,
                propertyType: card.propertyType,
                areaName: card.areaName,
                cityName: card.cityName,
                cover: card.cover,
                nightlyPrice: card.nightlyPrice,
                ratingAvg: card.ratingAvg,
                reviewCount: card.reviewCount,
                // The server computes stay totals; the mock mirrors the shape
                // with nightly × nights for display only (research R5 keeps
                // the real rule server-side).
                stay: CardStay(
                  nights: params.stay!.nights,
                  stayTotal: Money(
                    card.nightlyPrice.amountMinor * params.stay!.nights,
                  ),
                ),
              ),
          ];

    final filtered = [
      for (final card in cardsWithStay)
        if (_matches(
          card,
          published.firstWhere((json) => json['id'] == card.id),
          params,
          busyDates[card.id] ?? const {},
        ))
          card,
    ];

    return _sorted(filtered, params.sort);
  }

  bool _matches(
    ListingCard card,
    Map<String, dynamic> json,
    PropertySearchParams params,
    Set<DateOnly> busy,
  ) {
    if (params.locationId != null &&
        !(json['_location_ids'] as List).contains(params.locationId)) {
      return false;
    }
    final stay = params.stay;
    if (stay != null && !stay.isSelectable(busy)) return false;
    final guests = params.guests;
    if (guests != null && (json['max_guests'] as int) < guests) return false;
    final priceMin = params.priceMin;
    if (priceMin != null &&
        card.nightlyPrice.amountMinor < priceMin.amountMinor) {
      return false;
    }
    final priceMax = params.priceMax;
    if (priceMax != null &&
        card.nightlyPrice.amountMinor > priceMax.amountMinor) {
      return false;
    }
    if (params.minBedrooms != null &&
        (json['bedrooms'] as int) < params.minBedrooms!) {
      return false;
    }
    if (params.minBathrooms != null &&
        (json['bathrooms'] as int) < params.minBathrooms!) {
      return false;
    }
    final amenities = (json['_amenity_keys'] as List).toSet();
    if (!params.amenityKeys.every(amenities.contains)) return false;
    if (params.propertyTypes.isNotEmpty &&
        !params.propertyTypes.contains(card.propertyType)) {
      return false;
    }
    return true;
  }

  List<ListingCard> _sorted(List<ListingCard> cards, SearchSort? sort) {
    final sorted = [...cards];
    switch (sort) {
      case SearchSort.priceAsc:
        sorted.sort(
          (a, b) => a.nightlyPrice.amountMinor.compareTo(
            b.nightlyPrice.amountMinor,
          ),
        );
      case SearchSort.priceDesc:
        sorted.sort(
          (a, b) => b.nightlyPrice.amountMinor.compareTo(
            a.nightlyPrice.amountMinor,
          ),
        );
      case SearchSort.newest || null:
        // Newest first; the fixtures carry _created_at on the property.
        sorted.sort((a, b) => _createdAtOf(b.id).compareTo(_createdAtOf(a.id)));
    }
    return sorted;
  }

  final Map<String, String> _createdAtCache = {};

  String _createdAtOf(String id) {
    // The creation date lives on the raw fixture; cache it after first look.
    return _createdAtCache.putIfAbsent(id, () {
      for (final json in _properties ?? const <Map<String, dynamic>>[]) {
        if (json['id'] == id) return json['_created_at'] as String;
      }
      return '';
    });
  }

  Set<DateOnly> _busyDates(Map<String, dynamic> json) {
    final offsets = json['_busy_offsets'] as Map?;
    if (offsets == null) return {};
    final today = CairoTime.today();
    return {
      for (final list in offsets.values)
        for (final offset in list as List) today.addDays(offset as int),
    };
  }

  int _startsWithRank(String name, String query) =>
      normalizeArabic(name).startsWith(query) ? 1 : 0;

  int _parseCursor(String? cursor) {
    if (cursor == null) return 0;
    final offset = int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw AppFailure(ErrorMapper.fromCode('VALIDATION_FAILED'));
    }
    return offset;
  }

  AppFailure _notFound() => AppFailure(ErrorMapper.fromCode('NOT_FOUND'));

  List<Map<String, dynamic>> _decodeList(List<dynamic> raw) => [
    for (final item in raw) Map<String, dynamic>.from(item as Map),
  ];

  Map<String, dynamic> _decodeMap(Map<dynamic, dynamic> raw) =>
      Map<String, dynamic>.from(raw);
}

/// Arabic normalisation shared by search and fixtures:
/// أإآ→ا، ة→ه، ى→ي; tatweel and diacritics removed (research R7).
String normalizeArabic(String input) {
  const tatweel = '\u0640';
  const diacritics = [
    '\u064B',
    '\u064C',
    '\u064D',
    '\u064E',
    '\u064F',
    '\u0650',
    '\u0651',
    '\u0652',
  ];
  var output = input.replaceAll(tatweel, '');
  for (final diacritic in diacritics) {
    output = output.replaceAll(diacritic, '');
  }
  return output
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
}
