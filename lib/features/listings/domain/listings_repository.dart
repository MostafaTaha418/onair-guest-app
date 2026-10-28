import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/listings/domain/approved_review.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';
import 'package:on_air/features/listings/domain/property_details.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/listings/domain/results_page.dart';

/// The single discovery data layer for Home, Search, and Property
/// (Constitution VII). Every method throws `AppFailure` on error.
abstract interface class ListingsRepository {
  /// The Home feed; failing sections are reported, not raised (research R6).
  Future<HomeFeed> homeFeed();

  /// Server-filtered results with keyset pagination (research R4). With dates
  /// the server excludes apartments that are unavailable for any night
  /// (AC-012). A null cursor means the end of the list.
  Future<ResultsPage> searchProperties(
    PropertySearchParams params, {
    String? cursor,
    int limit = 20,
  });

  /// The count behind `searchProperties`; the filters sheet calls it with
  /// `p_limit = 0` server-side.
  Future<int> countProperties(PropertySearchParams params);

  /// Arabic-normalised location matches; a query shorter than two characters
  /// yields an empty list.
  Future<List<LocationSuggestion>> searchLocations(String query);

  /// Reference lists and price bounds; refresh by version (research R7).
  Future<ReferenceData> referenceData();

  /// Full details of a published apartment. Unknown and unpublished IDs give
  /// the same NOT_FOUND so existence is never revealed (AC-003).
  Future<PropertyDetails> property(String id);

  /// Unavailable nights in `[from, to)`, for any reason, with no further
  /// detail (research R2).
  Future<Set<DateOnly>> unavailableNights(
    String id,
    DateOnly from,
    DateOnly to,
  );

  /// Approved reviews, newest first (research R16).
  Future<ReviewsPage> reviews(String id, {String? cursor, int limit = 20});
}
