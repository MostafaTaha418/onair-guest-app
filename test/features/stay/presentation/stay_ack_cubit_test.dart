import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/presentation/stay_ack/stay_ack_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';

const _booking20 = 'b0000000-0000-4000-8000-000000000020';
const _booking21 = 'b0000000-0000-4000-8000-000000000021';
const _booking22 = 'b0000000-0000-4000-8000-000000000022';

void main() {
  late FakeBookingBackend backend;

  setUp(() {
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );
  });

  tearDown(() {
    backend.dispose();
  });

  StayAckCubit build(String id) => StayAckCubit(
    stay: backend.stay,
    logger: AppLogger(sink: (_) {}),
    bookingId: id,
  );

  test('confirmCheckIn records the guest acknowledgement', () async {
    final cubit = build(_booking21);
    final states = <StayAckState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.confirmCheckIn();

    expect(states.first, isA<AckSubmitting>());
    final done = cubit.state as AckDone;
    expect(done.newStatus, 'confirmed');
    final all = await backend.server.bookings;
    final booking = all[_booking21]!;
    final acknowledgements = booking['acknowledgements'] as Map;
    expect(acknowledgements['guest_checkin_at'], isNotNull);
    expect(backend.stay.checkIns, 1);
    await subscription.cancel();
    await cubit.close();
  });

  test('a second call while submitting does nothing', () async {
    final cubit = build(_booking21);

    final first = cubit.confirmCheckIn();
    await cubit.confirmCheckIn();
    await first;

    expect(backend.stay.checkIns, 1);
    await cubit.close();
  });

  test('confirming check-in with an unpaid remaining fails', () async {
    final cubit = build(_booking20);

    await cubit.confirmCheckIn();

    final failed = cubit.state as AckFailed;
    expect(failed.error.code, ErrorCode.remainingNotPaid);
    expect(backend.stay.checkIns, 1);
    await cubit.close();
  });

  test('confirmCheckOut records the guest checkout', () async {
    final cubit = build(_booking22);

    await cubit.confirmCheckOut();

    final done = cubit.state as AckDone;
    expect(done.newStatus, 'checked_in');
    final all = await backend.server.bookings;
    final acknowledgements = all[_booking22]!['acknowledgements'] as Map;
    expect(acknowledgements['guest_checkout_at'], isNotNull);
    expect(backend.stay.checkOuts, 1);
    await cubit.close();
  });

  test('a network failure keeps the cubit usable for a retry', () async {
    final cubit = build(_booking21);

    backend.stay.failNextWithNetwork = true;
    await cubit.confirmCheckIn();
    expect((cubit.state as AckFailed).error.code, ErrorCode.network);

    await cubit.confirmCheckIn();
    expect(cubit.state, isA<AckDone>());
    // The failed attempt never reached the mock's counter.
    expect(backend.stay.checkIns, 1);
    await cubit.close();
  });
}
