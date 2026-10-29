import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/home/data/home_feed_cache.dart';
import 'package:on_air/features/listings/data/reference_data_cache.dart';
import 'package:on_air/features/listings/domain/home_feed.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';

enum HomeSectionId { areas, suggested, newest, upcoming }

final class HomeState {
  const HomeState({
    this.feed,
    this.sectionLoading = const {},
    this.refreshing = false,
    this.offline = false,
    this.fatalError,
  });

  final HomeFeed? feed;

  /// Which sections show skeletons; the feed may still hold the cached
  /// values underneath.
  final Map<HomeSectionId, bool> sectionLoading;
  final bool refreshing;
  final bool offline;

  /// The whole-feed failure when there is no cache to show.
  final ApiError? fatalError;

  HomeState copyWith({
    HomeFeed? feed,
    Map<HomeSectionId, bool>? sectionLoading,
    bool? refreshing,
    bool? offline,
    Object? fatalError = _unset,
  }) => HomeState(
    feed: feed ?? this.feed,
    sectionLoading: sectionLoading ?? this.sectionLoading,
    refreshing: refreshing ?? this.refreshing,
    offline: offline ?? this.offline,
    fatalError: fatalError == _unset
        ? this.fatalError
        : fatalError as ApiError?,
  );

  static const _unset = Object();
}

/// Stale-while-revalidate Home state (research R6): show the cache, fetch
/// fresh, save the public sections, and keep every section independent
/// (FR-004). Lives on the Home branch.
final class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this._repo,
    required this._cache,
    required this._reference,
    required ConnectivityCubit connectivity,
    required AuthCubit auth,
  }) : super(HomeState(offline: !connectivity.state.isOnline)) {
    _authSubscription = auth.stream.listen(_onAuthChanged);
    _connectivitySubscription = connectivity.stream.listen(
      _onConnectivityChanged,
    );
  }

  final ListingsRepository _repo;
  final HomeFeedCache _cache;
  final ReferenceDataCache _reference;

  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription<ConnectivityState> _connectivitySubscription;

  /// Shows the cache (when there is one), then fetches fresh data and saves
  /// its public sections.
  Future<void> start() async {
    final cached = await _cache.load();
    if (isClosed) return;
    if (cached != null) {
      emit(state.copyWith(feed: cached, refreshing: true));
    } else {
      emit(
        state.copyWith(
          sectionLoading: {
            for (final id in HomeSectionId.values) id: true,
          },
        ),
      );
    }
    await _loadFeed();
  }

  Future<void> refresh() async {
    emit(state.copyWith(refreshing: true));
    await _loadFeed();
  }

  /// A section retry calls the feed again and replaces only that section
  /// (research R6).
  Future<void> retrySection(HomeSectionId id) async {
    emit(
      state.copyWith(
        sectionLoading: {...state.sectionLoading, id: true},
      ),
    );
    await _loadFeed(retrySection: id);
  }

  Future<void> _loadFeed({HomeSectionId? retrySection}) async {
    try {
      final feed = await _repo.homeFeed();
      if (isClosed) return;
      if (retrySection == null) {
        emit(
          state.copyWith(
            feed: feed,
            sectionLoading: const {},
            refreshing: false,
            fatalError: null,
          ),
        );
        await _cache.save(feed);
      } else {
        final current = state.feed;
        final replacement = _sectionOf(feed, retrySection);
        if (current == null) {
          emit(
            state.copyWith(
              feed: feed,
              sectionLoading: {...state.sectionLoading, retrySection: false},
              refreshing: false,
            ),
          );
        } else {
          emit(
            state.copyWith(
              feed: _withSection(current, retrySection, replacement),
              sectionLoading: {...state.sectionLoading, retrySection: false},
              refreshing: false,
            ),
          );
        }
      }
      await _reference.refreshIfVersionChanged(feed.referenceVersion);
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (state.feed == null) {
        // Nothing cached: the whole screen failed.
        emit(
          state.copyWith(
            sectionLoading: const {},
            refreshing: false,
            fatalError: failure.error,
          ),
        );
        return;
      }
      // Offline or a server problem with a cache: keep showing the cache
      // (research R6).
      emit(
        state.copyWith(
          sectionLoading: const {},
          refreshing: false,
        ),
      );
    }
  }

  FeedSection<Object?> _sectionOf(HomeFeed feed, HomeSectionId id) =>
      switch (id) {
        HomeSectionId.areas => feed.areas,
        HomeSectionId.suggested => feed.suggested,
        HomeSectionId.newest => feed.newest,
        HomeSectionId.upcoming => feed.upcomingBooking,
      };

  HomeFeed _withSection(
    HomeFeed feed,
    HomeSectionId id,
    FeedSection<Object?> section,
  ) => switch (id) {
    HomeSectionId.areas => _copy(
      feed,
      areas: section as FeedSection<List<AreaTile>>,
    ),
    HomeSectionId.suggested => _copy(
      feed,
      suggested: section as FeedSection<List<ListingCard>>,
    ),
    HomeSectionId.newest => _copy(
      feed,
      newest: section as FeedSection<List<ListingCard>>,
    ),
    HomeSectionId.upcoming => _copy(
      feed,
      upcomingBooking: section as FeedSection<UpcomingBookingCard?>,
    ),
  };

  HomeFeed _copy(
    HomeFeed feed, {
    FeedSection<List<AreaTile>>? areas,
    FeedSection<List<ListingCard>>? suggested,
    FeedSection<List<ListingCard>>? newest,
    FeedSection<UpcomingBookingCard?>? upcomingBooking,
  }) => HomeFeed(
    referenceVersion: feed.referenceVersion,
    areas: areas ?? feed.areas,
    suggested: suggested ?? feed.suggested,
    newest: newest ?? feed.newest,
    upcomingBooking: upcomingBooking ?? feed.upcomingBooking,
    fetchedAt: feed.fetchedAt,
  );

  void _onAuthChanged(AuthState authState) {
    if (isClosed) return;
    // The auth layer signals a session end either as SignedOut or as
    // SessionEnded (external account changes); both are personal-data
    // events (Constitution III).
    final ended = authState is SignedOut || authState is SessionEnded;
    if (ended) {
      final feed = state.feed;
      if (feed == null) return;
      emit(
        state.copyWith(
          feed: _copy(feed, upcomingBooking: const FeedSectionReady(null)),
        ),
      );
      return;
    }
    if (authState is SignedIn) {
      unawaited(refresh());
    }
  }

  void _onConnectivityChanged(ConnectivityState connectivityState) {
    if (isClosed) return;
    emit(state.copyWith(offline: !connectivityState.isOnline));
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await _connectivitySubscription.cancel();
    await super.close();
  }
}
