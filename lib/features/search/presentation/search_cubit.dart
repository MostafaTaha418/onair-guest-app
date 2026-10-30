import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/listings/domain/results_page.dart';
import 'package:on_air/features/search/domain/last_search_store.dart';
import 'package:on_air/features/search/domain/search_criteria.dart';

enum ResultsStatus { idle, loading, ready, empty, failed, offline }

final class SearchState {
  const SearchState({
    this.criteria = SearchCriteria.empty,
    this.locationLabel,
    this.status = ResultsStatus.idle,
    this.items = const [],
    this.nextCursor,
    this.totalCount = 0,
    this.loadingMore = false,
    this.error,
    this.datesDropped = false,
    this.scrollOffset = 0,
  });

  final SearchCriteria criteria;
  final String? locationLabel;
  final ResultsStatus status;
  final List<ListingCard> items;
  final String? nextCursor;
  final int totalCount;
  final bool loadingMore;
  final ApiError? error;
  final bool datesDropped;
  final double scrollOffset;

  /// Sentinel so an explicit null replaces the old value instead of keeping
  /// it (for example a page whose nextCursor is null).
  static const _unset = Object();

  SearchState copyWith({
    SearchCriteria? criteria,
    Object? locationLabel = _unset,
    ResultsStatus? status,
    List<ListingCard>? items,
    Object? nextCursor = _unset,
    int? totalCount,
    bool? loadingMore,
    Object? error = _unset,
    Object? datesDropped = _unset,
    Object? scrollOffset = _unset,
  }) => SearchState(
    criteria: criteria ?? this.criteria,
    locationLabel: locationLabel == _unset
        ? this.locationLabel
        : locationLabel as String?,
    status: status ?? this.status,
    items: items ?? this.items,
    nextCursor: nextCursor == _unset ? this.nextCursor : nextCursor as String?,
    totalCount: totalCount ?? this.totalCount,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error == _unset ? this.error : error as ApiError?,
    datesDropped: datesDropped == _unset
        ? this.datesDropped
        : datesDropped! as bool,
    scrollOffset: scrollOffset == _unset
        ? this.scrollOffset
        : (scrollOffset! as num).toDouble(),
  );
}

/// Lives as long as the Search tab branch, so results survive tab switches
/// and details round-trips (research R9).
final class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required this._repo,
    required this._lastSearch,
    required this._connectivity,
    DateOnly Function()? today,
  }) : _today = today ?? CairoTime.today,
       super(const SearchState()) {
    unawaited(_restoreLastSearch());
  }

  final ListingsRepository _repo;
  final LastSearchStore _lastSearch;
  final ConnectivityCubit _connectivity;
  final DateOnly Function() _today;

  /// The query the results screen is currently showing, so re-entering the
  /// route with the same query never searches twice.
  String? _openedQuery;

  /// The criteria (and summary label) the currently displayed `items` were
  /// loaded for; null whenever there are no loaded items. The offline branch
  /// compares against these instead of `state.criteria`, which `setCriteria`
  /// may already have replaced with an un-searched edit.
  SearchCriteria? _loadedCriteria;
  String? _loadedLabel;

  /// Bumped by every [search] so a late response from a superseded request
  /// never overwrites newer results. Supabase RPCs cannot be cancelled, so a
  /// sequence number is the accepted stand-in for a CancelToken.
  int _generation = 0;

  Future<void> _restoreLastSearch() async {
    final saved = await _lastSearch.load(today: _today());
    // A link or an explicit search that already ran wins over the restore.
    if (isClosed || saved == null || _openedQuery != null) return;
    emit(
      state.copyWith(
        criteria: saved.criteria,
        locationLabel: saved.label,
        datesDropped: saved.criteria.datesDropped,
      ),
    );
  }

  Future<void> search(SearchCriteria criteria, {String? label}) async {
    // Bumped before the connectivity check, so a request that left while
    // online is superseded even when its would-be successor went offline.
    _generation++;
    final generation = _generation;
    if (!_connectivity.state.isOnline) {
      // A different query offline cannot dress the old results up as its
      // own; repeating the same search keeps its items under the banner.
      // The comparison uses the criteria the displayed items were loaded
      // for, because `state.criteria` may already hold an un-searched edit
      // (the dropped-dates banner and the empty-state filters button both
      // call `setCriteria` right before `search`). Maps never compare
      // structurally, so the canonical query strings are compared.
      final changed =
          _loadedCriteria == null ||
          _canonical(criteria) != _canonical(_loadedCriteria!);
      if (changed) {
        _loadedCriteria = null;
        _loadedLabel = null;
      }
      emit(
        changed
            ? state.copyWith(
                criteria: criteria,
                locationLabel: label,
                status: ResultsStatus.offline,
                datesDropped: criteria.datesDropped,
                items: const [],
                nextCursor: null,
                totalCount: 0,
                loadingMore: false,
              )
            : state.copyWith(
                criteria: criteria,
                locationLabel: label,
                status: ResultsStatus.offline,
                datesDropped: criteria.datesDropped,
              ),
      );
      return;
    }
    _openedQuery = _canonical(criteria);
    // The old items are dropped, so nothing is loaded until page 1 arrives.
    _loadedCriteria = null;
    _loadedLabel = null;
    emit(
      state.copyWith(
        criteria: criteria,
        locationLabel: label,
        status: ResultsStatus.loading,
        items: const [],
        nextCursor: null,
        totalCount: 0,
        loadingMore: false,
        error: null,
        datesDropped: criteria.datesDropped,
        scrollOffset: 0.0,
      ),
    );
    // A convenience for the next launch; it must never delay the request.
    unawaited(_lastSearch.save(criteria, label));
    try {
      final page = await _repo.searchProperties(criteria.toParams());
      if (isClosed || generation != _generation) return;
      emit(
        _applyPage(
          page,
          reset: true,
          loadedCriteria: criteria,
          loadedLabel: label,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(status: ResultsStatus.failed, error: failure.error));
    }
  }

  Future<void> loadMore() async {
    if (state.status != ResultsStatus.ready ||
        state.loadingMore ||
        state.nextCursor == null) {
      return;
    }
    if (!_connectivity.state.isOnline) return;
    final generation = _generation;
    // The next page continues the list on screen, so it uses the criteria
    // those items were loaded for — never an un-searched `setCriteria` edit.
    final loadedCriteria = _loadedCriteria ?? state.criteria;
    final loadedLabel = _loadedCriteria == null
        ? state.locationLabel
        : _loadedLabel;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repo.searchProperties(
        loadedCriteria.toParams(),
        cursor: state.nextCursor,
      );
      // A newer search owns the list; its own page 1 already arrived or is
      // on its way, so this old page (and its cursor) must be dropped.
      if (isClosed || generation != _generation) return;
      emit(_applyPage(page, reset: false));
    } on AppFailure catch (failure) {
      if (isClosed || generation != _generation) return;
      if (failure.error.code == ErrorCode.validationFailed) {
        // A bad or expired cursor: restart from page 1 (contract §8).
        await search(loadedCriteria, label: loadedLabel);
        return;
      }
      emit(state.copyWith(loadingMore: false, error: failure.error));
    }
  }

  Future<void> removeChip(FilterChipData chip) =>
      search(state.criteria.withoutChip(chip), label: state.locationLabel);

  /// Parses a results location (`/search/results?…`) and shows it. The same
  /// query twice in a row is not searched again, and the summary label
  /// survives both that repeat and a new query for the same location — it is
  /// only cleared when the location itself changes (shared links carry `loc`
  /// without a name; see specs/002-guest-discovery/research.md).
  Future<void> openFromQuery(Map<String, String> query) async {
    final criteria = SearchCriteria.fromQuery(query, today: _today());
    final canonical = _canonical(criteria);
    if (canonical == _openedQuery) {
      // The same query is never searched again, but an un-searched criteria
      // edit (setCriteria on the search screen) must not survive either.
      // The summary label reverts to the last loaded one with the criteria:
      // the link's location is what the displayed results are for, so a
      // label left behind by the un-searched edit must not linger.
      if (criteria != state.criteria) {
        emit(
          state.copyWith(
            criteria: criteria,
            locationLabel: _loadedLabel,
            datesDropped: criteria.datesDropped,
          ),
        );
      }
      return;
    }
    final sameLocation =
        criteria.locationId != null &&
        criteria.locationId == state.criteria.locationId;
    _openedQuery = canonical;
    emit(
      state.copyWith(
        criteria: criteria,
        locationLabel: sameLocation ? state.locationLabel : null,
        datesDropped: criteria.datesDropped,
      ),
    );
    await search(criteria, label: sameLocation ? state.locationLabel : null);
  }

  /// Applies edited criteria (the filters sheet) without searching.
  void setCriteria(SearchCriteria criteria, {String? label}) => emit(
    state.copyWith(
      criteria: criteria,
      locationLabel: label ?? state.locationLabel,
      datesDropped: criteria.datesDropped,
    ),
  );

  void rememberScroll(double offset) =>
      emit(state.copyWith(scrollOffset: offset));

  SearchState _applyPage(
    ResultsPage page, {
    required bool reset,
    SearchCriteria? loadedCriteria,
    String? loadedLabel,
  }) {
    final items = reset ? page.items : [...state.items, ...page.items];
    if (reset) {
      // Page 1 of a successful search: the displayed items belong to this
      // criteria and label from now on. The values come from the search
      // call itself, not `state`, so a `setCriteria` that ran mid-flight
      // cannot be mistaken for what was loaded.
      _loadedCriteria = loadedCriteria;
      _loadedLabel = loadedLabel;
    }
    return state.copyWith(
      status: page.totalCount == 0 ? ResultsStatus.empty : ResultsStatus.ready,
      items: items,
      nextCursor: page.nextCursor,
      totalCount: page.totalCount,
      loadingMore: false,
    );
  }

  String _canonical(SearchCriteria criteria) => Uri(
    queryParameters: criteria.toQuery().isEmpty ? null : criteria.toQuery(),
  ).query;

  @override
  Future<void> close() async {
    await super.close();
  }
}
