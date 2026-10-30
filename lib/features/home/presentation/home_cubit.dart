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
  }) : _auth = auth,
       super(HomeState(offline: !connectivity.state.isOnline)) {
    _authSubscription = auth.stream.listen(_onAuthChanged);
    _connectivitySubscription = connectivity.stream.listen(
      _onConnectivityChanged,
    );
  }

  final ListingsRepository _repo;
  final HomeFeedCache _cache;
  final ReferenceDataCache _reference;

  /// Kept so a feed response is checked against the *current* auth state
  /// before it reaches the UI (Constitution III).
  final AuthCubit _auth;

  /// Bumped on every signed-in/signed-out transition, so a feed response is
  /// discarded when the account it was requested for is no longer the one
  /// signed in — a booking must never cross accounts.
  int _authEpoch = 0;

  /// Bumped by every feed request, so a response that lands after a newer
  /// one started (a refresh overtaking a section retry or another refresh)
  /// is dropped instead of overwriting newer state. Supabase RPCs cannot be
  /// cancelled, so a sequence number stands in for a CancelToken.
  int _requestSeq = 0;

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
    final epoch = _authEpoch;
    _requestSeq++;
    final seq = _requestSeq;
    try {
      var feed = await _repo.homeFeed();
      if (isClosed) return;
      // A newer request owns the screen now: drop this response entirely —
      // emitting it would overwrite newer sections with older ones. The
      // newest request is the one that clears `sectionLoading`.
      if (seq != _requestSeq) return;
      // Still the newest request, but the account changed while it was in
      // flight (a sign-out starts no new request): keep the public sections
      // so the screen never stays on skeletons, and strip the booking that
      // was requested under the old session (Constitution III). A sign-in
      // always starts a newer request, so it is handled by the check above.
      if (epoch != _authEpoch || _auth.state is! SignedIn) {
        feed = _copy(feed, upcomingBooking: const FeedSectionReady(null));
      }
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
      // The same staleness rule as the success path: a newer request owns
      // the failure handling (its own result or its retry state). A failure
      // carries no personal data, so an auth change alone does not drop it.
      if (seq != _requestSeq) return;
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
      _authEpoch++;
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
      _authEpoch++;
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
