import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/property/presentation/availability_cubit.dart';
import 'package:on_air/features/property/presentation/property_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The availability calendar. Read-only here: it shows which nights are
/// open, and the picking happens on the booking dates screen. It creates
/// its own [AvailabilityCubit] and sits inside a lazily built `SliverList`,
/// so the months load only when the guest scrolls near it (FR-026).
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.propertyAvailability,
              style: context.textStyles.sectionTitle.copyWith(
                color: colors['textAccent'],
              ),
            ),
            const SizedBox(height: 12),
            RangeCalendar(
              today: today,
              initialMonth: today,
              unavailableNights: {
                for (final nights in state.windows.values) ...nights,
              },
              loadingMonthKeys: state.loading,
              failedMonthKeys: state.failed,
              onMonthShown: (firstDay) => unawaited(_cubit.showMonth(firstDay)),
              onRetryMonth: (firstDay) =>
                  unawaited(_cubit.retryMonth(firstDay)),
            ),
            if (state.failed.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: Text(
                  l10n.calendarRangeLoadFailed,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.errorText,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
