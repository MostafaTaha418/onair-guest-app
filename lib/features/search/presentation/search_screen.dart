import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/counter_stepper.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/search/presentation/filters_sheet.dart';
import 'package:on_air/features/search/presentation/location_suggest_cubit.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/features/search/presentation/widgets/date_range_sheet.dart';
import 'package:on_air/features/search/presentation/widgets/location_field.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The Search tab. Every field is optional (Clarification 1), so «ابحث» is
/// always enabled — except while offline (research R17).
final class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider<LocationSuggestCubit>(
      create: (context) =>
          LocationSuggestCubit(repo: context.read<ListingsRepository>()),
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivity) {
          final online = connectivity.isOnline;
          return Scaffold(
            appBar: AppBar(title: Text(l10n.searchTitle)),
            body: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                return ListView(
                  padding: const EdgeInsetsDirectional.all(Dimens.space16),
                  children: [
                    LocationField(
                      onSelected: (id, label) => _selectLocation(
                        context,
                        id: id,
                        label: label,
                      ),
                    ),
                    const SizedBox(height: Dimens.space16),
                    _DatesRow(
                      stay: state.criteria.stay,
                      online: online,
                    ),
                    const SizedBox(height: Dimens.space16),
                    _GuestsRow(guests: state.criteria.guests),
                    const SizedBox(height: Dimens.space16),
                    _FiltersButton(
                      activeCount: state.criteria.activeFilterChips.length,
                    ),
                    const SizedBox(height: Dimens.space24),
                    OnAirPrimaryButton(
                      label: l10n.searchAction,
                      onPressed: online ? () => _runSearch(context) : null,
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _selectLocation(
    BuildContext context, {
    required String? id,
    required String? label,
  }) {
    final cubit = context.read<SearchCubit>();
    final current = cubit.state.criteria;
    final criteria = id == null
        ? current.withoutLocation()
        : current.copyWith(locationId: id, locationLabel: label);
    cubit.setCriteria(criteria, label: label);
  }

  void _runSearch(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    final state = cubit.state;
    // The results screen opens on the same cubit; it skips the duplicate
    // search for the query this call just started.
    unawaited(cubit.search(state.criteria, label: state.locationLabel));
    context.go(
      Uri(
        path: AppRoutes.searchResults,
        queryParameters: state.criteria.toQuery().isEmpty
            ? null
            : state.criteria.toQuery(),
      ).toString(),
    );
  }
}

final class _DatesRow extends StatelessWidget {
  const _DatesRow({required this.stay, required this.online});

  final StayRange? stay;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = stay == null
        ? l10n.searchDatesHint
        : '${DateOnlyFormatter.dayMonth(stay!.checkIn)} – '
              '${DateOnlyFormatter.dayMonth(stay!.checkOut)}';
    return InkWell(
      onTap: online
          ? () async {
              final selected = await showDateRangeSheet(context);
              if (selected == null || !context.mounted) return;
              final cubit = context.read<SearchCubit>();
              cubit.setCriteria(
                cubit.state.criteria.copyWith(stay: selected),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsetsDirectional.all(Dimens.space12),
        decoration: BoxDecoration(
          color: colors['inputFill'],
          borderRadius: BorderRadius.circular(Dimens.radiusField),
          border: Border.all(color: colors['inputBorder']),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_outlined,
              color: colors.textSecondary,
            ),
            const SizedBox(width: Dimens.space8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: stay == null
                      ? colors['placeholder']
                      : colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _GuestsRow extends StatelessWidget {
  const _GuestsRow({required this.guests});

  final int? guests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.searchGuestsLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Text(
                guests == null ? l10n.searchGuestsAny : '$guests',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        CounterStepper(
          value: guests ?? 1,
          min: 1,
          max: 50,
          onChanged: (value) {
            final cubit = context.read<SearchCubit>();
            cubit.setCriteria(cubit.state.criteria.copyWith(guests: value));
          },
          label: l10n.searchGuestsLabel,
          decrementTooltip: l10n.guestsDecrease,
          incrementTooltip: l10n.guestsIncrease,
        ),
      ],
    );
  }
}

final class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final label = activeCount == 0
        ? l10n.searchFilters
        : '${l10n.searchFilters} ($activeCount)';
    return OutlinedButton.icon(
      onPressed: () async {
        final cubit = context.read<SearchCubit>();
        final edited = await showFiltersSheet(
          context,
          initial: cubit.state.criteria,
        );
        if (edited == null || !context.mounted) return;
        cubit.setCriteria(edited);
      },
      icon: Icon(Icons.tune_outlined, color: colors['textAccent']),
      label: Text(
        label,
        style: context.textStyles.authButton.copyWith(
          color: colors['textAccent'],
        ),
      ),
    );
  }
}
