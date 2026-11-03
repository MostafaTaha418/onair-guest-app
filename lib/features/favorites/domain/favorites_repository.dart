abstract interface class FavoritesRepository {
  Future<List<String>> listPropertyIds(String userId);

  Future<void> add(String userId, String propertyId);

  Future<void> remove(String userId, String propertyId);
}
