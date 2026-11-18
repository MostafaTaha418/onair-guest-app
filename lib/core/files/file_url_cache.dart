import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/domain/stay_results.dart';

/// Short-lived private file URLs held in memory only.
///
/// A URL is refreshed when it has less than 30 seconds left. Call
/// [invalidate] after a 403 so the next read obtains a fresh signed URL.
final class FileUrlCache {
  FileUrlCache(this._source, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final StayRepository _source;
  final DateTime Function() _now;
  final Map<String, FileUrl> _urls = {};

  Future<Uri> urlFor(String attachmentId) async {
    final cached = _urls[attachmentId];
    if (cached != null &&
        cached.expiresAt.difference(_now()) >= const Duration(seconds: 30)) {
      return cached.url;
    }
    final url = await _source.fileUrl(attachmentId);
    _urls[attachmentId] = url;
    return url.url;
  }

  void invalidate(String attachmentId) => _urls.remove(attachmentId);

  void clear() => _urls.clear();
}
