import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/bookings/data/mock_booking_server.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/listings/data/mock_listings_repository.dart';

final _clockStart = DateTime.utc(2026, 11, 1, 10);
const _property1f = '00000000-0000-4000-8000-00000000001f';

StayRange _threeNights() =>
    StayRange(DateOnly.parse('2026-11-20'), DateOnly.parse('2026-11-23'));

MockBookingServer _server({
  required ControllableNotificationSignalSource signals,
}) => MockBookingServer(
  listings: MockListingsRepository(
    loader: (path) => File(path).readAsString(),
    latency: Duration.zero,
  ),
  signals: signals,
  loader: (path) => File(path).readAsString(),
  latency: Duration.zero,
  now: () => _clockStart,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tabs hold the right bookings in server order', () async {
    final signals = ControllableNotificationSignalSource();
    final server = _server(signals: signals);

    final current = await server.listBookings(BookingTab.current);
    expect(
      current.items.map((item) => item.id.substring(item.id.length - 2)),
      ['04', '02', '01', '03'],
    );
    expect(current.nextCursor, isNull);

    final past = await server.listBookings(BookingTab.past);
    expect(
      past.items.map((item) => item.id.substring(item.id.length - 2)),
      ['05', '13'],
    );

    final cancelled = await server.listBookings(BookingTab.cancelled);
    expect(
      cancelled.items.map((item) => item.id.substring(item.id.length - 2)),
      ['10', '09', '08', '07', '06'],
    );

    final pending = await server.listBookings(BookingTab.pending);
    expect(
      pending.items.map((item) => item.id.substring(item.id.length - 2)),
      ['11'],
    );

    final everyTab = [
      ...current.items,
      ...past.items,
      ...cancelled.items,
      ...pending.items,
    ];
    expect(
      everyTab.every((item) => item.status != BookingStatus.abandoned),
      isTrue,
    );
  });

  test('an unknown booking id is NOT_FOUND', () async {
    final signals = ControllableNotificationSignalSource();
    final server = _server(signals: signals);
    await expectLater(
      server.getBooking('b0000000-0000-4000-8000-0000000000ff'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.error.code,
          'code',
          ErrorCode.notFound,
        ),
      ),
    );
  });

  test('quote computes the deposit by the policy', () async {
    final signals = ControllableNotificationSignalSource();
    final server = _server(signals: signals);
    final quote = await server.quote(
      propertyId: _property1f,
      stay: _threeNights(),
      guests: 2,
      termsHash: 'mock-terms-1',
    );
    expect(quote.nights, 3);
    expect(quote.total, Money(450000));
    expect(quote.payNow, Money(112500));
    expect(quote.remaining, Money(337500));
    expect(quote.expiresAt, _clockStart.add(const Duration(minutes: 15)));
  });

  test('quote refuses changed terms and too many guests', () async {
    final signals = ControllableNotificationSignalSource();
    final server = _server(signals: signals);
    await expectLater(
      server.quote(
        propertyId: _property1f,
        stay: _threeNights(),
        guests: 2,
        termsHash: 'old',
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.error.code,
          'code',
          ErrorCode.termsChanged,
        ),
      ),
    );
    await expectLater(
      server.quote(
        propertyId: _property1f,
        stay: _threeNights(),
        guests: 99,
        termsHash: 'mock-terms-1',
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.error.code,
          'code',
          ErrorCode.guestsExceeded,
        ),
      ),
    );
  });

  test('the same attempt key reuses one session', () async {
    final signals = ControllableNotificationSignalSource();
    final server = _server(signals: signals);
    const key = '11111111-2222-4333-8444-555555555555';
    final quote = await server.quote(
      propertyId: _property1f,
      stay: _threeNights(),
      guests: 2,
      termsHash: 'mock-terms-1',
    );
    final first = await server.startPayment(
      quoteId: quote.quoteId,
      termsHash: 'mock-terms-1',
      attemptKey: key,
    );
    final second = await server.startPayment(
      quoteId: quote.quoteId,
      termsHash: 'mock-terms-1',
      attemptKey: key,
    );
    expect(second.bookingId, first.bookingId);
    expect(server.sessionCount(key), 1);

    await expectLater(
      server.startPayment(
        quoteId: quote.quoteId,
        termsHash: 'mock-terms-1',
        attemptKey: '99999999-8888-4777-8666-555555555555',
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.error.code,
          'code',
          ErrorCode.quoteExpired,
        ),
      ),
    );
  });

  Future<(MockBookingServer, List<String>, String)> paidBooking(
    MockPaymentResult result,
  ) async {
    final signals = ControllableNotificationSignalSource();
    final server = _server(signals: signals);
    await signals.start('guest');
    final quote = await server.quote(
      propertyId: _property1f,
      stay: _threeNights(),
      guests: 2,
      termsHash: 'mock-terms-1',
    );
    final session = await server.startPayment(
      quoteId: quote.quoteId,
      termsHash: 'mock-terms-1',
      attemptKey: '11111111-2222-4333-8444-555555555555',
    );
    final received = <NotificationSignal>[];
    final subscription = signals.signals.listen(received.add);
    addTearDown(subscription.cancel);
    await server.completePayment(session.bookingId, result);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return (server, [for (final s in received) s.typeKey], session.bookingId);
  }

  test('a successful payment becomes awaiting_owner with a signal', () async {
    final (server, types, bookingId) = await paidBooking(
      MockPaymentResult.success,
    );
    final details = await server.getBooking(bookingId);
    expect(details.status, BookingStatus.awaitingOwner);
    expect(details.paymentState, PaymentState.succeeded);
    expect(
      details.ownerResponseDeadline,
      _clockStart.add(const Duration(hours: 24)),
    );
    expect(types, ['booking.request_received']);
  });

  test('a failed payment stays pending with the failed signal', () async {
    final (server, types, bookingId) = await paidBooking(
      MockPaymentResult.failure,
    );
    final details = await server.getBooking(bookingId);
    expect(details.status, BookingStatus.paymentPending);
    expect(details.paymentState, PaymentState.failed);
    expect(types, ['payment.failed']);
  });

  test('a conflict payment opens a refund and sends its signal', () async {
    final (server, types, bookingId) = await paidBooking(
      MockPaymentResult.conflict,
    );
    final details = await server.getBooking(bookingId);
    expect(details.status, BookingStatus.paymentConflict);
    expect(details.refund, isNotNull);
    expect(details.refund!.stage, RefundStage.requested);
    expect(types, ['booking.payment_conflict']);
  });

  test('a silent payment stays verifying with no signal', () async {
    final (server, types, bookingId) = await paidBooking(
      MockPaymentResult.silent,
    );
    final details = await server.getBooking(bookingId);
    expect(details.status, BookingStatus.paymentVerifying);
    expect(types, isEmpty);
  });
}
