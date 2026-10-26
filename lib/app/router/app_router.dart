import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/redirect.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

GoRouter createAppRouter({required Listenable refreshListenable}) => GoRouter(
  initialLocation: AppRoutes.home,
  refreshListenable: refreshListenable,
  redirect: (_, state) =>
      resolveRedirect(RedirectContext(location: state.uri.path)),
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).appName)),
        body: Center(child: Text(AppLocalizations.of(context).home)),
      ),
    ),
  ],
);
