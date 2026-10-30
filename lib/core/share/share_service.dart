import 'package:share_plus/share_plus.dart';

/// The system share sheet. Widgets depend on this interface, never on
/// `share_plus` directly, so tests can record the text instead.
abstract interface class ShareService {
  Future<void> share(String text);
}

final class SharePlusShareService implements ShareService {
  const SharePlusShareService();

  @override
  Future<void> share(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

/// The verified share links (contracts/app-routes-g1.md, "Share links"):
/// a bare property URL, and the results URL carrying the canonical
/// `SearchCriteria` query — never the location label.
final class ShareLinks {
  const ShareLinks({required this.linkDomain});

  static const _searchPath = '/search/results';

  final String linkDomain;

  String property(String id) => 'https://$linkDomain/property/$id';

  String search(Map<String, String> query) => Uri(
    scheme: 'https',
    host: linkDomain,
    path: _searchPath,
    queryParameters: query,
  ).toString();
}
