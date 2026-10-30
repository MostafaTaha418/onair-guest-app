import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/listings/domain/location_suggestion.dart';
import 'package:on_air/features/search/presentation/location_suggest_cubit.dart';
import 'package:on_air/features/search/presentation/search_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The search location field with Arabic-normalised suggestions
/// (research R12). Selecting a row reports `(id, label)`; «كل الأماكن»
/// clears the location.
final class LocationField extends StatefulWidget {
  const LocationField({required this.onSelected, super.key});

  final void Function(String? id, String? label) onSelected;

  @override
  State<LocationField> createState() => _LocationFieldState();
}

final class _LocationFieldState extends State<LocationField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _queryIsShort => _controller.text.trim().length < 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectivity) {
        final online = connectivity.isOnline;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnAirTextField(
              controller: _controller,
              hint: l10n.searchLocationHint,
              enabled: online,
              onChanged: (text) {
                setState(() {});
                if (online) {
                  context.read<LocationSuggestCubit>().onQueryChanged(text);
                }
              },
            ),
            if (!online)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: Dimens.space4),
                child: Text(
                  l10n.offline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            if (online)
              BlocBuilder<LocationSuggestCubit, LocationSuggestState>(
                builder: (context, state) {
                  final searchState = context.watch<SearchCubit>().state;
                  if (_queryIsShort || state is LocationSuggestIdle) {
                    return _shortQueryRows(context, searchState.locationLabel);
                  }
                  return switch (state) {
                    LocationSuggestReady(:final items) when items.isEmpty =>
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: Dimens.space8,
                        ),
                        child: Text(
                          l10n.searchNoLocationMatches,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ),
                    LocationSuggestReady(:final items) => Column(
                      children: [
                        for (final suggestion in items)
                          _suggestionRow(context, suggestion),
                      ],
                    ),
                    _ => const SizedBox.shrink(),
                  };
                },
              ),
          ],
        );
      },
    );
  }

  Widget _shortQueryRows(BuildContext context, String? lastLabel) {
    final l10n = AppLocalizations.of(context);
    final searchState = context.read<SearchCubit>().state;
    return Column(
      children: [
        if (lastLabel != null && searchState.criteria.locationId != null)
          _row(
            context,
            title: lastLabel,
            subtitle: null,
            trailing: null,
            onTap: () => widget.onSelected(
              searchState.criteria.locationId,
              lastLabel,
            ),
          ),
        _row(
          context,
          title: l10n.searchAnyLocation,
          subtitle: null,
          trailing: null,
          onTap: () {
            _controller.clear();
            widget.onSelected(null, null);
          },
        ),
      ],
    );
  }

  Widget _suggestionRow(BuildContext context, LocationSuggestion suggestion) {
    final l10n = AppLocalizations.of(context);
    return _row(
      context,
      title: suggestion.name,
      subtitle: suggestion.parentLabel,
      trailing: l10n.areaListingCount(suggestion.listingCount),
      onTap: () {
        _controller
          ..text = suggestion.name
          ..selection = TextSelection.collapsed(
            offset: suggestion.name.length,
          );
        widget.onSelected(suggestion.id, suggestion.name);
      },
    );
  }

  Widget _row(
    BuildContext context, {
    required String title,
    required String? subtitle,
    required String? trailing,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: Dimens.space8,
          vertical: Dimens.space8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
