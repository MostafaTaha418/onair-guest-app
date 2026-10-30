import 'dart:io';

import 'package:on_air/core/cache/json_file_cache.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/storage/secure_store.dart';
import 'package:on_air/features/booking/data/payment_attempt_store.dart';
import 'package:on_air/features/bookings/data/arrival_instructions_store.dart';
import 'package:on_air/features/bookings/data/bookings_cache.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';

/// The whole mock backend for booking tests: a [MockBookingServer] over the
/// real JSON fixtures on disk, a controllable signal source, and the three
/// local stores, all deterministic (fixed clock, zero latency).
final class FakeBookingBackend {
  FakeBookingBackend({bool startVerified = true}) {
    listings = MockListingsRepository(
      loader: (path) => File(path).readAsString(),
      latency: Duration.zero,
    );
    signals = ControllableNotificationSignalSource();
    server = MockBookingServer(
      listings: listings,
      signals: signals,
      loader: (path) => File(path).readAsString(),
      latency: Duration.zero,
      now: () => DateTime.utc(2026, 11, 1, 10),
      startVerified: startVerified,
    );
    secureStore = InMemorySecureStore();
    paymentAttempts = PaymentAttemptStore(secureStore);
    arrivalInstructions = ArrivalInstructionsStore(secureStore);
    _tempDirectory = Directory.systemTemp.createTempSync('on_air_g2_test');
    cache = BookingsCache(
      JsonFileCache(
        directory: _tempDirectory,
        fileName: 'bookings_cache.json',
        schema: 1,
      ),
    );
  }

  late final MockListingsRepository listings;
  late final ControllableNotificationSignalSource signals;
  late final MockBookingServer server;
  late final InMemorySecureStore secureStore;
  late final PaymentAttemptStore paymentAttempts;
  late final ArrivalInstructionsStore arrivalInstructions;
  late final BookingsCache cache;
  late final Directory _tempDirectory;

  /// Widget tests must remove the temp directory themselves.
  void dispose() {
    if (_tempDirectory.existsSync()) {
      _tempDirectory.deleteSync(recursive: true);
    }
  }
}
