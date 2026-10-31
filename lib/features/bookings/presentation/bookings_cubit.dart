import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';

enum TabLoad { initial, loading, ready, failed, offline }

@immutable
final class TabData {
  const TabData({
    this.items = const [],
    this.nextCursor,
    this.load = TabLoad.initial,
    this.error,
    this.fetchedAt,
    this.fromCache = false,
    this.loadingMore = false,
  });

  final List<BookingSummary> items;
  final String? nextCursor;
  final TabLoad load;
  final ApiError? error;

  /// When the shown page was fetched (also for the cached copy).
  final DateTime? fetchedAt;
  final bool fromCache;
  final bool loadingMore;

  static const _unset = Object();

  TabData copyWith({
    List<BookingSummary>? items,
    Object? nextCursor = _unset,
    TabLoad? load,
    Object? error = _unset,
    Object? fetchedAt = _unset,
    bool? fromCache,
    bool? loadingMore,
  }) => TabData(
    items: items ?? this.items,
    nextCursor: nextCursor == _unset ? this.nextCursor : nextCursor as String?,
    load: load ?? this.load,
    error: error == _unset ? this.error : error as ApiError?,
    fetchedAt: fetchedAt == _unset ? this.fetchedAt : fetchedAt as DateTime?,
    fromCache: fromCache ?? this.fromCache,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

@immutable
final class BookingsState {
  const BookingsState({required this.selected, required this.tabs});

  final BookingTab selected;

  /// Only `current`, `past`, and `cancelled` — the pending tab never shows.
  final Map<BookingTab, TabData> tabs;
}

/// My Bookings (US3): one tab map, cache-first per tab, server-fresh after.
/// The list is the server's — no sorting or filtering happens here.
final class BookingsCubit extends Cubit<BookingsState> {
  BookingsCubit({
    required this._bookings,
    required this._cache,
    required this._connectivity,
  }) : super(
         BookingsState(
           selected: BookingTab.current,
           tabs: {
             for (final tab in _tabs) tab: const TabData(),
           },
         ),
       );

  static const List<BookingTab> _tabs = [
    BookingTab.current,
    BookingTab.past,
    BookingTab.cancelled,
  ];

  final BookingsRepository _bookings;
  final BookingsCache _cache;
  final ConnectivityCubit _connectivity;

  /// Bumped per tab so a late response from a superseded request never
  /// overwrites newer results (research R12 pattern).
  final Map<BookingTab, int> _generations = {};

  int _bump(BookingTab tab) {
    final generation = (_generations[tab] ?? 0) + 1;
    _generations[tab] = generation;
    return generation;
  }

  bool _stale(BookingTab tab, int generation) =>
      isClosed || generation != _generations[tab];

  void _emitTab(BookingTab tab, TabData data) {
    emit(
      BookingsState(
        selected: state.selected,
        tabs: {
          ...state.tabs,
          tab: data,
        },
      ),
    );
  }

  Future<void> start(BookingTab initial) async {
    emit(BookingsState(selected: initial, tabs: state.tabs));
    await _loadTab(initial);
  }

  /// Loads a tab the first time it is shown; a loaded tab never refetches.
  Future<void> selectTab(BookingTab tab) async {
    if (tab == state.selected) return;
    emit(BookingsState(selected: tab, tabs: state.tabs));
    final data = state.tabs[tab]!;
    if (data.load != TabLoad.initial) return;
    await _loadTab(tab);
  }

  Future<void> refresh() => _loadTab(state.selected, force: true);

  /// Reloads one tab (the per-tab error retry).
  Future<void> retryTab(BookingTab tab) => _loadTab(tab, force: true);

  Future<void> _loadTab(BookingTab tab, {bool force = false}) async {
    final generation = _bump(tab);
    if (!_connectivity.state.isOnline) {
      final cached = await _cache.readTab(tab);
      if (_stale(tab, generation)) return;
      if (cached != null) {
        _emitTab(
          tab,
          TabData(
            items: cached.items,
            load: TabLoad.ready,
            fetchedAt: cached.fetchedAt,
            fromCache: true,
          ),
        );
      } else {
        _emitTab(tab, const TabData(load: TabLoad.offline));
      }
      return;
    }
    if (!force) {
      final cached = await _cache.readTab(tab);
      if (_stale(tab, generation)) return;
      if (cached != null && cached.items.isNotEmpty) {
        _emitTab(
          tab,
          TabData(
            items: cached.items,
            load: TabLoad.ready,
            fetchedAt: cached.fetchedAt,
            fromCache: true,
          ),
        );
      } else {
        _emitTab(tab, const TabData(load: TabLoad.loading));
      }
    }
    try {
      final page = await _bookings.listBookings(tab);
      if (_stale(tab, generation)) return;
      await _cache.saveTab(tab, page.items);
      if (_stale(tab, generation)) return;
      _emitTab(
        tab,
        TabData(
          items: page.items,
          nextCursor: page.nextCursor,
          load: TabLoad.ready,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
    } on AppFailure catch (failure) {
      if (_stale(tab, generation)) return;
      _emitTab(
        tab,
        TabData(load: TabLoad.failed, error: failure.error),
      );
    }
  }

  /// Appends the next page of the selected tab; stops when the server has
  /// no more pages, and never runs twice at once.
  Future<void> loadMore() async {
    final tab = state.selected;
    final data = state.tabs[tab]!;
    if (data.loadingMore ||
        data.load != TabLoad.ready ||
        data.nextCursor == null) {
      return;
    }
    if (!_connectivity.state.isOnline) return;
    final generation = _generations[tab] ?? 0;
    _emitTab(tab, data.copyWith(loadingMore: true));
    try {
      final page = await _bookings.listBookings(tab, cursor: data.nextCursor);
      if (isClosed || generation != _generations[tab]) return;
      final current = state.tabs[tab]!;
      _emitTab(
        tab,
        current.copyWith(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          loadingMore: false,
        ),
      );
    } on AppFailure {
      if (isClosed || generation != _generations[tab]) return;
      _emitTab(tab, state.tabs[tab]!.copyWith(loadingMore: false));
    }
  }
}
