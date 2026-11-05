import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/presentation/remaining_payment/remaining_payment_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

const _booking20 = 'b0000000-0000-4000-8000-000000000020';
const _booking23 = 'b0000000-0000-4000-8000-000000000023';

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late ConnectivityCubit connectivityCubit;

  setUp(() {
    backend = FakeBookingBackend(includeG3Fixtures: true);
    connectivity = FakeConnectivity();
    connectivityCubit = connectivity.createCubit();
  });

  tearDown(() async {
    await connectivityCubit.close();
    connectivity.dispose();
    backend.dispose();
  });

  RemainingPaymentCubit build(String id) => RemainingPaymentCubit(
    bookings: backend.server,
    registry: BookingActionRegistry.g3(),
    connectivity: connectivityCubit,
    bookingId: id,
  );

  test('load emits ready and exposes server cash action', () async {
    final cubit = build(_booking20);
    final states = <RemainingPaymentState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<RemainingLoading>());
    final ready = cubit.state as RemainingReady;
    expect(ready.details.id, _booking20);
    expect(ready.cashAllowed, isTrue);
    await subscription.cancel();
    await cubit.close();
  });

  test('booking without pay remaining is not allowed', () async {
    final cubit = build(_booking23);
    await cubit.load();
    expect(cubit.state, isA<RemainingNotAllowed>());
    await cubit.close();
  });

  test('pending remaining payment goes straight to verification', () async {
    final all = await backend.server.bookings;
    all[_booking20]!['pending_remaining_payment_id'] =
        'c0000000-0000-4000-8000-000000000099';
    final cubit = build(_booking20);

    await cubit.load();

    expect(cubit.state, isA<RemainingGoVerify>());
    expect((cubit.state as RemainingGoVerify).bookingId, _booking20);
    await cubit.close();
  });

  test('offline without cache emits offline', () async {
    connectivity.goOffline();
    await Future<void>.delayed(Duration.zero);
    final cubit = build(_booking20);

    await cubit.load();

    expect(cubit.state, isA<RemainingOffline>());
    await cubit.close();
  });

  test('unknown booking emits not available', () async {
    final cubit = build('b0000000-0000-4000-8000-000000000099');
    await cubit.load();
    expect(cubit.state, isA<RemainingNotAvailable>());
    await cubit.close();
  });
}
