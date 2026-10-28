import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/filter_chip_bar.dart';
import 'package:on_air/design_system/components/property_card.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';
import 'package:on_air/features/search/presentation/filters_sheet.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/features/search/presentation/widgets/date_range_sheet.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Server-filtered results for the current criteria, with cursor pagination
/// (research R4). The screen stays on the Search branch stack, so Back keeps
/// the list and scroll position (research R9).
final class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

final class _ResultsScreenState extends State<ResultsScreen> {
  late final SearchCubit _cubit = context.read<SearchCubit>();
  late final ScrollController _controller = ScrollController(
    initialScrollOffset: _cubit.state.scrollOffset,
  );
  Map<String, String> _labels = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadLabels());
  }

  Future<void> _loadLabels() async {
    try {
      final reference = await context.read<ReferenceDataCache>().load();
      if (!mounted) return;
      setState(() {
        _labels = {
          for (final amenity in reference.amenities) amenity.key: amenity.label,
          for (final type in reference.propertyTypes) type.key: type.label,
        };
      });
    } on AppFailure {
      // Chip labels fall back to the raw keys.
    }
  }

  @override
  void dispose() {
    // The screen can be torn down before its scroll view ever attached.
    if (_controller.hasClients) {
      _cubit.rememberScroll(_controller.offset);
    }
    _controller.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    final state = _cubit.state;
    if (state.status != ResultsStatus.ready ||
        state.loadingMore ||
        state.nextCursor == null) {
      return false;
    }
    if (notification.metrics.extentAfter < 600) {
      unawaited(_cubit.loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) => NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: CustomScrollView(
            controller: _controller,
            slivers: [
              const SliverToBoxAdapter(child: OfflineBannerVisibility()),
              SliverToBoxAdapter(child: _SummaryBar(state: state)),
              SliverToBoxAdapter(child: _chipBar(context, state)),
              if (state.criteria.stay == null &&
                  state.status != ResultsStatus.loading)
                SliverToBoxAdapter(
                  child: _HintBanner(text: l10n.searchDatesNeededHint),
                ),
              if (state.datesDropped)
                const SliverToBoxAdapter(child: _DroppedBanner()),
              ..._resultsSlivers(context, state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _resultsSlivers(BuildContext context, SearchState state) {
    final l10n = AppLocalizations.of(context);
    switch (state.status) {
      case ResultsStatus.idle || ResultsStatus.loading:
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(Dimens.space16),
              child: Column(
                children: [
                  for (var index = 0; index < 4; index++)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: Dimens.space16,
                      ),
                      child: PropertyCardSkeleton(),
                    ),
                ],
              ),
            ),
          ),
        ];
      case ResultsStatus.empty:
        return [
          SliverFillRemaining(
            child: EmptyView(
              icon: Icons.search_off,
              message: l10n.searchNoResults,
              action: TextButton(
                onPressed: () async {
                  final edited = await showFiltersSheet(
                    context,
                    initial: state.criteria,
                  );
                  if (edited == null || !context.mounted) return;
                  _cubit.setCriteria(edited);
                  unawaited(_cubit.search(edited));
                },
                child: Text(l10n.searchFilters),
              ),
            ),
          ),
        ];
      case ResultsStatus.failed:
        return [
          SliverFillRemaining(
            child: ErrorView(
              message: apiErrorMessage(state.error!, l10n),
              referenceNumber: state.error!.requestId,
              onRetry: () =>
                  _cubit.search(state.criteria, label: state.locationLabel),
            ),
          ),
        ];
      case ResultsStatus.offline:
        return [
          const SliverToBoxAdapter(child: SizedBox.shrink()),
        ];
      case ResultsStatus.ready:
        return [
          SliverPadding(
            padding: const EdgeInsetsDirectional.all(Dimens.space16),
            sliver: SliverList.builder(
              itemCount: state.items.length + (state.loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsetsDirectional.only(bottom: Dimens.space16),
                    child: PropertyCardSkeleton(),
                  );
                }
                final card = state.items[index];
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
                    stayTotalText: card.stay == null
                        ? null
                        : l10n.stayTotal(
                            card.stay!.nights,
                            MoneyFormatter().format(card.stay!.stayTotal),
                          ),
                    ratingText: card.ratingAvg?.toStringAsFixed(1),
                    ratingSemantics: card.ratingAvg == null
                        ? null
                        : l10n.ratingSemantics(
                            card.ratingAvg!.toStringAsFixed(1),
                            card.reviewCount,
                          ),
                    heroTag: 'listing-${card.id}',
                    onTap: () => context.push(AppRoutes.property(card.id)),
                  ),
                );
              },
            ),
          ),
        ];
    }
  }

  Widget _chipBar(BuildContext context, SearchState state) {
    final l10n = AppLocalizations.of(context);
    final formatter = MoneyFormatter();
    final chips = [
      for (final chip in state.criteria.activeFilterChips)
        (
          label: switch (chip.kind) {
            FilterChipKind.price => _priceLabel(state.criteria, formatter),
            FilterChipKind.bedrooms => l10n.bedroomsAtLeast(
              state.criteria.minBedrooms ?? 0,
            ),
            FilterChipKind.bathrooms => l10n.bathroomsAtLeast(
              state.criteria.minBathrooms ?? 0,
            ),
            FilterChipKind.amenity => _labels[chip.key] ?? chip.key!,
            FilterChipKind.type => _labels[chip.key] ?? chip.key!,
          },
          removeTooltip: l10n.filterChipRemove(''),
          onRemove: () => _cubit.removeChip(chip),
        ),
    ];
    return FilterChipBar(chips: chips);
  }

  String _priceLabel(SearchCriteria criteria, MoneyFormatter formatter) {
    final min = criteria.priceMin;
    final max = criteria.priceMax;
    return switch ((min, max)) {
      (final Money min, final Money max) =>
        '${formatter.format(min)} – ${formatter.format(max)}',
      (final Money min, null) => formatter.format(min),
      (null, final Money max) => formatter.format(max),
      (null, null) => '',
    };
  }
}

/// The offline banner shows whenever the device is offline; loaded items
/// stay visible underneath (research R17).
final class OfflineBannerVisibility extends StatelessWidget {
  const OfflineBannerVisibility({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivity) => connectivity.isOnline
            ? const SizedBox.shrink()
            : const OfflineBanner(),
      );
}

final class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final stay = state.criteria.stay;
    final dates = stay == null
        ? l10n.searchDatesHint
        : '${DateOnlyFormatter.dayMonth(stay.checkIn)} – '
              '${DateOnlyFormatter.dayMonth(stay.checkOut)}';
    final guests = state.criteria.guests == null
        ? l10n.searchGuestsAny
        : '${state.criteria.guests}';
    return InkWell(
      onTap: () => context.go(AppRoutes.search),
      child: Container(
        color: colors.surface,
        padding: const EdgeInsetsDirectional.all(Dimens.space12),
        child: Row(
          children: [
            Icon(Icons.tune_outlined, size: 18, color: colors.textSecondary),
            const SizedBox(width: Dimens.space8),
            Expanded(
              child: Text(
                [
                  state.locationLabel ?? l10n.searchAnyLocation,
                  dates,
                  '${l10n.searchGuestsLabel}: $guests',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _HintBanner extends StatelessWidget {
  const _HintBanner({
    required this.text,
    this.action,
    this.onAction,
  });

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors['infoContainer'],
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Dimens.space8,
        vertical: Dimens.space4,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: colors['onInfoContainer']),
          const SizedBox(width: Dimens.space8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors['onInfoContainer'],
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors['onInfoContainer'],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _DroppedBanner extends StatelessWidget {
  const _DroppedBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _HintBanner(
      text: l10n.searchDatesDropped,
      action: l10n.searchChooseDates,
      onAction: () async {
        final cubit = context.read<SearchCubit>();
        final selected = await showDateRangeSheet(context);
        if (selected == null || !context.mounted) return;
        final criteria = cubit.state.criteria.copyWith(stay: selected);
        cubit.setCriteria(criteria);
        unawaited(cubit.search(criteria));
      },
    );
  }
}
