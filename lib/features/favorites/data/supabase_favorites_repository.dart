import 'package:on_air/features/favorites/domain/favorites_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The table's RLS policies also restrict every operation to auth.uid().
final class SupabaseFavoritesRepository implements FavoritesRepository {
  const SupabaseFavoritesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<String>> listPropertyIds(String userId) async {
    final rows = await _client
        .from('favorites')
        .select('property_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return [for (final row in rows) row['property_id'] as String];
  }

  @override
  Future<void> add(String userId, String propertyId) async {
    await _client
        .from('favorites')
        .upsert(
          {
            'user_id': userId,
            'property_id': propertyId,
          },
          onConflict: 'user_id,property_id',
          ignoreDuplicates: true,
        );
  }

  @override
  Future<void> remove(String userId, String propertyId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('property_id', propertyId);
  }
}
