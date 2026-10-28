import 'package:flutter/material.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Opens the date sheet; pops with the selected [StayRange], or null.
Future<StayRange?> showDateRangeSheet(BuildContext context) =>
    showModalBottomSheet<StayRange>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimens.radiusSheet),
        ),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: const DateRangeSheet(),
      ),
    );

/// The stay picker. The selection lives in this sheet's state: the first tap
/// sets check-in, a later tap sets check-out, and a tap on or before the
/// current check-in restarts with that day (research R3).
final class DateRangeSheet extends StatefulWidget {
  const DateRangeSheet({this.today, super.key});

  /// Defaults to the Cairo calendar day; injectable for tests.
  final DateOnly? today;

  @override
  State<DateRangeSheet> createState() => _DateRangeSheetState();
}

final class _DateRangeSheetState extends State<DateRangeSheet> {
  DateOnly? _checkIn;
  DateOnly? _checkOut;

  DateOnly get _today => widget.today ?? CairoTime.today();

  void _onDayTap(DateOnly day) {
    setState(() {
      if (_checkIn == null) {
        _checkIn = day;
      } else if (_checkOut == null && day.isAfter(_checkIn!)) {
        _checkOut = day;
      } else {
        _checkIn = day;
        _checkOut = null;
      }
    });
  }

  StayRange? get _confirmed => StayRange.tryCreate(_checkIn, _checkOut, _today);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final confirmed = _confirmed;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(Dimens.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RangeCalendar(
                today: _today,
                initialMonth: _today,
                selectedCheckIn: _checkIn,
                selectedCheckOut: _checkOut,
                onDayTap: _onDayTap,
              ),
              const SizedBox(height: Dimens.space8),
              if (confirmed != null)
                Text(
                  l10n.calendarNightsSelected(confirmed.nights),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              const SizedBox(height: Dimens.space12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _checkIn = null;
                        _checkOut = null;
                      }),
                      child: Text(
                        l10n.calendarClear,
                        style: context.textStyles.authButton.copyWith(
                          color: colors['textAccent'],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimens.space12),
                  Expanded(
                    child: OnAirPrimaryButton(
                      label: l10n.calendarConfirm,
                      onPressed: confirmed == null
                          ? null
                          : () => Navigator.pop(context, confirmed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
