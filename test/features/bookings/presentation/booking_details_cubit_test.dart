import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/realtime/notification_signal.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/domain/bookings_repository.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

/// Delegates to the mock server but counts getBooking fetches.
final class RecordingBookings implements BookingsRepository {
  RecordingBookings(this._inner);

  final BookingsRepository _inner;
  int getBookingCalls = 0;

  @override
  Future<BookingsPage> listBookings(BookingTab tab, {String? cursor}) =>
      _inner.listBookings(tab, cursor: cursor);

  @override
  Future<BookingDetails> getBooking(String bookingId) async {
    getBookingCalls++;
    return _inner.getBooking(bookingId);
  }
}

const _confirmedId = 'b0000000-0000-4000-8000-000000000001';
const _instructionsText = 'المفتاح مع حارس العمارة. اطلب منه باسم الحجز.';

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;

  setUp(() {
    backend = FakeBookingBackend();
    connectivity = FakeConnectivity();
  });

  tearDown(() {
    backend.dispose();
    connectivity.dispose();
  });

  BookingDetailsCubit buildCubit({
    String bookingId = _confirmedId,
    BookingsRepository? bookings,
    ConnectivityCubit? connectivityCubit,
  }) => BookingDetailsCubit(
    bookings: bookings ?? backend.server,
    cache: backend.cache,
    arrival: backend.arrivalInstructions,
    signals: backend.signals,
    connectivity: connectivityCubit ?? connectivity.createCubit(),
    bookingId: bookingId,
  );

  test(
    'a confirmed booking keeps its instructions in the store, never in the cache',
    () async {
      final cubit = buildCubit();
      await cubit.load();
      final state = cubit.state;
      expect(state, isA<DetailsReady>());
      final ready = state as DetailsReady;
      expect(ready.instructions, _instructionsText);
      expect(ready.details.accessInstructions, isNull);
      expect(ready.fromCache, isFalse);
      expect(
        await backend.arrivalInstructions.read(_confirmedId),
        _instructionsText,
      );
      final cached = await backend.cache.readDetails(_confirmedId);
      expect(cached!.details.accessInstructions, isNull);
      await cubit.close();
    },
  );

  test(
    'a terminal status removes the stored instructions on refresh',
    () async {
      final cubit = buildCubit();
      await cubit.load();
      expect(await backend.arrivalInstructions.read(_confirmedId), isNotNull);

      backend.server.setStatus(_confirmedId, 'cancelled');
      await cubit.refresh();
      final state = cubit.state as DetailsReady;
      expect(state.instructions, isNull);
      expect(await backend.arrivalInstructions.read(_confirmedId), isNull);
      await cubit.close();
    },
  );

  test(
    'offline with a cached copy shows it and the stored instructions',
    () async {
      // One connectivity cubit shared by both: a broadcast flip is never
      // replayed to a later subscriber.
      final conn = connectivity.createCubit();
      final onlineCubit = buildCubit(connectivityCubit: conn);
      await onlineCubit.load();
      await onlineCubit.close();

      connectivity.goOffline();
      await _flush();

      final offlineCubit = buildCubit(connectivityCubit: conn);
      final emissions = <BookingDetailsState>[];
      final subscription = offlineCubit.stream.listen(emissions.add);
      await offlineCubit.load();
      await _flush(); // stream events are delivered asynchronously
      await subscription.cancel();

      final ready = emissions.whereType<DetailsReady>().single;
      expect(ready.fromCache, isTrue);
      expect(ready.instructions, _instructionsText);
      expect(ready.details.id, _confirmedId);
      await offlineCubit.close();
    },
  );

  test('an unknown booking is not available', () async {
    final cubit = buildCubit(bookingId: 'b0000000-0000-4000-8000-0000000000ff');
    await cubit.load();
    expect(cubit.state, isA<DetailsNotAvailable>());
    await cubit.close();
  });

  test('a signal for this booking refreshes; a foreign one does not', () async {
    final recording = RecordingBookings(backend.server);
    final cubit = buildCubit(bookings: recording);
    await cubit.load();
    final before = recording.getBookingCalls;
    expect(before, 1);

    await backend.signals.start('guest');
    backend.signals.emit(
      const NotificationSignal(
        id: 'n1',
        typeKey: 'booking.confirmed',
        entityType: 'booking',
        entityId: _confirmedId,
      ),
    );
    await _flush();
    expect(recording.getBookingCalls, before + 1);

    backend.signals.emit(
      const NotificationSignal(
        id: 'n2',
        typeKey: 'booking.confirmed',
        entityType: 'booking',
        entityId: 'b0000000-0000-4000-8000-000000000002',
      ),
    );
    await _flush();
    expect(recording.getBookingCalls, before + 1);
    await cubit.close();
    await backend.signals.stop();
  });
}
