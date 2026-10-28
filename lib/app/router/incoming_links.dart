import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/link_parser.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';

abstract interface class UriLinkSource {
  Stream<Uri> get uriLinks;
}

final class AppLinksUriSource implements UriLinkSource {
  AppLinksUriSource({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

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

  void start() {
    _subscription ??= _source.uriLinks.listen(
      (link) => _router.go(
        _parser.parse(link, isSignedIn: _authCubit.state is SignedIn),
      ),
      onError: _ignoreError,
    );
  }

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  static void _ignoreError(Object _, StackTrace _) {}
}
