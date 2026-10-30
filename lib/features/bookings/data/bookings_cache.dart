import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';

/// One cached tab page with the moment it was fetched (for «Last updated»).
final class CachedTab {
  const CachedTab({required this.items, required this.fetchedAt});

  final List<BookingSummary> items;
  final DateTime fetchedAt;
}

/// One cached details document with the moment it was fetched.
final class CachedDetails {
  const CachedDetails({required this.details, required this.fetchedAt});

  final BookingDetails details;
  final DateTime fetchedAt;
}

/// The offline copy of bookings (research R13): the first page of each tab
/// and every viewed details document. Arrival instructions are never written
/// here — `toCacheJson` strips them before the model reaches this class.
///
/// Document layout:
/// ```json
/// {
///   "tabs": { "current": { "fetched_at": "...", "items": [...] } },
///   "details": { "<id>": { "fetched_at": "...", "data": {...} } }
/// }
/// ```
final class BookingsCache {
  BookingsCache(this._cache);

  final JsonFileCache _cache;

  Future<Map<String, dynamic>?> _document() => _cache.read();

  Future<CachedTab?> readTab(BookingTab tab) async {
    final document = await _document();
    final tabs = document?['tabs'];
    if (tabs is! Map<String, dynamic>) return null;
    final raw = tabs[tab.wire];
    if (raw is! Map<String, dynamic>) return null;
    final fetchedAt = raw['fetched_at'];
    final items = raw['items'];
    if (fetchedAt is! String || items is! List) return null;
    return CachedTab(
      items: [
        for (final item in items)
          BookingSummary.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      fetchedAt: DateTime.parse(fetchedAt),
    );
  }

  Future<void> saveTab(BookingTab tab, List<BookingSummary> items) async {
    final document = await _document() ?? const <String, dynamic>{};
    final tabs = Map<String, dynamic>.from(document['tabs'] as Map? ?? {});
    tabs[tab.wire] = {
      'fetched_at': DateTime.now().toUtc().toIso8601String(),
      'items': [for (final item in items) item.toJson()],
    };
    await _cache.write({...document, 'tabs': tabs});
  }

  Future<CachedDetails?> readDetails(String id) async {
    final document = await _document();
    final details = document?['details'];
    if (details is! Map<String, dynamic>) return null;
    final raw = details[id];
    if (raw is! Map<String, dynamic>) return null;
    final fetchedAt = raw['fetched_at'];
    final data = raw['data'];
    if (fetchedAt is! String || data is! Map<String, dynamic>) return null;
    return CachedDetails(
      details: BookingDetails.fromJson(data),
      fetchedAt: DateTime.parse(fetchedAt),
    );
  }

  Future<void> saveDetails(BookingDetails details) async {
    final document = await _document() ?? const <String, dynamic>{};
    final all = Map<String, dynamic>.from(document['details'] as Map? ?? {});
    all[details.id] = {
      'fetched_at': DateTime.now().toUtc().toIso8601String(),
      // Never `details.toJson()`: that would carry the instructions.
      'data': details.toCacheJson(),
    };
    await _cache.write({...document, 'details': all});
  }

  Future<void> clear() => _cache.clear();
}
