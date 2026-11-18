import 'package:on_air/features/stay/domain/stay_repository.dart';
import 'package:on_air/features/stay/domain/stay_results.dart';

/// In-memory URLs for claim evidence (Constitution: evidence never touches
/// disk). URLs are reused until 30 s before expiry, then fetched again.
final class EvidenceUrlCache {
  EvidenceUrlCache(this._stay, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final StayRepository _stay;
  final DateTime Function() _now;
  final Map<String, FileUrl> _urls = {};

  Future<Uri> urlFor(String attachmentId) async {
    final cached = _urls[attachmentId];
    if (cached != null &&
        cached.expiresAt.difference(_now()) >= const Duration(seconds: 30)) {
      return cached.url;
    }
    final url = await _stay.fileUrl(attachmentId);
    _urls[attachmentId] = url;
    return url.url;
  }

  void invalidate(String attachmentId) {
    _urls.remove(attachmentId);
  }

  void clear() {
    _urls.clear();
  }
}
