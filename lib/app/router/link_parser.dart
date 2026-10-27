import 'package:on_air/app/router/routes.dart';

final class LinkParser {
  const LinkParser(this._linkDomain);

  final String _linkDomain;

  String parse(Uri link, {required bool isSignedIn}) {
    if (link.scheme != 'https' ||
        link.host.toLowerCase() != _linkDomain.toLowerCase() ||
        link.userInfo.isNotEmpty ||
        !AppRoutes.isLinkablePath(link.path)) {
      return AppRoutes.notAvailable;
    }
    final destination = Uri(path: link.path).toString();
    if (!isSignedIn && AppRoutes.requiresAccount(destination)) {
      return Uri(
        path: AppRoutes.login,
        queryParameters: {'from': destination},
      ).toString();
    }
    return destination;
  }
}
