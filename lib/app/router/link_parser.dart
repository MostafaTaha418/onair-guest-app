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
    // The Kashier return link carries only the booking id, and only as a
    // navigation hint (FR-016): `status` and every provider field is
    // dropped, and a non-UUID booking leaves no query at all.
    final booking = link.queryParameters['booking'];
    final returnQuery = booking != null && AppRoutes.isUuidV4(booking)
        ? {'booking': booking}
        : null;
    final destination = switch (link.path) {
      AppRoutes.searchResults => Uri(
        path: link.path,
        queryParameters: {
          for (final key
              in link.queryParameters.keys
                  .where(_searchQueryKeys.contains)
                  .toList()
                ..sort())
            key: link.queryParameters[key],
        },
      ).toString(),
      AppRoutes.paymentReturnPath => Uri(
        path: link.path,
        queryParameters: returnQuery,
      ).toString(),
      _ => Uri(path: link.path).toString(),
    };
    if (!isSignedIn && AppRoutes.requiresAccount(destination)) {
      return Uri(
        path: AppRoutes.login,
        queryParameters: {'from': destination},
      ).toString();
    }
    return destination;
  }
}
