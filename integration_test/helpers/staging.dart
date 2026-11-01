import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/api/generated/fallback/fallback_client.dart';
import 'package:on_air/core/env/env_config.dart';
import 'package:on_air/core/network/dio_factory.dart';
import 'package:on_air/core/network/supabase_token_source.dart';
import 'package:on_air/features/booking/data/supabase_booking_flow_repository.dart';
import 'package:on_air/features/booking/domain/booking_flow_repository.dart';
import 'package:on_air/features/bookings/data/supabase_bookings_repository.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/listings/data/supabase_listings_repository.dart';
import 'package:on_air/features/listings/domain/listings_repository.dart';
import 'package:on_air/features/notifications/data/supabase_notifications_repository.dart';
import 'package:on_air/features/notifications/domain/notifications_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared setup for the Staging booking tests (T102–T104). Every test skips
/// with the required message unless it runs in remote mode against the
/// Staging seed: mock mode has no Kashier, and the seed ids come from
/// dart-defines carried in the seed configuration.
bool skipUnlessStaging() {
  const mode = String.fromEnvironment('BACKEND_MODE');
  if (mode != 'remote' || !const bool.fromEnvironment('KASHIER_TEST')) {
    markTestSkipped('remote mode + Kashier test account required');
    return false;
  }
  for (final key in <String>[
    'GUEST_EMAIL',
    'GUEST_PASSWORD',
    'DEPOSIT_PROPERTY',
    'BOOKING_CONFIRMED',
    'BOOKING_REJECTED',
    'BOOKING_EXPIRED',
    'BOOKING_CONFLICT',
    'BOOKING_REFUND_REQUESTED',
    'BOOKING_REFUND_VERIFIED',
    'FOREIGN_BOOKING',
  ]) {
    if (seedValue(key).isEmpty) return false;
  }
  return true;
}

/// One dart-define seed; empty means the Staging seed does not carry it yet.
String seedValue(String key) {
  final value = switch (key) {
    'GUEST_EMAIL' => const String.fromEnvironment('SEED_GUEST_EMAIL'),
    'GUEST_PASSWORD' => const String.fromEnvironment('SEED_GUEST_PASSWORD'),
    'DEPOSIT_PROPERTY' => const String.fromEnvironment(
      'SEED_PROPERTY_DEPOSIT_ID',
    ),
    'BOOKING_CONFIRMED' => const String.fromEnvironment(
      'SEED_BOOKING_CONFIRMED_ID',
    ),
    'BOOKING_REJECTED' => const String.fromEnvironment(
      'SEED_BOOKING_REJECTED_ID',
    ),
    'BOOKING_EXPIRED' => const String.fromEnvironment(
      'SEED_BOOKING_EXPIRED_ID',
    ),
    'BOOKING_CONFLICT' => const String.fromEnvironment(
      'SEED_BOOKING_CONFLICT_ID',
    ),
    'BOOKING_REFUND_REQUESTED' => const String.fromEnvironment(
      'SEED_BOOKING_REFUND_REQUESTED_ID',
    ),
    'BOOKING_REFUND_VERIFIED' => const String.fromEnvironment(
      'SEED_BOOKING_REFUND_VERIFIED_ID',
    ),
    'FOREIGN_BOOKING' => const String.fromEnvironment(
      'SEED_BOOKING_FOREIGN_ID',
    ),
    _ => '',
  };
  if (value.isEmpty) {
    markTestSkipped('Staging seed value $key is not set');
  }
  return value;
}

/// The repositories on the live Staging backend, after signing the seeded
/// guest in with password auth.
Future<StagingHarness> bootStaging() async {
  final environment = EnvConfig.fromEnvironment();
  await Supabase.initialize(
    url: environment.supabaseUrl,
    publishableKey: environment.supabaseAnonKey,
  );
  final client = Supabase.instance.client;
  await client.auth.signInWithPassword(
    email: seedValue('GUEST_EMAIL'),
    password: seedValue('GUEST_PASSWORD'),
  );
  Future<dynamic> rpc(String fn, Map<String, dynamic> params) =>
      client.rpc<dynamic>(fn, params: params);
  final dio = createNodeDio(
    baseUrl: environment.nodeApiBaseUrl,
    tokens: SupabaseTokenSource(client),
  );
  return StagingHarness(
    listings: SupabaseListingsRepository(rpc: rpc),
    bookings: SupabaseBookingsRepository(rpc: rpc),
    flow: SupabaseBookingFlowRepository(rpc: rpc, node: FallbackClient(dio)),
    notifications: SupabaseNotificationsRepository(rpc: rpc),
  );
}

final class StagingHarness {
  const StagingHarness({
    required this.listings,
    required this.bookings,
    required this.flow,
    required this.notifications,
  });

  final ListingsRepository listings;
  final BookingsRepository bookings;
  final BookingFlowRepository flow;
  final NotificationsRepository notifications;
}
