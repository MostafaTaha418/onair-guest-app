import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';

/// The stale-while-revalidate Home cache (research R6): the public sections
/// live under the `home` key of the shared `discovery_cache.json` document;
/// the personal upcoming booking is never written (Constitution III).
final class HomeFeedCache {
  HomeFeedCache(this._cache);

  final JsonFileCache _cache;

  static const _homeKey = 'home';

  Future<void> save(HomeFeed feed) async {
    // Read-modify-write so the `reference` key in the same file survives.
    final document = await _cache.read() ?? {};
    document[_homeKey] = feed.toPublicJson();
    await _cache.write(document);
  }

  Future<HomeFeed?> load() async {
    final document = await _cache.read();
    final raw = document?[_homeKey];
    if (raw is! Map) return null;
    return HomeFeed.fromPublicJson(Map<String, dynamic>.from(raw));
  }
}
