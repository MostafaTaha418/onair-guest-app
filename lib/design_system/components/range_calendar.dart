import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/booking_flow_kit.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// How [RangeCalendar] draws its days: the original pills, or the booking
/// redesign's band (48dp rows, a highlight band across the range, struck
/// unavailable nights and an outlined today).
enum RangeCalendarStyle { classic, banded }

/// A single-month range calendar for stays (research R3).
///
/// The component does not decide selection: it reports day taps through
/// [onDayTap] and lets the caller own the state. Weeks start on Saturday
/// (Egypt), and month names come from the `ar` locale.
final class RangeCalendar extends StatefulWidget {
  const RangeCalendar({
    required this.today,
    required this.initialMonth,
    this.onDayTap,
    this.selectedCheckIn,
    this.selectedCheckOut,
    this.unavailableNights = const {},
    this.loadingMonthKeys = const {},
    this.failedMonthKeys = const {},
    this.onMonthShown,
    this.onRetryMonth,
    this.lastSelectableDay,
    this.style = RangeCalendarStyle.classic,
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

  /// Null renders the calendar read-only: past, loading and unavailable
  /// nights keep their disabled look, and selectable days stop responding.
  final void Function(DateOnly day)? onDayTap;
  final void Function(DateOnly firstDayOfMonth)? onMonthShown;

  /// Reports the displayed month for a retry after its fetch failed.
  final void Function(DateOnly firstDayOfMonth)? onRetryMonth;
  final DateOnly? lastSelectableDay;
  final RangeCalendarStyle style;

  static int monthKey(DateOnly date) => date.year * 12 + date.month;

  @override
  State<RangeCalendar> createState() => _RangeCalendarState();
}

final class _RangeCalendarState extends State<RangeCalendar> {
  late DateOnly _displayedMonth = _firstOfMonth(widget.initialMonth);

  /// +1 after "next month", -1 after "previous": the banded grid slides in
  /// from that side.
  var _slide = 1;

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
    setState(() {
      _displayedMonth = next;
      _slide = delta.sign;
    });
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
    if (widget.style == RangeCalendarStyle.banded) return _buildBanded(context);
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final daysInMonth = _displayedMonth.daysUntil(
      _firstOfMonth(_shiftMonth(_displayedMonth, 1)),
    );
    final leadingBlanks = _columnOf(_displayedMonth, l10n.localeName);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.calendarPrevMonth,
              onPressed: _canGo(-1) ? () => _goToMonth(-1) : null,
              icon: Icon(
                Directionality.of(context) == ui.TextDirection.rtl
                    ? AppIcons.chevronRight
                    : AppIcons.chevronLeft,
              ),
            ),
            Expanded(
              child: Text(
                DateOnlyFormatter.monthYear(
                  _displayedMonth,
                  locale: l10n.localeName,
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.calendarNextMonth,
              onPressed: _canGo(1) ? () => _goToMonth(1) : null,
              icon: Icon(
                Directionality.of(context) == ui.TextDirection.rtl
                    ? AppIcons.chevronLeft
                    : AppIcons.chevronRight,
              ),
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
            for (var index = 0; index < 7; index++)
              Center(
                child: Semantics(
                  label: _weekdayInitial(index, l10n.localeName),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _weekdayInitial(index, l10n.localeName),
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            for (var index = 0; index < leadingBlanks; index++)
              const SizedBox.shrink(),
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
  int _columnOf(DateOnly date, String locale) {
    final weekday = DateTime.utc(date.year, date.month, date.day).weekday;
    return locale.startsWith('ar') ? (weekday + 1) % 7 : weekday % 7;
  }

  /// The weekday header; [narrow] is the one-letter form (س ح ن …) the
  /// banded grid uses so 1.3× text never runs the names together.
  String _weekdayInitial(int column, String locale, {bool narrow = false}) {
    final firstDay = locale.startsWith('ar')
        ? DateTime.utc(2026, 11, 7)
        : DateTime.utc(2026, 11, 8);
    final format = narrow ? DateFormat('EEEEE', locale) : DateFormat.E(locale);
    return format.format(firstDay.add(Duration(days: column)));
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
    final isToday = day == widget.today;
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
    Color? outline;
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
    } else if (isToday) {
      // A marked but clearly not-selected today: an outline, never the
      // filled pill a picked day wears.
      outline = colors.primary;
      foreground = colors.primary;
    }

    final label = unavailable
        ? l10n.calendarUnavailableDay(
            DateOnlyFormatter.dayMonth(day, locale: l10n.localeName),
          )
        : DateOnlyFormatter.dayMonth(day, locale: l10n.localeName);
    final text = Text(
      '${day.day}',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: foreground,
        decoration: decoration,
      ),
    );
    final cell = Semantics(
      label: label,
      button: !disabled && widget.onDayTap != null,
      selected: isStart || isEnd,
      excludeSemantics: true,
      child: Center(
        child: Container(
          width: Dimens.minTouchTarget,
          height: Dimens.minTouchTarget,
          alignment: Alignment.center,
          decoration: background == null && outline == null
              ? null
              : BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: outline == null
                      ? null
                      : Border.all(color: outline, width: 1.5),
                ),
          child: text,
        ),
      ),
    );
    if (disabled) return cell;
    final onTap = widget.onDayTap;
    if (onTap == null) return cell;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => onTap(day),
      child: cell,
    );
  }

  Widget _navButton(BuildContext context, int delta) {
    final l10n = AppLocalizations.of(context);
    final rtl = Directionality.of(context) == ui.TextDirection.rtl;
    final enabled = _canGo(delta);
    final forward = delta > 0;
    return IconButton(
      tooltip: forward ? l10n.calendarNextMonth : l10n.calendarPrevMonth,
      onPressed: enabled ? () => _goToMonth(delta) : null,
      color: context.colors.textPrimary,
      disabledColor: FlowPalette.of(context).disabledForeground,
      icon: Icon(
        forward == rtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
        size: 24,
      ),
    );
  }

  Widget _buildBanded(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final palette = FlowPalette.of(context);
    final daysInMonth = _displayedMonth.daysUntil(
      _firstOfMonth(_shiftMonth(_displayedMonth, 1)),
    );
    final leadingBlanks = _columnOf(_displayedMonth, l10n.localeName);
    final key = RangeCalendar.monthKey(_displayedMonth);
    final loading = widget.loadingMonthKeys.contains(key);
    final failed = widget.failedMonthKeys.contains(key);
    final title = DateOnlyFormatter.monthYear(
      _displayedMonth,
      locale: l10n.localeName,
    );
    final slots = <DateOnly?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateOnly(_displayedMonth.year, _displayedMonth.month, day),
    ];
    while (slots.length % 7 != 0) {
      slots.add(null);
    }
    final rtl = Directionality.of(context) == ui.TextDirection.rtl;
    final grid = Column(
      key: ValueKey(key),
      children: [
        for (var week = 0; week < slots.length ~/ 7; week++) ...[
          if (week > 0) const SizedBox(height: 2),
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: SizedBox(
                    height: Dimens.minTouchTarget,
                    child: slots[week * 7 + column] == null
                        ? const SizedBox.shrink()
                        : _bandedCell(
                            context,
                            slots[week * 7 + column]!,
                            column,
                          ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _navButton(context, -1),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            _navButton(context, 1),
          ],
        ),
        ExcludeSemantics(
          child: SizedBox(
            height: 32,
            child: Row(
              children: [
                for (var index = 0; index < 7; index++)
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _weekdayInitial(
                            index,
                            l10n.localeName,
                            narrow: true,
                          ),
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        RepaintBoundary(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedSwitcher(
                duration: flowDuration(context, 320),
                switchInCurve: flowEmphasized,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [?current],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0.08 * _slide * (rtl ? -1 : 1), 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: grid,
              ),
              if (loading)
                PositionedDirectional(
                  top: -4,
                  start: Dimens.space12,
                  end: Dimens.space12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: colors.primary,
                      backgroundColor: palette.highlight,
                      semanticsLabel: l10n.loading,
                    ),
                  ),
                ),
              if (failed && widget.onRetryMonth != null)
                Positioned.fill(
                  child: Center(
                    child: FlowButton(
                      label: l10n.retry,
                      icon: AppIcons.refresh,
                      kind: FlowButtonKind.outlined,
                      expand: false,
                      onPressed: () => widget.onRetryMonth!(_displayedMonth),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bandedCell(BuildContext context, DateOnly day, int column) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final palette = FlowPalette.of(context);
    final isPast = day.isBefore(widget.today);
    final isBeyond =
        widget.lastSelectableDay != null &&
        day.isAfter(widget.lastSelectableDay!);
    final monthKey = RangeCalendar.monthKey(day);
    final pending =
        widget.loadingMonthKeys.contains(monthKey) ||
        widget.failedMonthKeys.contains(monthKey);
    final dim = isPast || isBeyond || pending;
    final unavailable = widget.unavailableNights.contains(day);
    final isToday = day == widget.today;
    final checkIn = widget.selectedCheckIn;
    final checkOut = widget.selectedCheckOut;
    final isStart = day == checkIn;
    final isEnd = day == checkOut;
    final edge = isStart || isEnd;
    final ranged = checkIn != null && checkOut != null;
    final inRange = ranged && day.isAfter(checkIn) && day.isBefore(checkOut);
    // An unavailable night can still close a stay: it is a departure day —
    // after the check-in, or after a departure kept alone (that departure
    // then becomes the check-in).
    final canDepart = checkIn != null
        ? day.isAfter(checkIn)
        : checkOut != null && day.isAfter(checkOut);
    // A picked day always answers a tap, so it can be removed.
    final tappable =
        widget.onDayTap != null && !dim && (edge || !unavailable || canDepart);

    final foreground = edge
        ? colors.onPrimary
        : unavailable
        ? colors.textSecondary
        : colors.textPrimary;
    final dateText = DateOnlyFormatter.dayMonth(day, locale: l10n.localeName);
    final label = [
      if (unavailable) l10n.calendarUnavailableDay(dateText) else dateText,
      if (isToday) l10n.calendarToday,
      if (isStart) l10n.bookingStepCheckIn,
      if (isEnd) l10n.bookingStepCheckOut,
    ].join(l10n.localeName.startsWith('ar') ? '، ' : ', ');

    final circle = LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth - 2).clamp(24.0, 40.0);
        return TweenAnimationBuilder<double>(
          key: ValueKey('pulse-$edge'),
          tween: Tween(begin: edge ? 0 : 1, end: 1),
          duration: flowDuration(context, 420),
          curve: flowEmphasized,
          builder: (context, t, child) {
            final scale = TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween(begin: 0.86, end: 1.08),
                weight: 55,
              ),
              TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 45),
            ]).transform(t);
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: flowDuration(context, 200),
            width: size,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: edge ? colors.primary : colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: isToday && !edge
                  ? Border.all(color: colors.primary, width: 1.5)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: edge || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: foreground,
                  ),
                ),
                if (unavailable && !edge)
                  PositionedDirectional(
                    start: size * 0.22,
                    end: size * 0.22,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: flowDuration(context, 320 + column * 18),
                      curve: Interval(
                        (column * 18) / (320 + column * 18),
                        1,
                        curve: flowEmphasized,
                      ),
                      builder: (context, t, _) => Transform.scale(
                        scaleX: t,
                        child: Container(height: 1.5, color: foreground),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    final body = Stack(
      children: [
        Positioned.fill(
          top: 4,
          bottom: 4,
          child: Row(
            children: [
              Expanded(
                child: ColoredBox(
                  color: ranged && (inRange || isEnd)
                      ? palette.highlight
                      : colors.transparent,
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: ranged && (inRange || isStart)
                      ? palette.highlight
                      : colors.transparent,
                ),
              ),
            ],
          ),
        ),
        Center(child: circle),
      ],
    );

    return Semantics(
      label: label,
      button: tappable,
      selected: edge,
      enabled: !dim,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: flowDuration(context, 280),
        curve: flowEmphasized,
        opacity: dim ? 0.38 : 1,
        child: tappable
            ? InkWell(
                customBorder: const CircleBorder(),
                onTap: () => widget.onDayTap!(day),
                child: body,
              )
            : body,
      ),
    );
  }
}
