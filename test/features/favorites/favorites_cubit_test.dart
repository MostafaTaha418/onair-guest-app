import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/auth/domain/guest_account.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/features/favorites/data/memory_favorites_repository.dart';
import 'package:on_air/features/favorites/domain/favorites_repository.dart';
import 'package:on_air/features/favorites/presentation/favorites_cubit.dart';
import 'package:on_air/features/listings/domain/listing_card.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_listings_repository.dart';

final class _SlowFavorites implements FavoritesRepository {
  final ids = <String>[];
  final Completer<void> adding = Completer<void>();
  int addCalls = 0;

  @override
  Future<List<String>> listPropertyIds(String userId) async => List.of(ids);

  @override
  Future<void> add(String userId, String propertyId) async {
    addCalls++;
    await adding.future;
    ids.add(propertyId);
  }

  @override
  Future<void> remove(String userId, String propertyId) async {
    ids.remove(propertyId);
  }
}

void main() {
  test('a rapid second tap cannot save the same apartment twice', () async {
    final authRepository = FakeAuthRepository()
      ..account = GuestAccount(id: 'guest', email: 'guest@example.test');
    final auth = AuthCubit(authRepository, currentTermsVersion: 'v1');
    final repository = _SlowFavorites();
    final favorites = FavoritesCubit(
      repository: repository,
      listings: FakeListingsRepository(),
      auth: auth,
    );
    addTearDown(authRepository.dispose);
    addTearDown(auth.close);
    addTearDown(favorites.close);
    await auth.restore();
    await Future<void>.delayed(Duration.zero);
    final card = ListingCard.fromJson(const {
      'id': 'property-1',
      'title': 'شقة',
      'property_type': 'apartment',
      'area_name': 'رأس البر',
      'city_name': 'دمياط',
      'nightly_price_minor': 150000,
    });

    final first = favorites.toggle(card);
    await favorites.toggle(card);
    expect(repository.addCalls, 1);
    repository.adding.complete();
    await first;
    expect(favorites.state.contains(card.id), isTrue);
    expect(favorites.state.cards.single.id, card.id);
  });

  test('saved apartments reload and clear from memory on sign-out', () async {
    final authRepository = FakeAuthRepository()
      ..account = GuestAccount(id: 'guest', email: 'guest@example.test');
    final auth = AuthCubit(authRepository, currentTermsVersion: 'v1');
    final repository = MemoryFavoritesRepository();
    await repository.add('guest', 'property-1');
    final favorites = FavoritesCubit(
      repository: repository,
      listings: FakeListingsRepository(),
      auth: auth,
    );
    addTearDown(authRepository.dispose);
    addTearDown(auth.close);
    addTearDown(favorites.close);

    await auth.restore();
    await Future<void>.delayed(Duration.zero);
    expect(favorites.state.contains('property-1'), isTrue);
    expect(favorites.state.cards.single.id, 'property-1');

    authRepository.account = null;
    await auth.restore();
    await Future<void>.delayed(Duration.zero);
    expect(favorites.state.userId, isNull);
    expect(favorites.state.ids, isEmpty);
    expect(favorites.state.cards, isEmpty);
  });
}
