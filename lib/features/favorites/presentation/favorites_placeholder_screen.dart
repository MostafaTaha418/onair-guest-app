import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class FavoritesPlaceholderScreen extends StatelessWidget {
  const FavoritesPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: EmptyView(
      icon: Icons.favorite_border,
      message: AppLocalizations.of(context).favoritesEmpty,
    ),
  );
}
