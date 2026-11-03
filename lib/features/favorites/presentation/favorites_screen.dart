import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/favorites/presentation/favorite_action.dart';
import 'package:on_air/features/favorites/presentation/favorites_cubit.dart';
import 'package:on_air/features/property/presentation/property_navigation.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(AppIcons.arrowBackRounded),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (state.loading && state.cards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error && state.cards.isEmpty) {
            return ErrorView(
              message: l10n.favoritesLoadFailed,
              onRetry: () => context.read<FavoritesCubit>().refresh(),
            );
          }
          if (state.cards.isEmpty) {
            return EmptyView(
              icon: AppIcons.favoriteBorder,
              message: l10n.favoritesEmpty,
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<FavoritesCubit>().refresh(),
            child: ListView.builder(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.screenSide,
                Dimens.space16,
                Dimens.screenSide,
                Dimens.space32,
              ),
              itemCount: state.cards.length,
              itemBuilder: (context, index) {
                final card = state.cards[index];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: Dimens.space16,
                  ),
                  child: PropertyCard(
                    title: card.title,
                    subtitle: '${card.areaName} • ${card.cityName}',
                    imageVariants: card.cover?.variants ?? const [],
                    priceText: l10n.nightlyPrice(
                      MoneyFormatter().format(card.nightlyPrice),
                    ),
                    ratingText: card.ratingAvg?.toStringAsFixed(1),
                    ratingSemantics: card.ratingAvg == null
                        ? null
                        : l10n.ratingSemantics(
                            card.ratingAvg!.toStringAsFixed(1),
                            card.reviewCount,
                          ),
                    isFavorite: true,
                    favoriteBusy: state.isBusy(card.id) || state.loading,
                    onFavoriteTap: () => toggleFavorite(context, card),
                    onTap: () => openPropertyDetails(
                      context,
                      AppRoutes.property(card.id),
                      extra: card.cover?.variants,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
