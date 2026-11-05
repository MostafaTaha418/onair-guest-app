import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/features/stay/presentation/cancellation/cancellation_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

const _booking20 = 'b0000000-0000-4000-8000-000000000020';
const _booking21 = 'b0000000-0000-4000-8000-000000000021';
const _booking23 = 'b0000000-0000-4000-8000-000000000023';

void main() {
  late FakeBookingBackend backend;
  late FakeConnectivity connectivity;
  late ConnectivityCubit connectivityCubit;

  setUp(() {
    backend = FakeBookingBackend(
      includeG3Fixtures: true,
      actionRegistry: BookingActionRegistry.g3(),
    );
    connectivity = FakeConnectivity();
    connectivityCubit = connectivity.createCubit();
  });

  tearDown(() async {
    await connectivityCubit.close();
    connectivity.dispose();
    backend.dispose();
  });

  CancellationCubit build(String id) => CancellationCubit(
    stay: backend.stay,
    attempts: backend.actionAttempts,
    connectivity: connectivityCubit,
    logger: AppLogger(sink: (_) {}),
    bookingId: id,
  );

  test('load emits ready with the server preview', () async {
    final cubit = build(_booking23);
    final states = <CancellationState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<CancelLoading>());
    final ready = cubit.state as CancelReady;
    expect(ready.preview.refund, Money(450000));
    expect(ready.changes, PreviewChange.none);
    expect(ready.error, isNull);
    await subscription.cancel();
    await cubit.close();
  });

  test('reason and note are single-select and capped at 300', () async {
    final cubit = build(_booking23);
    await cubit.load();

    cubit
      ..selectReason(CancellationReason.other)
      ..setNote('x' * 301);

    final ready = cubit.state as CancelReady;
    expect(ready.reason, CancellationReason.other);
    expect(ready.note.length, 300);
    await cubit.close();
  });

  test('submit sends the previewed refund and the attempt key', () async {
    final cubit = build(_booking23);
    final states = <CancellationState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.load();

    final attemptKey = await backend.actionAttempts.keyFor(
      'cancel',
      _booking23,
    );
    await cubit.submit();

    expect(states.whereType<CancelSubmitting>().length, 1);
    expect(backend.stay.cancels, 1);
    expect(backend.stay.lastExpectedRefund, Money(450000));
    expect(backend.stay.lastCancelKey, attemptKey);
    expect(cubit.state, isA<CancelDone>());
    // The key is cleared after a successful command.
    final nextKey = await backend.actionAttempts.keyFor(
      'cancel',
      _booking23,
    );
    expect(nextKey, isNot(attemptKey));
    await subscription.cancel();
    await cubit.close();
  });

  test('a second submit while submitting does nothing', () async {
    final cubit = build(_booking23);
    await cubit.load();

    final first = cubit.submit();
    await cubit.submit();
    await first;

    expect(backend.stay.cancels, 1);
    await cubit.close();
  });

  test('changed terms re-preview and ask the guest again', () async {
    final cubit = build(_booking21);
    await cubit.load();
    final firstKey = await backend.actionAttempts.keyFor(
      'cancel',
      _booking21,
    );

    backend.stay.forceTermsChangeOnce(_booking21);
    await cubit.submit();

    expect(backend.stay.previews, 2);
    final ready = cubit.state as CancelReady;
    expect(ready.changes.refund, isTrue);
    expect(ready.preview.refund, Money(260000));
    expect(ready.previous!.refund, Money(270000));
    expect(ready.error?.code, ErrorCode.cancellationTermsChanged);
    final nextKey = await backend.actionAttempts.keyFor(
      'cancel',
      _booking21,
    );
    expect(nextKey, isNot(firstKey));
    await cubit.close();
  });

  test('a network error keeps the attempt key for the retry', () async {
    final cubit = build(_booking23);
    await cubit.load();

    backend.stay.failNextWithNetwork = true;
    await cubit.submit();
    final ready = cubit.state as CancelReady;
    expect(ready.error?.code, ErrorCode.network);
    final keptKey = await backend.actionAttempts.keyFor(
      'cancel',
      _booking23,
    );

    await cubit.submit();
    expect(backend.stay.lastCancelKey, keptKey);
    expect(cubit.state, isA<CancelDone>());
    await cubit.close();
  });

  test('a cancelled booking refuses a second cancellation', () async {
    final cubit = build(_booking20);
    await cubit.load();
    await cubit.submit();
    expect(cubit.state, isA<CancelDone>());

    await cubit.load();

    expect(cubit.state, isA<CancelNotAllowed>());
    await cubit.close();
  });

  test('offline load emits offline', () async {
    connectivity.goOffline();
    await Future<void>.delayed(Duration.zero);
    final cubit = build(_booking23);

    await cubit.load();

    expect(cubit.state, isA<CancelOffline>());
    await cubit.close();
  });
}
