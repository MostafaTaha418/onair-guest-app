import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';

/// The calendar selection: nothing → arrival picked → confirmed range
/// (data-model "Availability").
sealed class CalendarSelection {
  const CalendarSelection();
}

final class CalendarNone extends CalendarSelection {
  const CalendarNone();
}

@immutable
final class CalendarArrivalPicked extends CalendarSelection {
  const CalendarArrivalPicked(this.day);

  final DateOnly day;

  @override
  bool operator ==(Object other) =>
      other is CalendarArrivalPicked && other.day == day;

  @override
  int get hashCode => day.hashCode;
}

@immutable
final class CalendarRange extends CalendarSelection {
  const CalendarRange(this.range);

  final StayRange range;

  @override
  bool operator ==(Object other) =>
      other is CalendarRange && other.range == range;

  @override
  int get hashCode => range.hashCode;
}

/// Unavailable nights per loaded month (key `year * 12 + month`), the
/// months being fetched or failed, and the current selection. Failed
/// months stay greyed until the cubit refetches them via retryMonth.
@immutable
final class AvailabilityState {
  const AvailabilityState({
    this.windows = const {},
    this.loading = const {},
    this.failed = const {},
    this.selection = const CalendarNone(),
    this.rangeRejected = false,
  });

  final Map<int, Set<DateOnly>> windows;
  final Set<int> loading;
  final Set<int> failed;
  final CalendarSelection selection;

  /// True only for the range pick that was just rejected; the selection has
  /// already restarted at the tapped day.
  final bool rangeRejected;

  AvailabilityState copyWith({
    Map<int, Set<DateOnly>>? windows,
    Set<int>? loading,
    Set<int>? failed,
    CalendarSelection? selection,
    bool? rangeRejected,
  }) => AvailabilityState(
    windows: windows ?? this.windows,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    selection: selection ?? this.selection,
    rangeRejected: rangeRejected ?? this.rangeRejected,
  );
}

/// Loads 3-month windows of unavailable nights and owns the calendar
/// selection (research R3). The section widget wires the `onStayConfirmed`
/// callback to `PropertyCubit.setStay`.
final class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit({
    required this._repo,
    required this._propertyId,
    required this._onStayConfirmed,
    DateOnly Function()? today,
  }) : _today = today ?? CairoTime.today,
       super(const AvailabilityState());

  final ListingsRepository _repo;
  final String _propertyId;
  final void Function(StayRange range) _onStayConfirmed;
  final DateOnly Function() _today;

  static int _monthKey(DateOnly date) => date.year * 12 + date.month;

  static DateOnly _firstOfMonth(DateOnly date) =>
      DateOnly(date.year, date.month, 1);

  static DateOnly _shiftMonth(DateOnly month, int delta) {
    final total = month.year * 12 + (month.month - 1) + delta;
    return DateOnly(total ~/ 12, (total % 12) + 1, 1);
  }

  static DateOnly _keyToFirstDay(int key) {
    final year = key ~/ 12;
    final month = key % 12;
    return month == 0 ? DateOnly(year - 1, 12, 1) : DateOnly(year, month, 1);
  }

  /// Shows [firstDay]'s month; missing months of its 3-month window are
  /// fetched in one call. Already-loaded months are never fetched again.
  Future<void> showMonth(DateOnly firstDay) async {
    final start = _firstOfMonth(firstDay);
    final missing =
        <int>{
              for (var index = 0; index < 3; index++)
                _monthKey(_shiftMonth(start, index)),
            }
            .where(
              (key) =>
                  !state.windows.containsKey(key) &&
                  !state.loading.contains(key) &&
                  !state.failed.contains(key),
            )
            .toSet();
    await _fetch(missing);
  }

  /// Refetches the failed months of [firstDay]'s window.
  Future<void> retryMonth(DateOnly firstDay) async {
    final start = _firstOfMonth(firstDay);
    final retry = <int>{
      for (var index = 0; index < 3; index++)
        _monthKey(_shiftMonth(start, index)),
    }.where(state.failed.contains).toSet();
    await _fetch(retry);
  }

  Future<void> _fetch(Set<int> keys) async {
    if (keys.isEmpty) return;
    final sorted = keys.toList()..sort();
    final from = _keyToFirstDay(sorted.first);
    final to = _firstOfMonth(_shiftMonth(_keyToFirstDay(sorted.last), 1));
    emit(
      state.copyWith(
        loading: {...state.loading, ...keys},
        failed: {...state.failed}..removeAll(keys),
      ),
    );
    try {
      final nights = await _repo.unavailableNights(_propertyId, from, to);
      if (isClosed) return;
      emit(
        state.copyWith(
          windows: {
            ...state.windows,
            for (final key in keys) key: nights,
          },
          loading: {...state.loading}..removeAll(keys),
        ),
      );
    } on AppFailure {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: {...state.loading}..removeAll(keys),
          failed: {...state.failed, ...keys},
        ),
      );
    }
  }

  /// The calendar component only reports taps; this cubit decides the
  /// selection (research R3). A range crossing an unavailable night is
  /// rejected and restarts at the tapped day as the new arrival.
  void onDayTap(DateOnly day) {
    if (day.isBefore(_today())) return;
    final selection = state.selection;
    if (selection is! CalendarArrivalPicked || !day.isAfter(selection.day)) {
      emit(
        state.copyWith(
          selection: CalendarArrivalPicked(day),
          rangeRejected: false,
        ),
      );
      return;
    }
    final range = StayRange(selection.day, day);
    if (!range.isSelectable(_unavailableNights)) {
      emit(
        state.copyWith(
          selection: CalendarArrivalPicked(day),
          rangeRejected: true,
        ),
      );
      return;
    }
    emit(state.copyWith(selection: CalendarRange(range), rangeRejected: false));
  }

  Set<DateOnly> get _unavailableNights => {
    for (final nights in state.windows.values) ...nights,
  };

  /// Called by the «تمام» button; the screen wires this to
  /// `PropertyCubit.setStay`.
  void confirm() {
    final selection = state.selection;
    if (selection is CalendarRange) _onStayConfirmed(selection.range);
  }
}
