import 'package:on_air/core/network/dio_factory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseTokenSource implements SessionTokenSource {
  const SupabaseTokenSource(this.client);
  final SupabaseClient client;
  @override
  Future<String?> currentToken() async =>
      client.auth.currentSession?.accessToken;
  @override
  Future<String?> refreshToken() async =>
      (await client.auth.refreshSession()).session?.accessToken;
}
