import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/favorites/presentation/favorites_cubit.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void toggleFavorite(BuildContext context, ListingCard card) {
  if (context.read<AuthCubit>().state is! SignedIn) {
    final origin = GoRouterState.of(context).uri.toString();
    unawaited(
      context.push<void>(
        Uri(
          path: AppRoutes.login,
          queryParameters: {'from': origin, 'cancelTo': origin},
        ).toString(),
      ),
    );
    return;
  }
  unawaited(_saveFavorite(context, card));
}

Future<void> _saveFavorite(BuildContext context, ListingCard card) async {
  try {
    await context.read<FavoritesCubit>().toggle(card);
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).favoriteSaveFailed),
      ),
    );
  }
}
