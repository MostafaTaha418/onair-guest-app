import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/area_card.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/home/presentation/home_cubit.dart';
import 'package:on_air/features/home/presentation/widgets/home_header.dart';
import 'package:on_air/features/home/presentation/widgets/home_search_box.dart';
import 'package:on_air/features/home/presentation/widgets/home_section.dart';
import 'package:on_air/features/home/presentation/widgets/upcoming_booking_card.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The Home tab (US3): greeting, search box, upcoming booking, areas,
/// suggested, and newest — each section independent (FR-004), rendered from
/// the cache first and refreshed (research R6).
final class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeCubit>().refresh(),
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) => CustomScrollView(
            key: const ValueKey('home-scroll'),
            slivers: _slivers(context, state),
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
      const SliverToBoxAdapter(child: HomeHeader()),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
          child: HomeSearchBox(
            onTap: () => StatefulNavigationShell.of(context).goBranch(1),
          ),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.screenSide,
                Dimens.space24,
                Dimens.screenSide,
                0,
              ),
              child: _suggestedSection(context, state),
            ),
          ),
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
              icon: Icons.search_off,
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
    return empty(feed.areas) && empty(feed.suggested) && empty(feed.newest);
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
      skeleton: SizedBox(
        height: 170,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          clipBehavior: Clip.none,
          itemCount: 2,
          itemBuilder: (_, index) => const Padding(
            padding: EdgeInsetsDirectional.only(end: Dimens.space12),
            child: SkeletonBox(width: 140, height: 170),
          ),
        ),
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
    return SizedBox(
      height: 170,
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
  }

  Widget _suggestedSection(BuildContext context, HomeState state) {
    final l10n = AppLocalizations.of(context);
    return HomeSection(
      title: l10n.homeSuggestedTitle,
      isLoading: state.sectionLoading[HomeSectionId.suggested] ?? false,
      error: _sectionError(state.feed?.suggested),
      onRetry: () => unawaited(
        context.read<HomeCubit>().retrySection(HomeSectionId.suggested),
      ),
      skeleton: SizedBox(
        height: 320,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          clipBehavior: Clip.none,
          itemCount: 2,
          itemBuilder: (_, index) => const Padding(
            padding: EdgeInsetsDirectional.only(end: Dimens.space12),
            child: PropertyCardSkeleton(width: 260),
          ),
        ),
      ),
      child: _cardsList(context, state, suggested: true),
    );
  }

  Widget _cardsList(
    BuildContext context,
    HomeState state, {
    required bool suggested,
  }) {
    final cards = switch (suggested
        ? state.feed?.suggested
        : state.feed?.newest) {
      FeedSectionReady<List<ListingCard>>(:final value) => value,
      _ => const <ListingCard>[],
    };
    return SizedBox(
      height: 320,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        itemCount: cards.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsetsDirectional.only(end: Dimens.space12),
          child: _propertyCard(context, cards[index], width: 260),
        ),
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
                    Icons.error_outline,
                    size: 18,
                    color: context.colors.errorText,
                  ),
                  const SizedBox(width: Dimens.space8),
                  Expanded(
                    child: Text(
                      l10n.errorUnexpectedNoRef,
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
    double? width,
  }) {
    final l10n = AppLocalizations.of(context);
    return PropertyCard(
      width: width ?? double.infinity,
      title: card.title,
      subtitle: '${card.areaName} • ${card.cityName}',
      imageVariants: card.cover?.variants ?? const [],
      priceText: l10n.nightlyPrice(MoneyFormatter().format(card.nightlyPrice)),
      ratingText: card.ratingAvg?.toStringAsFixed(1),
      ratingSemantics: card.ratingAvg == null
          ? null
          : l10n.ratingSemantics(
              card.ratingAvg!.toStringAsFixed(1),
              card.reviewCount,
            ),
      heroTag: 'listing-${card.id}',
      onTap: () => unawaited(
        context.push(AppRoutes.property(card.id), extra: card.cover?.variants),
      ),
    );
  }

  String? _sectionError<T>(FeedSection<List<T>>? section) => switch (section) {
    FeedSectionFailed() => 'INTERNAL',
    _ => null,
  };
}
