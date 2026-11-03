import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/favorites/domain/favorites_repository.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';

final class FavoritesState {
  const FavoritesState({
    this.userId,
    this.ids = const {},
    this.cards = const [],
    this.busyIds = const {},
    this.loading = false,
    this.error = false,
  });

  final String? userId;
  final Set<String> ids;
  final List<ListingCard> cards;
  final Set<String> busyIds;
  final bool loading;
  final bool error;

  bool contains(String id) => ids.contains(id);
  bool isBusy(String id) => busyIds.contains(id);

  FavoritesState copyWith({
    Set<String>? ids,
    List<ListingCard>? cards,
    Set<String>? busyIds,
    bool? loading,
    bool? error,
  }) => FavoritesState(
    userId: userId,
    ids: ids ?? this.ids,
    cards: cards ?? this.cards,
    busyIds: busyIds ?? this.busyIds,
    loading: loading ?? this.loading,
    error: error ?? this.error,
  );
}

final class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({
    required this.repository,
    required this.listings,
    required AuthCubit auth,
  }) : super(const FavoritesState()) {
    _subscription = auth.stream.listen(_onAuthChanged);
    _onAuthChanged(auth.state);
  }

  final FavoritesRepository repository;
  final ListingsRepository listings;
  late final StreamSubscription<AuthState> _subscription;
  int _generation = 0;

  void _onAuthChanged(AuthState auth) {
    if (isClosed) return;
    if (auth is SignedIn) {
      if (state.userId == auth.account.id) return;
      emit(FavoritesState(userId: auth.account.id, loading: true));
      unawaited(refresh());
    } else if (auth is SignedOut ||
        auth is SessionEnded ||
        auth is SigningOut) {
      _generation++;
      emit(const FavoritesState());
    }
  }

  Future<void> refresh() async {
    final userId = state.userId;
    if (userId == null) return;
    final generation = ++_generation;
    emit(state.copyWith(loading: true, error: false));
    try {
      final ids = await repository.listPropertyIds(userId);
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(ids: ids.toSet()));
      final cards = <ListingCard>[];
      for (final id in ids) {
        try {
          final property = await listings.property(id);
          cards.add(
            ListingCard(
              id: property.id,
              title: property.title,
              propertyType: property.propertyType,
              areaName: property.areaName,
              cityName: property.cityName,
              cover: property.images.firstOrNull,
              nightlyPrice: property.nightlyPrice,
              ratingAvg: property.ratingAvg,
              reviewCount: property.reviewCount,
              stay: null,
            ),
          );
        } on Object {
          // An unpublished or removed property no longer has public details.
        }
        if (isClosed || generation != _generation) return;
      }
      emit(state.copyWith(cards: cards, loading: false));
    } on Object {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(loading: false, error: true));
    }
  }

  Future<void> toggle(ListingCard card) async {
    final userId = state.userId;
    if (userId == null || state.loading || state.isBusy(card.id)) return;
    final wasFavorite = state.contains(card.id);
    emit(state.copyWith(busyIds: {...state.busyIds, card.id}));
    try {
      if (wasFavorite) {
        await repository.remove(userId, card.id);
      } else {
        await repository.add(userId, card.id);
      }
      if (isClosed || state.userId != userId) return;
      final ids = {...state.ids};
      final cards = [...state.cards];
      if (wasFavorite) {
        ids.remove(card.id);
        cards.removeWhere((item) => item.id == card.id);
      } else {
        ids.add(card.id);
        cards
          ..removeWhere((item) => item.id == card.id)
          ..insert(0, card);
      }
      emit(state.copyWith(ids: ids, cards: cards));
    } finally {
      if (!isClosed && state.userId == userId) {
        final busy = {...state.busyIds}..remove(card.id);
        emit(state.copyWith(busyIds: busy));
      }
    }
  }

  @override
  Future<void> close() async {
    ++_generation;
    await _subscription.cancel();
    await super.close();
  }
}
