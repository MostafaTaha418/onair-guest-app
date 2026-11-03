import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/components/area_card.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/bookings/presentation/widgets/unfinished_payment_banner.dart';
import 'package:on_air/features/favorites/presentation/favorite_action.dart';
import 'package:on_air/features/favorites/presentation/favorites_cubit.dart';
import 'package:on_air/features/home/presentation/home_cubit.dart';
import 'package:on_air/features/home/presentation/widgets/home_header.dart';
import 'package:on_air/features/home/presentation/widgets/home_search_box.dart';
import 'package:on_air/features/home/presentation/widgets/home_section.dart';
import 'package:on_air/features/home/presentation/widgets/upcoming_booking_card.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/property/presentation/property_navigation.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The Home tab (US3): greeting, search box, upcoming booking, areas,
/// suggested, and newest — each section independent (FR-004), rendered from
/// the cache first and refreshed (research R6).
final class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: context.colors.gradient('authBackground'),
        ),
        child: RefreshIndicator(
          onRefresh: () => context.read<HomeCubit>().refresh(),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) => CustomScrollView(
              key: const ValueKey('home-scroll'),
              slivers: _slivers(context, state),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _slivers(BuildContext context, HomeState state) {
    final l10n = AppLocalizations.of(context);
    return [
      // The offline banner itself is global (app.dart); the state flag only
      // drives behaviour, not a second banner.
      BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) => authState is SignedIn
            ? const SliverToBoxAdapter(child: UnfinishedPaymentBanner())
            : const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
      SliverToBoxAdapter(
        child: Column(
          children: [
            const HomeHeader(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.screenSide,
                Dimens.space16,
                Dimens.screenSide,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: HomeSearchBox(
                      onTap: () =>
                          StatefulNavigationShell.of(context).goBranch(1),
                    ),
                  ),
                  const SizedBox(width: Dimens.space12),
                  Material(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(Dimens.radiusCard),
                    child: InkWell(
                      key: const ValueKey('home-filter-button'),
                      borderRadius: BorderRadius.circular(Dimens.radiusCard),
                      onTap: () =>
                          StatefulNavigationShell.of(context).goBranch(1),
                      child: SizedBox.square(
                        dimension: 50,
                        child: Icon(
                          AppIcons.tuneOutlined,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimens.space40),
          ],
        ),
      ),
      if (state.feed == null && state.fatalError != null)
        SliverFillRemaining(
          child: ErrorView(
            message: apiErrorMessage(state.fatalError!, l10n),
            referenceNumber: state.fatalError!.requestId,
            onRetry: () => unawaited(context.read<HomeCubit>().refresh()),
          ),
        )
      else ...[
        _upcomingSliver(context, state),
        if (!_isEmpty(state)) ...[
          if (_showSection(
            state.feed?.areas,
            state.sectionLoading[HomeSectionId.areas] ?? false,
          ))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  Dimens.screenSide,
                  Dimens.space16,
                  Dimens.screenSide,
                  0,
                ),
                child: _areasSection(context, state),
              ),
            ),
          if (_showSection(state.availableToday, state.availableTodayLoading))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  Dimens.screenSide,
                  Dimens.space24,
                  Dimens.screenSide,
                  0,
                ),
                child: _availableTodaySection(context, state),
              ),
            ),
          if (_showSection(
            state.feed?.newest,
            state.sectionLoading[HomeSectionId.newest] ?? false,
          ))
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.screenSide,
                Dimens.space24,
                Dimens.screenSide,
                Dimens.space32,
              ),
              sliver: _newestSliver(context, state),
            ),
        ],
        if (_isEmpty(state))
          SliverFillRemaining(
            child: EmptyView(
              icon: AppIcons.searchOff,
              message: l10n.homeEmpty,
              action: TextButton(
                onPressed: () =>
                    StatefulNavigationShell.of(context).goBranch(1),
                child: Text(l10n.homeEmptyAction),
              ),
            ),
          ),
      ],
    ];
  }

  bool _isEmpty(HomeState state) {
    final feed = state.feed;
    if (feed == null) return false;
    bool empty<T>(FeedSection<List<T>> section) => switch (section) {
      FeedSectionReady(:final value) => value.isEmpty,
      FeedSectionFailed() => false,
    };
    final today = state.availableToday;
    return !state.availableTodayLoading &&
        today is FeedSectionReady<List<ListingCard>> &&
        empty(feed.areas) &&
        today.value.isEmpty &&
        empty(feed.newest);
  }

  bool _showSection<T>(FeedSection<List<T>>? section, bool loading) {
    if (loading || section == null) return true;
    return switch (section) {
      FeedSectionReady(:final value) => value.isNotEmpty,
      FeedSectionFailed() => true,
    };
  }

  Widget _upcomingSliver(BuildContext context, HomeState state) {
    final feed = state.feed;
    final section = feed?.upcomingBooking;
    final booking = switch (section) {
      FeedSectionReady(:final value) => value,
      _ => null,
    };
    if (booking == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
        child: UpcomingBookingTile(booking: booking),
      ),
    );
  }

  Widget _areasSection(BuildContext context, HomeState state) {
    final l10n = AppLocalizations.of(context);
    return HomeSection(
      title: l10n.homeAreasTitle,
      isLoading: state.sectionLoading[HomeSectionId.areas] ?? false,
      error: _sectionError(state.feed?.areas),
      onRetry: () => unawaited(
        context.read<HomeCubit>().retrySection(HomeSectionId.areas),
      ),
      skeleton: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = ((constraints.maxWidth - Dimens.space12) / 2).clamp(
            120.0,
            220.0,
          );
          return SizedBox(
            height: 218,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              clipBehavior: Clip.none,
              itemCount: 2,
              itemBuilder: (_, index) => Padding(
                padding: const EdgeInsetsDirectional.only(end: Dimens.space12),
                child: SkeletonBox(width: cardWidth, height: 218),
              ),
            ),
          );
        },
      ),
      child: _areasList(context, state),
    );
  }

  Widget _areasList(BuildContext context, HomeState state) {
    final l10n = AppLocalizations.of(context);
    final tiles = switch (state.feed?.areas) {
      FeedSectionReady<List<AreaTile>>(:final value) => value,
      _ => const <AreaTile>[],
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = ((constraints.maxWidth - Dimens.space12) / 2).clamp(
          120.0,
          220.0,
        );
        return SizedBox(
          height: 218,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            clipBehavior: Clip.none,
            itemCount: tiles.length,
            itemBuilder: (context, index) {
              final tile = tiles[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: Dimens.space12),
                child: AreaCard(
                  width: cardWidth,
                  height: 218,
                  title: tile.name,
                  countLabel: l10n.areaListingCount(tile.listingCount),
                  imageVariants: tile.image?.variants ?? const [],
                  onTap: () => context.go(
                    Uri(
                      path: AppRoutes.searchResults,
                      queryParameters: {'loc': tile.locationId},
                    ).toString(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _availableTodaySection(BuildContext context, HomeState state) {
    final l10n = AppLocalizations.of(context);
    return HomeSection(
      title: l10n.homeSuggestedTitle,
      isLoading: state.availableTodayLoading,
      error: _sectionError(state.availableToday),
      onRetry: () => unawaited(context.read<HomeCubit>().retryAvailableToday()),
      skeleton: const PropertyCardSkeleton(),
      child: Column(
        children: [
          for (final card in switch (state.availableToday) {
            FeedSectionReady<List<ListingCard>>(:final value) => value,
            _ => const <ListingCard>[],
          })
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: Dimens.space16),
              child: _propertyCard(context, card, availableToday: true),
            ),
        ],
      ),
    );
  }

  Widget _newestSliver(BuildContext context, HomeState state) {
    final l10n = AppLocalizations.of(context);
    final isLoading = state.sectionLoading[HomeSectionId.newest] ?? false;
    final error = _sectionError(state.feed?.newest);
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(l10n.homeNewestTitle)),
        if (isLoading)
          SliverToBoxAdapter(
            child: Column(
              children: [
                for (var index = 0; index < 2; index++)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: Dimens.space16,
                    ),
                    child: PropertyCardSkeleton(),
                  ),
              ],
            ),
          )
        else if (error != null)
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.all(Dimens.space12),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(Dimens.radiusCard),
                border: Border.all(color: context.colors['subtleBorder']),
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.errorOutline,
                    size: 18,
                    color: context.colors.errorText,
                  ),
                  const SizedBox(width: Dimens.space8),
                  Expanded(
                    child: Text(
                      l10n.homeSectionError(l10n.homeNewestTitle),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => unawaited(
                      context.read<HomeCubit>().retrySection(
                        HomeSectionId.newest,
                      ),
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: switch (state.feed?.newest) {
              FeedSectionReady<List<ListingCard>>(:final value) => value.length,
              _ => 0,
            },
            itemBuilder: (context, index) {
              final cards = switch (state.feed!.newest) {
                FeedSectionReady<List<ListingCard>>(:final value) => value,
                _ => const <ListingCard>[],
              };
              return Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: Dimens.space16,
                ),
                child: _propertyCard(context, cards[index]),
              );
            },
          ),
      ],
    );
  }

  Widget _propertyCard(
    BuildContext context,
    ListingCard card, {
    bool availableToday = false,
  }) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, favorites) => PropertyCard(
        availabilityLabel: availableToday ? l10n.propertyAvailableBadge : null,
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
        // No Hero on Home cards: the shell's indexed stack keeps every branch
        // alive, so the same apartment can carry the tag twice across the
        // route subtree. The instant photo on details still comes through
        // `extra` (SC-006); the Hero flight stays between results and details.
        onTap: () {
          final today = CairoTime.today();
          openPropertyDetails(
            context,
            availableToday
                ? Uri(
                    path: AppRoutes.property(card.id),
                    queryParameters: {
                      'checkIn': today.toString(),
                      'checkOut': today.addDays(1).toString(),
                    },
                  ).toString()
                : AppRoutes.property(card.id),
            extra: card.cover?.variants,
          );
        },
      ),
    );
  }

  String? _sectionError<T>(FeedSection<List<T>>? section) => switch (section) {
    FeedSectionFailed() => 'INTERNAL',
    _ => null,
  };
}
