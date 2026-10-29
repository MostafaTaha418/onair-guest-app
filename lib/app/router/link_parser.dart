import 'package:on_air/app/router/routes.dart';

final class LinkParser {
  const LinkParser(this._linkDomain);

  final String _linkDomain;

  /// Query keys kept on a shared `/search/results` link — the canonical
  /// `SearchCriteria` keys (contracts/app-routes-g1.md, "Query parameters").
  /// Duplicated here on purpose: the router layer must not import
  /// `features/`, where `SearchCriteria` lives.
  static const _searchQueryKeys = <String>{
    'am',
    'bath',
    'bed',
    'g',
    'in',
    'loc',
    'out',
    'pmax',
    'pmin',
    'sort',
    'type',
  };

  String parse(Uri link, {required bool isSignedIn}) {
    if (link.scheme != 'https' ||
        link.host.toLowerCase() != _linkDomain.toLowerCase() ||
        link.userInfo.isNotEmpty ||
        !AppRoutes.isLinkablePath(link.path)) {
      return AppRoutes.notAvailable;
    }
    final destination = link.path == AppRoutes.searchResults
        ? Uri(
            path: link.path,
            queryParameters: {
              for (final key
                  in link.queryParameters.keys
                      .where(_searchQueryKeys.contains)
                      .toList()
                    ..sort())
                key: link.queryParameters[key],
            },
          ).toString()
        : Uri(path: link.path).toString();
    if (!isSignedIn && AppRoutes.requiresAccount(destination)) {
      return Uri(
        path: AppRoutes.login,
        queryParameters: {'from': destination},
      ).toString();
    }
    return destination;
  }
}
