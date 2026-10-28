import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/counter_stepper.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/reference_data.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';
import 'package:on_air/features/search/presentation/filters_count_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Opens the filters sheet; pops with the edited [SearchCriteria], or null.
Future<SearchCriteria?> showFiltersSheet(
  BuildContext context, {
  required SearchCriteria initial,
}) => showModalBottomSheet<SearchCriteria>(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(Dimens.radiusSheet),
    ),
  ),
  builder: (_) => BlocProvider<FiltersCountCubit>(
    create: (context) => FiltersCountCubit(
      repo: context.read<ListingsRepository>(),
    )..recount(initial),
    child: FiltersSheet(initial: initial),
  ),
);

/// Edits a local copy of the criteria: price range, bedrooms, bathrooms,
/// amenities, property types, and sort. Confirming pops with the copy; the
/// caller decides what to do with it.
final class FiltersSheet extends StatefulWidget {
  const FiltersSheet({required this.initial, super.key});

  final SearchCriteria initial;

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

final class _FiltersSheetState extends State<FiltersSheet> {
  late SearchCriteria _draft = widget.initial;
  ReferenceData? _reference;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_loadReference());
  }

  Future<void> _loadReference() async {
    try {
      final data = await context.read<ReferenceDataCache>().load();
      if (!mounted) return;
      setState(() {
        _reference = data;
        _failure = null;
      });
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _failure = failure);
    }
  }

  void _update(SearchCriteria draft) {
    setState(() => _draft = draft);
    context.read<FiltersCountCubit>().recount(draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            Expanded(
              child: _failure != null
                  ? ErrorView(
                      message: apiErrorMessage(_failure!.error, l10n),
                      referenceNumber: _failure!.error.requestId,
                      onRetry: _loadReference,
                    )
                  : _reference == null
                  ? const Padding(
                      padding: EdgeInsetsDirectional.all(Dimens.space16),
                      child: Column(
                        children: [
                          SkeletonBox(height: 24, width: 160, radius: 8),
                          SizedBox(height: Dimens.space16),
                          SkeletonBox(height: 200),
                          SizedBox(height: Dimens.space16),
                          SkeletonBox(height: 120),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsetsDirectional.all(
                        Dimens.space16,
                      ),
                      child: _form(context, l10n),
                    ),
            ),
            _bottomBar(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context, AppLocalizations l10n) {
    final reference = _reference!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, l10n.searchPriceRange),
        _priceSlider(context, l10n, reference),
        const SizedBox(height: Dimens.space16),
        _counterRow(
          context,
          title: l10n.searchMinBedrooms,
          value: _draft.minBedrooms ?? 0,
          onChanged: (value) => _update(
            _draft.copyWith(minBedrooms: value == 0 ? null : value),
          ),
        ),
        _counterRow(
          context,
          title: l10n.searchMinBathrooms,
          value: _draft.minBathrooms ?? 0,
          onChanged: (value) => _update(
            _draft.copyWith(minBathrooms: value == 0 ? null : value),
          ),
        ),
        const SizedBox(height: Dimens.space16),
        _sectionTitle(context, l10n.searchAmenities),
        _chipWrap(
          context,
          options: reference.amenities
              .map((amenity) => (key: amenity.key, label: amenity.label))
              .toList(),
          selected: _draft.amenityKeys,
          onToggle: (key, {required selected}) => _update(
            _draft.copyWith(
              amenityKeys: selected
                  ? {..._draft.amenityKeys, key}
                  : ({..._draft.amenityKeys}..remove(key)),
            ),
          ),
        ),
        const SizedBox(height: Dimens.space16),
        _sectionTitle(context, l10n.searchPropertyType),
        _chipWrap(
          context,
          options: reference.propertyTypes
              .map((type) => (key: type.key, label: type.label))
              .toList(),
          selected: _draft.propertyTypes,
          onToggle: (key, {required selected}) => _update(
            _draft.copyWith(
              propertyTypes: selected
                  ? {..._draft.propertyTypes, key}
                  : ({..._draft.propertyTypes}..remove(key)),
            ),
          ),
        ),
        const SizedBox(height: Dimens.space16),
        _sectionTitle(context, l10n.searchSort),
        _sortChips(context, l10n),
      ],
    );
  }

  Widget _priceSlider(
    BuildContext context,
    AppLocalizations l10n,
    ReferenceData reference,
  ) {
    final colors = context.colors;
    final formatter = MoneyFormatter();
    final minMinor = reference.priceMin.amountMinor;
    final maxMinor = reference.priceMax.amountMinor;
    final step = reference.priceStep.amountMinor;
    final start = (_draft.priceMin?.amountMinor ?? minMinor).clamp(
      minMinor,
      maxMinor,
    );
    final end = (_draft.priceMax?.amountMinor ?? maxMinor).clamp(
      minMinor,
      maxMinor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RangeSlider(
          values: RangeValues(start.toDouble(), end.toDouble()),
          min: minMinor.toDouble(),
          max: maxMinor.toDouble(),
          // A degenerate server range (min == max) leaves no divisions.
          divisions: maxMinor > minMinor
              ? ((maxMinor - minMinor) / step).round()
              : null,
          labels: RangeLabels(
            formatter.format(Money(start)),
            formatter.format(Money(end)),
          ),
          onChanged: (values) => _update(
            _draft.copyWith(
              priceMin: values.start.round() <= minMinor
                  ? null
                  : Money(values.start.round()),
              priceMax: values.end.round() >= maxMinor
                  ? null
                  : Money(values.end.round()),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatter.format(Money(start)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            Text(
              formatter.format(Money(end)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _counterRow(
    BuildContext context, {
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '$title · ${value == 0 ? l10n.searchAnyCount : '$value+'}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
        ),
        CounterStepper(
          value: value,
          min: 0,
          max: 20,
          onChanged: onChanged,
          label: title,
          decrementTooltip: l10n.countDecrease,
          incrementTooltip: l10n.countIncrease,
        ),
      ],
    );
  }

  Widget _chipWrap(
    BuildContext context, {
    required List<({String key, String label})> options,
    required Set<String> selected,
    required void Function(String key, {required bool selected}) onToggle,
  }) => Wrap(
    spacing: Dimens.space8,
    runSpacing: Dimens.space8,
    children: [
      for (final option in options)
        FilterChip(
          label: Text(option.label),
          selected: selected.contains(option.key),
          onSelected: (value) => onToggle(option.key, selected: value),
        ),
    ],
  );

  Widget _sortChips(BuildContext context, AppLocalizations l10n) {
    final entries = [
      (sort: SearchSort.priceAsc, label: l10n.sortPriceAsc),
      (sort: SearchSort.priceDesc, label: l10n.sortPriceDesc),
      (sort: SearchSort.newest, label: l10n.sortNewest),
    ];
    return Wrap(
      spacing: Dimens.space8,
      children: [
        for (final entry in entries)
          ChoiceChip(
            label: Text(entry.label),
            selected: _draft.sort == entry.sort,
            onSelected: (selected) => _update(
              _draft.copyWith(sort: selected ? entry.sort : null),
            ),
          ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors['navBorder']),
        ),
      ),
      padding: const EdgeInsetsDirectional.all(Dimens.space16),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                // Reset only the fields this sheet edits; location, dates,
                // and guests stay as they are.
                final initial = widget.initial;
                _update(
                  SearchCriteria(
                    locationId: initial.locationId,
                    locationLabel: initial.locationLabel,
                    stay: initial.stay,
                    guests: initial.guests,
                  ),
                );
              },
              child: Text(
                l10n.searchClearAll,
                style: context.textStyles.authButton.copyWith(
                  color: colors['textAccent'],
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimens.space16),
          Expanded(
            flex: 2,
            child: BlocBuilder<FiltersCountCubit, FiltersCountState>(
              builder: (context, count) {
                final label = switch (count) {
                  FiltersCount(:final count) => l10n.searchShowResults(count),
                  FiltersCounting() ||
                  FiltersCountFailed() => l10n.searchShowResultsUnknown,
                };
                return OnAirPrimaryButton(
                  label: label,
                  isLoading: count is FiltersCounting,
                  onPressed: () => Navigator.pop(context, _draft),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: Dimens.space8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: context.colors.textPrimary,
      ),
    ),
  );
}
