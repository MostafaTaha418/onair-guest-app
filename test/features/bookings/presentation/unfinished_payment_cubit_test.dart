import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/booking/domain/payment_attempt.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/unfinished_payment_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';

const _property1f = '00000000-0000-4000-8000-00000000001f';

StayRange _threeNights() =>
    StayRange(DateOnly.parse('2026-11-20'), DateOnly.parse('2026-11-23'));

Future<String> _createPendingBooking(FakeBookingBackend backend) async {
  final quote = await backend.server.quote(
    propertyId: _property1f,
    stay: _threeNights(),
    guests: 2,
    termsHash: 'mock-terms-1',
  );
  final session = await backend.server.startPayment(
    quoteId: quote.quoteId,
    termsHash: quote.termsHash,
    attemptKey: 'attempt-key-1',
  );
  return session.bookingId;
}

/// A repository with scripted answers: the fixture server always carries a
/// `payment_pending` booking, so the «nothing pending» cases need their own
/// pending tab.
final class ScriptedBookings implements BookingsRepository {
  ScriptedBookings(this._server);

  final MockBookingServer _server;
  BookingsPage pendingPage = const BookingsPage(items: [], nextCursor: null);
  BookingDetails? bookingDetails;
  bool throwNotFound = false;

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) async =>
      tab == BookingTab.pending
      ? pendingPage
      : _server.listBookings(tab, cursor: cursor);

  @override
  Future<BookingDetails> getBooking(String bookingId) {
    if (throwNotFound) {
      throw const AppFailure(
        ApiError(code: ErrorCode.notFound, messageKey: 'NOT_FOUND'),
      );
    }
    return Future.value(bookingDetails!);
  }
}

PaymentAttempt _attempt(String bookingId) => PaymentAttempt(
  attemptKey: 'attempt-key-1',
  quoteId: 'q1',
  propertyId: _property1f,
  termsHash: 'mock-terms-1',
  startedAt: DateTime.utc(2026, 11, 1, 10),
  bookingId: bookingId,
);

void main() {
  late FakeBookingBackend backend;

  setUp(() {
    backend = FakeBookingBackend();
  });

  tearDown(() {
    backend.dispose();
  });

  test(
    'a payment_pending booking on the server becomes UnfinishedSome',
    () async {
      final bookingId = await _createPendingBooking(backend);
      final cubit = UnfinishedPaymentCubit(
        bookings: backend.server,
        attempts: backend.paymentAttempts,
      );
      await cubit.refresh();
      final state = cubit.state;
      expect(state, isA<UnfinishedSome>());
      expect((state as UnfinishedSome).booking.id, bookingId);
      await cubit.close();
    },
  );

  test('no pending booking stays UnfinishedNone', () async {
    final bookings = ScriptedBookings(backend.server);
    final cubit = UnfinishedPaymentCubit(
      bookings: bookings,
      attempts: backend.paymentAttempts,
    );
    await cubit.refresh();
    expect(cubit.state, isA<UnfinishedNone>());
    await cubit.close();
  });

  test(
    'a stored attempt whose booking is no longer pending and not verifying '
    'clears the store',
    () async {
      final bookingId = await _createPendingBooking(backend);
      await backend.paymentAttempts.save(_attempt(bookingId));
      // The server decided: the booking left the pending tab for good, and
      // the pending tab itself is empty now.
      await backend.server.completePayment(
        bookingId,
        MockPaymentResult.success,
      );
      final bookings = ScriptedBookings(backend.server)
        ..bookingDetails = await backend.server.getBooking(
          'b0000000-0000-4000-8000-000000000001',
        );
      final cubit = UnfinishedPaymentCubit(
        bookings: bookings,
        attempts: backend.paymentAttempts,
      );
      await cubit.refresh();
      expect(await backend.paymentAttempts.read(), isNull);
      expect(cubit.state, isA<UnfinishedNone>());
      await cubit.close();
    },
  );

  test('a stored attempt whose booking vanished clears the store', () async {
    final bookingId = await _createPendingBooking(backend);
    await backend.paymentAttempts.save(_attempt(bookingId));
    final bookings = ScriptedBookings(backend.server)..throwNotFound = true;
    final cubit = UnfinishedPaymentCubit(
      bookings: bookings,
      attempts: backend.paymentAttempts,
    );
    await cubit.refresh();
    expect(await backend.paymentAttempts.read(), isNull);
    await cubit.close();
  });

  test('a stored attempt whose booking is still pending is kept', () async {
    final bookingId = await _createPendingBooking(backend);
    await backend.paymentAttempts.save(_attempt(bookingId));
    final cubit = UnfinishedPaymentCubit(
      bookings: backend.server,
      attempts: backend.paymentAttempts,
    );
    await cubit.refresh();
    final stored = await backend.paymentAttempts.read();
    expect(stored, isNotNull);
    expect(stored!.bookingId, bookingId);
    expect(cubit.state, isA<UnfinishedSome>());
    await cubit.close();
  });

  test(
    'targetFor opens the verification screen for the attempt booking',
    () async {
      final bookingId = await _createPendingBooking(backend);
      await backend.paymentAttempts.save(_attempt(bookingId));
      final cubit = UnfinishedPaymentCubit(
        bookings: backend.server,
        attempts: backend.paymentAttempts,
      );
      await cubit.refresh();
      final booking = (cubit.state as UnfinishedSome).booking;
      expect(
        await cubit.targetFor(booking),
        '/payment/return?booking=$bookingId',
      );
      await cubit.close();
    },
  );

  test(
    'targetFor opens the details when the attempt is another booking',
    () async {
      final bookingId = await _createPendingBooking(backend);
      final cubit = UnfinishedPaymentCubit(
        bookings: backend.server,
        attempts: backend.paymentAttempts,
      );
      await cubit.refresh();
      final booking = (cubit.state as UnfinishedSome).booking;
      expect(await cubit.targetFor(booking), '/bookings/$bookingId');
      await cubit.close();
    },
  );

  test('sign-out resets to UnfinishedNone', () async {
    await _createPendingBooking(backend);
    final cubit = UnfinishedPaymentCubit(
      bookings: backend.server,
      attempts: backend.paymentAttempts,
    );
    await cubit.refresh();
    expect(cubit.state, isA<UnfinishedSome>());
    cubit.reset();
    expect(cubit.state, isA<UnfinishedNone>());
    await cubit.close();
  });
}
