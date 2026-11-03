import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class FavoritesPlaceholderScreen extends StatelessWidget {
  const FavoritesPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context).favorites),
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(AppIcons.arrowBackRounded),
        onPressed: () => context.go(AppRoutes.home),
      ),
    ),
    body: EmptyView(
      icon: AppIcons.favoriteBorder,
      message: AppLocalizations.of(context).favoritesEmpty,
    ),
  );
}
