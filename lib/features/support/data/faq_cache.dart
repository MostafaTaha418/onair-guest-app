import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/features/support/domain/faq_item.dart';

/// The public FAQ cache (data-model §4, task T059): a dedicated
/// `faq_v1.json` document in the app-support directory. The content is
/// public and non-personal, so it is deliberately **not** registered with
/// any sign-out cleaner.
final class FaqCache {
  FaqCache(this._cache);

  final JsonFileCache _cache;

  Future<void> save(FaqSnapshot snapshot) => _cache.write(snapshot.toJson());

  Future<FaqSnapshot?> load() async {
    final document = await _cache.read();
    if (document == null) return null;
    return FaqSnapshot.fromJson(document);
  }

  Future<void> clear() => _cache.clear();
}
