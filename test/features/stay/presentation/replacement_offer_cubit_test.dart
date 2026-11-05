import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/stay/presentation/offer/replacement_offer_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';

const _offer1 = 'f0000000-0000-4000-8000-000000000001';
const _offer2 = 'f0000000-0000-4000-8000-000000000002';

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

  ReplacementOfferCubit build(String offerId) => ReplacementOfferCubit(
    stay: backend.stay,
    attempts: backend.actionAttempts,
    logger: AppLogger(sink: (_) {}),
    offerId: offerId,
  );

  test('accept submits then answers with the attempt key', () async {
    final cubit = build(_offer1);
    final states = <ReplacementOfferState>[];
    final subscription = cubit.stream.listen(states.add);

    final attemptKey = await backend.actionAttempts.keyFor(
      'offer_answer',
      _offer1,
    );
    await cubit.accept();

    expect(states.whereType<OfferSubmitting>().single.accept, isTrue);
    final answered = cubit.state as OfferAnswered;
    expect(answered.accepted, isTrue);
    expect(backend.stay.offerAnswers, 1);
    // The key is cleared after the successful answer.
    final nextKey = await backend.actionAttempts.keyFor(
      'offer_answer',
      _offer1,
    );
    expect(nextKey, isNot(attemptKey));
    await subscription.cancel();
    await cubit.close();
  });

  test('decline answers with accepted: false', () async {
    final cubit = build(_offer1);

    await cubit.decline();

    expect((cubit.state as OfferAnswered).accepted, isFalse);
    expect(backend.stay.offerAnswers, 1);
    await cubit.close();
  });

  test('an expired offer is gone', () async {
    final cubit = build(_offer2);

    await cubit.accept();

    expect(cubit.state, isA<OfferGone>());
    await cubit.close();
  });

  test('a double tap makes one call', () async {
    final cubit = build(_offer1);

    final first = cubit.accept();
    await cubit.accept();
    await first;

    expect(backend.stay.offerAnswers, 1);
    await cubit.close();
  });

  test('a network error keeps the key and returns to idle', () async {
    final cubit = build(_offer1);

    backend.stay.failNextWithNetwork = true;
    await cubit.accept();

    final idle = cubit.state as OfferIdle;
    expect(idle.error?.code, ErrorCode.network);
    // The key survives for the retry.
    final keptKey = await backend.actionAttempts.keyFor(
      'offer_answer',
      _offer1,
    );
    await cubit.accept();
    expect(backend.stay.offerAnswers, 1);
    expect(cubit.state, isA<OfferAnswered>());
    expect(
      await backend.actionAttempts.keyFor('offer_answer', _offer1),
      isNot(keptKey),
    );
    await cubit.close();
  });
}
