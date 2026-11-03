import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/area_card.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/favorites/presentation/favorite_action.dart';
import 'package:on_air/features/favorites/presentation/favorites_cubit.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:on_air/features/property/presentation/property_navigation.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

enum HomeCollection { areas, today, newest }

/// Full collections use the discovery repository rather than the small Home
/// preview. Apartment lists continue with the server's cursor pagination.
final class HomeCollectionScreen extends StatefulWidget {
  const HomeCollectionScreen({required this.collection, super.key});

  final HomeCollection collection;

  @override
  State<HomeCollectionScreen> createState() => _HomeCollectionScreenState();
}

final class _HomeCollectionScreenState extends State<HomeCollectionScreen> {
  late final ListingsRepository _repo = context.read<ListingsRepository>();
  HomeFeed? _feed;
  List<ListingCard> _cards = const [];
  String? _cursor;
  ApiError? _error;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  PropertySearchParams get _params {
    if (widget.collection == HomeCollection.today) {
      final today = CairoTime.today();
      return PropertySearchParams(
        stay: StayRange(today, today.addDays(1)),
      );
    }
    return const PropertySearchParams(sort: SearchSort.newest);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.collection == HomeCollection.areas) {
        final feed = await _repo.homeFeed();
        if (!mounted) return;
        setState(() => _feed = feed);
      } else {
        final page = await _repo.searchProperties(_params);
        if (!mounted) return;
        setState(() {
          _cards = page.items;
          _cursor = page.nextCursor;
        });
      }
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.searchProperties(_params, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _cards = [..._cards, ...page.items];
        _cursor = page.nextCursor;
        _error = null;
      });
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 500 && !_loading) {
      unawaited(_loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (widget.collection) {
      HomeCollection.areas => l10n.homeAreasTitle,
      HomeCollection.today => l10n.homeSuggestedTitle,
      HomeCollection.newest => l10n.homeNewestTitle,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _cards.isEmpty && _feed == null
          ? ErrorView(
              message: apiErrorMessage(_error!, l10n),
              referenceNumber: _error!.requestId,
              onRetry: _load,
            )
          : widget.collection == HomeCollection.areas
          ? _areas(context)
          : _apartments(context),
    );
  }

  Widget _areas(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_feed?.areas is FeedSectionFailed<List<AreaTile>>) {
      return ErrorView(
        message: l10n.homeSectionError(l10n.homeAreasTitle),
        onRetry: _load,
      );
    }
    final tiles = switch (_feed?.areas) {
      FeedSectionReady<List<AreaTile>>(:final value) => value,
      _ => const <AreaTile>[],
    };
    if (tiles.isEmpty) {
      return EmptyView(icon: AppIcons.searchOff, message: l10n.homeEmpty);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth - 2 * Dimens.screenSide) / 170)
            .floor()
            .clamp(2, 4);
        return GridView.builder(
          padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: Dimens.space12,
            crossAxisSpacing: Dimens.space12,
            childAspectRatio: 0.76,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            final tile = tiles[index];
            return AreaCard(
              title: tile.name,
              countLabel: l10n.areaListingCount(tile.listingCount),
              imageVariants: tile.image?.variants ?? const [],
              onTap: () => context.go(
                Uri(
                  path: AppRoutes.searchResults,
                  queryParameters: {'loc': tile.locationId},
                ).toString(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _apartments(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_cards.isEmpty) {
      return EmptyView(icon: AppIcons.searchOff, message: l10n.homeEmpty);
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView.builder(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          Dimens.space16,
          Dimens.screenSide,
          Dimens.space32,
        ),
        itemCount: _cards.length + (_loadingMore || _error != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _cards.length) {
            if (_error != null) {
              return TextButton(onPressed: _loadMore, child: Text(l10n.retry));
            }
            return const PropertyCardSkeleton();
          }
          final card = _cards[index];
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Dimens.space16),
            child: BlocBuilder<FavoritesCubit, FavoritesState>(
              builder: (context, favorites) => PropertyCard(
                availabilityLabel: widget.collection == HomeCollection.today
                    ? l10n.propertyAvailableBadge
                    : null,
                isFavorite: favorites.contains(card.id),
                favoriteBusy: favorites.loading || favorites.isBusy(card.id),
                onFavoriteTap: () => toggleFavorite(context, card),
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
                onTap: () => openPropertyDetails(
                  context,
                  AppRoutes.property(card.id),
                  extra: card.cover?.variants,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
