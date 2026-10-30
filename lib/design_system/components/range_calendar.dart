import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// A single-month range calendar for stays (research R3).
///
/// The component does not decide selection: it reports day taps through
/// [onDayTap] and lets the caller own the state. Weeks start on Saturday
/// (Egypt), and month names come from the `ar` locale.
final class RangeCalendar extends StatefulWidget {
  const RangeCalendar({
    required this.today,
    required this.initialMonth,
    required this.onDayTap,
    this.selectedCheckIn,
    this.selectedCheckOut,
    this.unavailableNights = const {},
    this.loadingMonthKeys = const {},
    this.failedMonthKeys = const {},
    this.onMonthShown,
    this.onRetryMonth,
    this.lastSelectableDay,
    super.key,
  });

  final DateOnly today;
  final DateOnly initialMonth;
  final DateOnly? selectedCheckIn;
  final DateOnly? selectedCheckOut;
  final Set<DateOnly> unavailableNights;

  /// Months being fetched, keyed by `year * 12 + month`; every day is greyed
  /// and not tappable.
  final Set<int> loadingMonthKeys;

  /// Months whose fetch failed; their days are greyed and not tappable like
  /// the loading ones, and a retry button is shown for the displayed month.
  final Set<int> failedMonthKeys;
  final void Function(DateOnly day) onDayTap;
  final void Function(DateOnly firstDayOfMonth)? onMonthShown;

  /// Reports the displayed month for a retry after its fetch failed.
  final void Function(DateOnly firstDayOfMonth)? onRetryMonth;
  final DateOnly? lastSelectableDay;

  static int monthKey(DateOnly date) => date.year * 12 + date.month;

  @override
  State<RangeCalendar> createState() => _RangeCalendarState();
}

final class _RangeCalendarState extends State<RangeCalendar> {
  late DateOnly _displayedMonth = _firstOfMonth(widget.initialMonth);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMonthShown?.call(_displayedMonth);
    });
  }

  DateOnly _firstOfMonth(DateOnly date) => DateOnly(date.year, date.month, 1);

  DateOnly _shiftMonth(DateOnly month, int delta) {
    final total = month.year * 12 + (month.month - 1) + delta;
    return DateOnly(total ~/ 12, (total % 12) + 1, 1);
  }

  void _goToMonth(int delta) {
    if (!_canGo(delta)) return;
    final next = _shiftMonth(_displayedMonth, delta);
    setState(() => _displayedMonth = next);
    widget.onMonthShown?.call(next);
  }

  bool _canGo(int delta) {
    final target = _shiftMonth(_displayedMonth, delta);
    if (target.isBefore(_firstOfMonth(widget.today))) return false;
    final lastMonth = widget.lastSelectableDay;
    if (lastMonth != null && _firstOfMonth(lastMonth).isBefore(target)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final daysInMonth = _displayedMonth.daysUntil(
      _firstOfMonth(_shiftMonth(_displayedMonth, 1)),
    );
    final leadingBlanks = _columnOf(_displayedMonth);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.calendarPrevMonth,
              onPressed: _canGo(-1) ? () => _goToMonth(-1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
            Expanded(
              child: Text(
                DateOnlyFormatter.monthYear(_displayedMonth),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.calendarNextMonth,
              onPressed: _canGo(1) ? () => _goToMonth(1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: Dimens.space4,
          crossAxisSpacing: Dimens.space4,
          children: [
            for (var index = 0; index < leadingBlanks; index++)
              const SizedBox.shrink(),
            for (var index = 0; index < 7; index++)
              Center(
                child: Text(
                  _weekdayInitial(index),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            for (var day = 1; day <= daysInMonth; day++)
              _dayCell(
                context,
                DateOnly(_displayedMonth.year, _displayedMonth.month, day),
              ),
          ],
        ),
        if (_retryVisible) ...[
          const SizedBox(height: Dimens.space4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => widget.onRetryMonth!(_displayedMonth),
              child: Text(l10n.retry),
            ),
          ),
        ],
      ],
    );
  }

  bool get _retryVisible =>
      widget.onRetryMonth != null &&
      widget.failedMonthKeys.contains(RangeCalendar.monthKey(_displayedMonth));

  /// Column index of a date, with Saturday first (Egypt week). Dart's
  /// weekday runs Monday = 1 … Sunday = 7.
  int _columnOf(DateOnly date) =>
      (DateTime.utc(date.year, date.month, date.day).weekday + 1) % 7;

  String _weekdayInitial(int column) {
    // 2026-11-07 is a Saturday; stepping 0..6 covers السبت…الجمعة.
    final saturday = DateTime.utc(2026, 11, 7).add(Duration(days: column));
    return DateFormat.E('ar').format(saturday);
  }

  Widget _dayCell(BuildContext context, DateOnly day) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final isPast = day.isBefore(widget.today);
    final isBeyond =
        widget.lastSelectableDay != null &&
        day.isAfter(widget.lastSelectableDay!);
    final isLoading = widget.loadingMonthKeys.contains(
      RangeCalendar.monthKey(day),
    );
    final isFailed = widget.failedMonthKeys.contains(
      RangeCalendar.monthKey(day),
    );
    final disabled = isPast || isBeyond || isLoading || isFailed;
    final unavailable = widget.unavailableNights.contains(day);
    final isStart = day == widget.selectedCheckIn;
    final isEnd = day == widget.selectedCheckOut;
    final checkIn = widget.selectedCheckIn;
    final checkOut = widget.selectedCheckOut;
    final inRange =
        !isStart &&
        !isEnd &&
        checkIn != null &&
        checkOut != null &&
        day.isAfter(checkIn) &&
        day.isBefore(checkOut);

    Color? background;
    var foreground = colors.textPrimary;
    var decoration = TextDecoration.none;
    if (isStart || isEnd) {
      background = colors.primary;
      foreground = colors.onPrimary;
    } else if (inRange) {
      background = colors['badgeNavActive'];
    } else if (isPast || isLoading || isFailed) {
      foreground = colors['placeholder'];
    } else if (unavailable) {
      foreground = colors.textSecondary;
      decoration = TextDecoration.lineThrough;
    }

    final label = unavailable
        ? l10n.calendarUnavailableDay(DateOnlyFormatter.dayMonth(day))
        : DateOnlyFormatter.dayMonth(day);
    final text = Text(
      '${day.day}',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: foreground,
        decoration: decoration,
      ),
    );
    final cell = Semantics(
      label: label,
      button: !disabled,
      selected: isStart || isEnd,
      excludeSemantics: true,
      child: Center(
        child: Container(
          width: Dimens.minTouchTarget,
          height: Dimens.minTouchTarget,
          alignment: Alignment.center,
          decoration: background == null
              ? null
              : BoxDecoration(color: background, shape: BoxShape.circle),
          child: text,
        ),
      ),
    );
    if (disabled) return cell;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => widget.onDayTap(day),
      child: cell,
    );
  }
}
