import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/presentation/cash/cash_confirm_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

const _booking20 = 'b0000000-0000-4000-8000-000000000020';
const _booking28 = 'b0000000-0000-4000-8000-000000000028';

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

  CashConfirmCubit build(String id) => CashConfirmCubit(
    bookings: backend.server,
    stay: backend.stay,
    attempts: backend.actionAttempts,
    registry: BookingActionRegistry.g3(),
    connectivity: connectivityCubit,
    logger: AppLogger(sink: (_) {}),
    bookingId: id,
    now: () => DateTime.utc(2026, 11, 1, 10),
  );

  test('load for a confirmed booking with cash emits phone entry', () async {
    final cubit = build(_booking20);
    final states = <CashConfirmState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<CashLoading>());
    final entry = cubit.state as CashPhoneEntry;
    expect(entry.amount, Money(337500));
    expect(entry.phoneError, isFalse);
    await subscription.cancel();
    await cubit.close();
  });

  test('pending cash goes straight to the code step without sending', () async {
    final cubit = build(_booking28);
    await cubit.load();

    final entry = cubit.state as CashCodeEntry;
    expect(entry.request.collectorDisplayName, 'أحمد م.');
    expect(entry.resendAvailableAt, isNull);
    expect(backend.stay.codesSent, 0);
    await cubit.close();
  });

  test(
    'an invalid phone shows a field error with no repository call',
    () async {
      final cubit = build(_booking20);
      await cubit.load();

      await cubit.submitPhone('0100');

      final entry = cubit.state as CashPhoneEntry;
      expect(entry.phoneError, isTrue);
      expect(entry.amount, Money(337500));
      expect(backend.stay.lastCashStartKey, isNull);
      await cubit.close();
    },
  );

  test('an unauthorized collector is rejected before starting', () async {
    final cubit = build(_booking20);
    await cubit.load();

    await cubit.submitPhone('01099999999');

    expect(cubit.state, isA<CashNotAuthorized>());
    expect(backend.stay.codesSent, 0);
    await cubit.close();
  });

  test(
    'a valid phone starts, sends the code, and reaches the code step',
    () async {
      final cubit = build(_booking20);
      final states = <CashConfirmState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load();
      await cubit.submitPhone('01000000001');

      expect(
        states.whereType<CashStarting>().length,
        1,
        reason: 'starting state passed through',
      );
      final entry = cubit.state as CashCodeEntry;
      expect(entry.request.maskedEmail, 'g***@mock.onair.test');
      expect(entry.resendAvailableAt, isNull);
      expect(backend.stay.codesSent, 1);
      expect(backend.stay.lastExpectedAmount, Money(337500));
      await subscription.cancel();
      await cubit.close();
    },
  );

  test('a second submitPhone while starting does nothing', () async {
    final cubit = build(_booking20);
    await cubit.load();

    final first = cubit.submitPhone('01000000001');
    await cubit.submitPhone('01000000001');
    await first;

    expect(backend.stay.codesSent, 1);
    await cubit.close();
  });

  test('a wrong code returns to the code step with otpInvalid', () async {
    final cubit = build(_booking20);
    await cubit.load();
    await cubit.submitPhone('01000000001');

    await cubit.confirm('000000');

    final entry = cubit.state as CashCodeEntry;
    expect(entry.error?.code, ErrorCode.otpInvalid);
    expect(backend.stay.cashConfirms, 1);
    await cubit.close();
  });

  test('the right code confirms and emits done', () async {
    final cubit = build(_booking20);
    final states = <CashConfirmState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.load();
    await cubit.submitPhone('01000000001');
    await cubit.confirm('123456');

    expect(states.whereType<CashConfirming>().length, 1);
    final done = cubit.state as CashDone;
    expect(done.paymentId, isNotEmpty);
    await subscription.cancel();
    await cubit.close();
  });

  test('a rate-limited resend sets the resend wait', () async {
    final cubit = build(_booking20);
    await cubit.load();
    await cubit.submitPhone('01000000001');

    backend.stay.rateLimitNextSend = true;
    await cubit.resend();

    final entry = cubit.state as CashCodeEntry;
    expect(entry.resendAvailableAt, DateTime.utc(2026, 11, 1, 10, 0, 30));
    expect(backend.stay.codesSent, 1, reason: 'the rate-limited send counted');
    await cubit.close();
  });

  test('a changed amount reloads the booking and shows the new one', () async {
    final cubit = build(_booking20);
    await cubit.load();

    backend.stay.changeAmountOnce(_booking20);
    await cubit.submitPhone('01000000001');

    final entry = cubit.state as CashPhoneEntry;
    expect(entry.amount, Money(325000));
    expect(entry.error, isNull);
    await cubit.close();
  });

  test('a network error keeps the attempt key for the retry', () async {
    final cubit = build(_booking20);
    await cubit.load();

    backend.stay.failNextWithNetwork = true;
    await cubit.submitPhone('01000000001');
    final entry = cubit.state as CashPhoneEntry;
    expect(entry.error?.code, ErrorCode.network);
    // The attempt key survived the failure and is reused on the retry.
    final keptKey = await backend.actionAttempts.keyFor(
      'cash_start',
      _booking20,
    );

    await cubit.submitPhone('01000000001');
    expect(backend.stay.lastCashStartKey, keptKey);
    await cubit.close();
  });
}
