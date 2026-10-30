import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads discovery data through the `guest_*` RPCs
/// (contracts/supabase-discovery.md). Nothing but this class talks to
/// Supabase for discovery (Constitution VII).
final class SupabaseListingsRepository implements ListingsRepository {
  SupabaseListingsRepository({
    required Future<dynamic> Function(String fn, Map<String, dynamic> params)
    rpc,
  }) : this._(rpc);

  SupabaseListingsRepository._(this._rpc);

  final Future<dynamic> Function(String fn, Map<String, dynamic> params) _rpc;

  @override
  Future<HomeFeed> homeFeed() => _guard(() async {
    final response = await _rpc('guest_home_feed', {'p_locale': 'ar'});
    return HomeFeed.fromJson(_asMap(response));
  });

  @override
  Future<ResultsPage> searchProperties(
    PropertySearchParams params, {
    String? cursor,
    int limit = 20,
  }) => _guard(() async {
    final response = await _rpc('guest_search_properties', {
      ..._searchParams(params, cursor: cursor),
      'p_limit': limit,
    });
    return ResultsPage.fromJson(_asMap(response));
  });

  @override
  Future<int> countProperties(PropertySearchParams params) => _guard(() async {
    final response = await _rpc('guest_search_properties', {
      ..._searchParams(params),
      'p_limit': 0,
    });
    return _asMap(response)['total_count'] as int;
  });

  @override
  Future<List<LocationSuggestion>> searchLocations(String query) =>
      _guard(() async {
        final rows = await _rpc('guest_search_locations', {
          'p_query': query,
          'p_limit': 10,
        });
        return [
          for (final row in _asList(rows))
            LocationSuggestion.fromJson(_asMap(row)),
        ];
      });

  @override
  Future<ReferenceData> referenceData() => _guard(() async {
    final response = await _rpc('guest_get_reference_data', {
      'p_locale': 'ar',
    });
    return ReferenceData.fromJson(_asMap(response));
  });

  @override
  Future<PropertyDetails> property(String id) => _guard(() async {
    final response = await _rpc('guest_get_property', {
      'p_property_id': id,
      'p_locale': 'ar',
    });
    // Unknown, unpublished, and paused IDs are indistinguishable, so an
    // empty answer is NOT_FOUND and existence is never revealed (AC-003).
    if (response == null) {
      throw AppFailure(ErrorMapper.fromCode('NOT_FOUND'));
    }
    return PropertyDetails.fromJson(_asMap(response));
  });

  @override
  Future<Set<DateOnly>> unavailableNights(
    String id,
    DateOnly from,
    DateOnly to,
  ) => _guard(() async {
    final rows = await _rpc('guest_get_property_unavailable_dates', {
      'p_property_id': id,
      'p_from': from.toString(),
      'p_to': to.toString(),
    });
    return {
      for (final row in _asList(rows).cast<String>()) DateOnly.parse(row),
    };
  });

  @override
  Future<ReviewsPage> reviews(
    String id, {
    String? cursor,
    int limit = 20,
  }) => _guard(() async {
    final response = await _rpc('guest_list_property_reviews', {
      'p_property_id': id,
      'p_cursor': ?cursor,
      'p_limit': limit,
    });
    return ReviewsPage.fromJson(_asMap(response));
  });

  Map<String, dynamic> _searchParams(
    PropertySearchParams params, {
    String? cursor,
  }) => {
    if (params.locationId != null) 'p_location_id': params.locationId,
    if (params.stay != null) 'p_check_in': params.stay!.checkIn.toString(),
    if (params.stay != null) 'p_check_out': params.stay!.checkOut.toString(),
    if (params.guests != null) 'p_guests': params.guests,
    if (params.priceMin != null)
      'p_price_min_minor': params.priceMin!.amountMinor,
    if (params.priceMax != null)
      'p_price_max_minor': params.priceMax!.amountMinor,
    if (params.minBedrooms != null) 'p_min_bedrooms': params.minBedrooms,
    if (params.minBathrooms != null) 'p_min_bathrooms': params.minBathrooms,
    if (params.amenityKeys.isNotEmpty)
      'p_amenity_keys': params.amenityKeys.toList()..sort(),
    if (params.propertyTypes.isNotEmpty)
      'p_property_types': params.propertyTypes.toList()..sort(),
    if (params.sort != null) 'p_sort': params.sort!.wire,
    'p_cursor': ?cursor,
  };

  /// One wrapper for every call, covering the RPC round-trip and the
  /// response parsing alike: known PostgREST codes map through
  /// [ErrorMapper], transport failures become network errors, a malformed
  /// or null payload is internal, and an [AppFailure] from the action (a
  /// deliberate NOT_FOUND) passes through unchanged. Request parameters are
  /// never logged.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      final code = [error.message, ?error.code].firstWhere(
        ErrorMapper.hasCode,
        orElse: () => 'INTERNAL',
      );
      throw AppFailure(ErrorMapper.fromCode(code));
    } on SocketException {
      throw AppFailure(ErrorMapper.noResponse());
    } on TimeoutException {
      throw AppFailure(ErrorMapper.noResponse());
    } on http.ClientException {
      throw AppFailure(ErrorMapper.noResponse());
    } on AppFailure {
      rethrow;
    } on Object {
      throw AppFailure(ErrorMapper.fromCode('INTERNAL'));
    }
  }

  static Map<String, dynamic> _asMap(Object? value) =>
      Map<String, dynamic>.from(value! as Map);

  static List<Object?> _asList(Object? value) =>
      List<Object?>.from(value! as List);
}
