import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';

/// Long-lived cache for the reference lists, refreshed when the server
/// version changes (research R7). Shares the discovery cache file with Home
/// under the `reference` key and never drops the `home` key.
final class ReferenceDataCache {
  ReferenceDataCache(this._repo, this._cache);

  final ListingsRepository _repo;
  final JsonFileCache _cache;

  ReferenceData? _memory;

  /// The reference data, from memory or disk; the repository is only called
  /// when nothing is cached yet.
  Future<ReferenceData> load() async {
    final cached = _memory ?? await _readDisk();
    if (cached != null) {
      _memory = cached;
      return cached;
    }
    return _fetchAndStore();
  }

  /// Refetches when [version] differs from the cached one (FR-008).
  Future<void> refreshIfVersionChanged(String version) async {
    final cached = _memory ?? await _readDisk();
    if (cached != null && cached.version == version) return;
    try {
      await _fetchAndStore();
    } on AppFailure catch (_) {
      // Without a cache there is nothing to fall back to; rethrow.
      if (cached == null) rethrow;
    }
  }

  Future<ReferenceData?> _readDisk() async {
    final document = await _cache.read();
    final stored = document?['reference'];
    if (stored is! Map<String, dynamic>) return null;
    try {
      return ReferenceData.fromJson(stored);
    } on Object {
      return null;
    }
  }

  Future<ReferenceData> _fetchAndStore() async {
    final data = await _repo.referenceData();
    _memory = data;
    // Read-modify-write so Home's cached sections survive.
    final document = await _cache.read() ?? <String, dynamic>{};
    document['reference'] = data.toJson();
    await _cache.write(document);
    return data;
  }
}
