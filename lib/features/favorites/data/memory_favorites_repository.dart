import 'package:on_air/features/favorites/domain/favorites_repository.dart';

/// Used by the offline mock backend and widget harnesses.
final class MemoryFavoritesRepository implements FavoritesRepository {
  final Map<String, List<String>> _idsByUser = {};

  @override
  Future<List<String>> listPropertyIds(String userId) async =>
      List.of(_idsByUser[userId] ?? const []);

  @override
  Future<void> add(String userId, String propertyId) async {
    _idsByUser.putIfAbsent(userId, () => [])
      ..remove(propertyId)
      ..insert(0, propertyId);
  }

  @override
  Future<void> remove(String userId, String propertyId) async {
    _idsByUser[userId]?.remove(propertyId);
  }
}
