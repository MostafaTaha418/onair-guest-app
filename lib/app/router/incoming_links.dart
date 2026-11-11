import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/link_parser.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';

abstract interface class UriLinkSource {
  Future<Uri?> getInitialLink();

  Stream<Uri> get uriLinks;
}

final class AppLinksUriSource implements UriLinkSource {
  AppLinksUriSource({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriLinks => _appLinks.uriLinkStream;
}

final class IncomingLinks {
  IncomingLinks(this._source, this._parser, this._router, this._authCubit);

  final UriLinkSource _source;
  final LinkParser _parser;
  final GoRouter _router;
  final AuthCubit _authCubit;
  StreamSubscription<Uri>? _subscription;

  Future<void> start() async {
    if (_subscription != null) return;

    final linksSeenWhileStarting = <Uri>{};
    var isStarting = true;
    _subscription = _source.uriLinks.listen((link) {
      if (isStarting) linksSeenWhileStarting.add(link);
      _open(link);
    }, onError: _ignoreError);

    try {
      final initialLink = await _source.getInitialLink();
      if (initialLink != null &&
          !linksSeenWhileStarting.contains(initialLink)) {
        _open(initialLink);
      }
    } on Object catch (_) {
      // A platform lookup failure must not disable links received later.
    } finally {
      isStarting = false;
    }
  }

  void _open(Uri link) => _router.go(
    _parser.parse(link, isSignedIn: _authCubit.state is SignedIn),
  );

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  static void _ignoreError(Object _, StackTrace _) {}
}
