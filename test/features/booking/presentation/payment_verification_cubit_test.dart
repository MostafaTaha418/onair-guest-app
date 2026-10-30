import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_mapper.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/verification_outcome.dart';
import 'package:on_air/features/booking/presentation/payment_verification_cubit.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';

import '../../../helpers/fake_booking_backend.dart';

/// Counts `getBooking` calls and can answer with a fixed error.
final class CountingBookingsRepository implements BookingsRepository {
  CountingBookingsRepository(this._inner);

  final BookingsRepository _inner;
  int calls = 0;
  String? nextError;

  @override
  Future<BookingDetails> getBooking(String bookingId) async {
    calls++;
    final error = nextError;
    if (error != null) {
      throw AppFailure(ErrorMapper.fromCode(error));
    }
    return _inner.getBooking(bookingId);
  }

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) =>
      _inner.listBookings(tab, cursor: cursor);
}

void main() {
  late FakeBookingBackend backend;

  setUp(() {
    backend = FakeBookingBackend();
  });

  tearDown(() => backend.dispose());

  /// Warms the fixture cache outside fakeAsync: async file IO never
  /// completes under the fake zone.
  Future<String> createSilentBooking() async {
    final quote = await backend.server.quote(
      propertyId: '00000000-0000-4000-8000-00000000001f',
      stay: _threeNights(),
      guests: 2,
      termsHash: 'mock-terms-1',
    );
    final session = await backend.server.startPayment(
      quoteId: quote.quoteId,
      termsHash: 'mock-terms-1',
      attemptKey: 'attempt-verification-1'.padRight(36, '0'),
    );
    await backend.server.completePayment(
      session.bookingId,
      MockPaymentResult.silent,
    );
    return session.bookingId;
  }

  test('polls with backoff and times out after 120 s', () {
    fakeAsync((async) {
      var bookingId = '';
      // The fixtures are already in memory; only microtasks run here.
      unawaited(createSilentBooking().then((id) => bookingId = id));
      async.flushMicrotasks();

      final bookings = CountingBookingsRepository(backend.server);
      final cubit = PaymentVerificationCubit(
        bookings: bookings,
        signals: backend.signals,
        bookingId: bookingId,
        logger: AppLogger(sink: (_) {}),
      );
      // The fakeAsync zone interleaves calls with microtask flushes on
      // different receivers, which the cascade lint cannot see past the
      // local declarations.
      // ignore: cascade_invocations
      cubit.start();
      async.flushMicrotasks();
      expect(cubit.state, isA<VerifyWaiting>());
      expect(bookings.calls, 1);

      async
        ..elapse(const Duration(seconds: 2))
        ..flushMicrotasks();
      expect(bookings.calls, 2, reason: 'backoff 2 s');

      async
        ..elapse(const Duration(seconds: 4))
        ..flushMicrotasks();
      expect(bookings.calls, 3, reason: 'backoff 4 s');

      async
        ..elapse(const Duration(seconds: 8))
        ..flushMicrotasks();
      expect(bookings.calls, 4, reason: 'backoff 8 s');

      async
        ..elapse(const Duration(seconds: 16))
        ..flushMicrotasks();
      expect(bookings.calls, 5, reason: 'backoff 16 s');

      async
        ..elapse(const Duration(seconds: 30))
        ..flushMicrotasks();
      expect(bookings.calls, 6, reason: 'backoff 30 s');

      async
        ..elapse(const Duration(seconds: 30))
        ..flushMicrotasks();
      expect(bookings.calls, 7, reason: 'backoff 30 s');

      async
        ..elapse(const Duration(seconds: 30))
        ..flushMicrotasks();
      expect(bookings.calls, 8, reason: 'backoff 30 s');
      expect(cubit.state, isA<VerifyTimeout>());

      async
        ..elapse(const Duration(seconds: 60))
        ..flushMicrotasks();
      expect(bookings.calls, 8, reason: 'no fetch after the timeout');
      unawaited(cubit.close());
    });
  });

  test('a signal for this booking fetches at once and resolves', () async {
    // Real async: the signal must resolve long before the first poll.
    var bookingId = '';
    bookingId = await createSilentBooking();
    final bookings = CountingBookingsRepository(backend.server);
    final cubit = PaymentVerificationCubit(
      bookings: bookings,
      signals: backend.signals,
      bookingId: bookingId,
      logger: AppLogger(sink: (_) {}),
    );
    // The fakeAsync-style pairing of a call with its await does not
    // cascade: the receivers differ.
    // ignore: cascade_invocations
    cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<VerifyWaiting>());

    unawaited(backend.signals.start('guest'));
    backend.server.setStatus(bookingId, 'awaiting_owner');
    backend.signals.emit(
      NotificationSignal(
        id: 'n1',
        typeKey: 'booking.request_received',
        entityType: 'booking',
        entityId: bookingId,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bookings.calls, 2, reason: 'the signal triggered the fetch');
    expect(cubit.state, isA<VerifyResolved>());
    final resolved = cubit.state as VerifyResolved;
    expect(resolved.outcome, VerificationOutcome.success);
    await cubit.close();
  });

  test('a signal for another booking does not trigger a fetch', () {
    fakeAsync((async) {
      var bookingId = '';
      unawaited(createSilentBooking().then((id) => bookingId = id));
      async.flushMicrotasks();

      final bookings = CountingBookingsRepository(backend.server);
      final cubit = PaymentVerificationCubit(
        bookings: bookings,
        signals: backend.signals,
        bookingId: bookingId,
        logger: AppLogger(sink: (_) {}),
      );
      // The fakeAsync zone interleaves calls with microtask flushes on
      // different receivers, which the cascade lint cannot see past the
      // local declarations.
      // ignore: cascade_invocations
      cubit.start();
      async.flushMicrotasks();

      backend.signals.emit(
        const NotificationSignal(
          id: 'n2',
          typeKey: 'booking.confirmed',
          entityType: 'booking',
          entityId: 'b0000000-0000-4000-8000-0000000000aa',
        ),
      );
      async.flushMicrotasks();
      expect(bookings.calls, 1);
      expect(cubit.state, isA<VerifyWaiting>());
      unawaited(cubit.close());
    });
  });

  test('NOT_FOUND is not available, network errors keep waiting', () async {
    // Real async: the outcome lands well before the (long) first poll.
    final bookingId = await createSilentBooking();
    final notFound = CountingBookingsRepository(backend.server)
      ..nextError = 'NOT_FOUND';
    final cubit = PaymentVerificationCubit(
      bookings: notFound,
      signals: backend.signals,
      bookingId: bookingId,
      logger: AppLogger(sink: (_) {}),
      backoff: const [Duration(hours: 1)],
    );
    // The fakeAsync-style pairing of a call with its await does not
    // cascade: the receivers differ.
    // ignore: cascade_invocations
    cubit.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state, isA<VerifyNotAvailable>());
    await cubit.close();

    final failing = CountingBookingsRepository(backend.server)
      ..nextError = 'INTERNAL';
    final cubit2 = PaymentVerificationCubit(
      bookings: failing,
      signals: backend.signals,
      bookingId: bookingId,
      logger: AppLogger(sink: (_) {}),
      backoff: const [Duration(hours: 1)],
    );
    // The fakeAsync-style pairing of a call with its await does not
    // cascade: the receivers differ.
    // ignore: cascade_invocations
    cubit2.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit2.state, isA<VerifyWaiting>());
    await cubit2.close();
  });

  test('close cancels the pending timer', () {
    fakeAsync((async) {
      var bookingId = '';
      unawaited(createSilentBooking().then((id) => bookingId = id));
      async.flushMicrotasks();

      final bookings = CountingBookingsRepository(backend.server);
      final cubit = PaymentVerificationCubit(
        bookings: bookings,
        signals: backend.signals,
        bookingId: bookingId,
        logger: AppLogger(sink: (_) {}),
      );
      // The fakeAsync zone interleaves calls with microtask flushes on
      // different receivers, which the cascade lint cannot see past the
      // local declarations.
      // ignore: cascade_invocations
      cubit.start();
      async.flushMicrotasks();
      unawaited(cubit.close());
      async
        ..elapse(const Duration(seconds: 10))
        ..flushMicrotasks();
      expect(bookings.calls, 1);
    });
  });
}

StayRange _threeNights() =>
    StayRange(DateOnly.parse('2026-11-20'), DateOnly.parse('2026-11-23'));
