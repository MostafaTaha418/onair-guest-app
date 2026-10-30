import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/property/presentation/availability_cubit.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The pickable availability calendar. It creates its own
/// [AvailabilityCubit] and sits inside a lazily built `SliverList`, so the
/// months load only when the guest scrolls near it (FR-026).
final class PropertyAvailabilitySection extends StatefulWidget {
  const PropertyAvailabilitySection({
    required this.propertyId,
    this.today,
    super.key,
  });

  final String propertyId;

  /// Injectable clock for goldens and tests; production uses the real Cairo
  /// date. Pinning it keeps the calendar's «today» marker deterministic in
  /// reference images.
  final DateOnly? today;

  @override
  State<PropertyAvailabilitySection> createState() =>
      _PropertyAvailabilitySectionState();
}

final class _PropertyAvailabilitySectionState
    extends State<PropertyAvailabilitySection> {
  late final AvailabilityCubit _cubit = AvailabilityCubit(
    repo: context.read<ListingsRepository>(),
    propertyId: widget.propertyId,
    onStayConfirmed: context.read<PropertyCubit>().setStay,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.showMonth(widget.today ?? CairoTime.today()));
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return BlocBuilder<AvailabilityCubit, AvailabilityState>(
      bloc: _cubit,
      builder: (context, state) {
        final today = widget.today ?? CairoTime.today();
        final selection = state.selection;
        final checkIn = switch (selection) {
          CalendarArrivalPicked(:final day) => day,
          CalendarRange(:final range) => range.checkIn,
          _ => null,
        };
        final checkOut = switch (selection) {
          CalendarRange(:final range) => range.checkOut,
          _ => null,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.propertyAvailability,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            RangeCalendar(
              today: today,
              initialMonth: today,
              selectedCheckIn: checkIn,
              selectedCheckOut: checkOut,
              unavailableNights: {
                for (final nights in state.windows.values) ...nights,
              },
              loadingMonthKeys: state.loading,
              failedMonthKeys: state.failed,
              onDayTap: _cubit.onDayTap,
              onMonthShown: (firstDay) => unawaited(_cubit.showMonth(firstDay)),
              onRetryMonth: (firstDay) =>
                  unawaited(_cubit.retryMonth(firstDay)),
            ),
            if (state.rangeRejected)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: Text(
                  l10n.calendarRangeInvalid,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.errorText,
                  ),
                ),
              )
            else if (state.rangeIncomplete)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: Text(
                  // The retry button belongs to the displayed month, so the
                  // failure text only applies when one of the pending
                  // months actually failed.
                  state.pendingRangeMonths.any(state.failed.contains)
                      ? l10n.calendarRangeLoadFailed
                      : l10n.calendarRangeNotLoaded,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.errorText,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            OnAirPrimaryButton(
              label: l10n.calendarConfirm,
              onPressed: selection is CalendarRange ? _cubit.confirm : null,
            ),
          ],
        );
      },
    );
  }
}
