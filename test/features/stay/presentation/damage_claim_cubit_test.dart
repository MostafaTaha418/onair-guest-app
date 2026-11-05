import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/logging/app_logger.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_cubit.dart';

import '../../../helpers/fake_booking_backend.dart';
import '../../../helpers/fake_connectivity.dart';

const _booking25 = 'b0000000-0000-4000-8000-000000000025';
const _booking21 = 'b0000000-0000-4000-8000-000000000021';
const _claim1 = 'e0000000-0000-4000-8000-000000000001';
const _claim2 = 'e0000000-0000-4000-8000-000000000002';

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

  DamageClaimCubit build({
    required String bookingId,
    required String claimId,
  }) => DamageClaimCubit(
    stay: backend.stay,
    bookings: backend.server,
    attempts: backend.actionAttempts,
    registry: BookingActionRegistry.g3(),
    connectivity: connectivityCubit,
    logger: AppLogger(sink: (_) {}),
    bookingId: bookingId,
    claimId: claimId,
  );

  test('load emits ready with evidence and a respondable claim', () async {
    final cubit = build(bookingId: _booking25, claimId: _claim1);
    await cubit.load();

    final ready = cubit.state as ClaimReady;
    expect(ready.claim.evidence, hasLength(2));
    expect(ready.canRespond, isTrue);
    await cubit.close();
  });

  test('a claim from another booking is not available', () async {
    final cubit = build(bookingId: _booking21, claimId: _claim1);
    await cubit.load();

    expect(cubit.state, isA<ClaimNotAvailable>());
    await cubit.close();
  });

  test('agree submits then reloads the accepted claim', () async {
    final cubit = build(bookingId: _booking25, claimId: _claim1);
    final states = <ClaimState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.load();

    await cubit.agree();

    expect(states.whereType<ClaimSubmitting>().length, 1);
    final ready = cubit.state as ClaimReady;
    expect(ready.claim.status, DamageClaimStatus.guestAccepted);
    expect(backend.stay.claimAnswers, 1);
    await subscription.cancel();
    await cubit.close();
  });

  test('a too-short dispute shows the note error and sends nothing', () async {
    final cubit = build(bookingId: _booking25, claimId: _claim1);
    await cubit.load();

    await cubit.dispute('قصير');

    final ready = cubit.state as ClaimReady;
    expect(ready.noteError, isTrue);
    expect(ready.disputeOpen, isFalse, reason: 'error copy keeps the form');
    expect(backend.stay.claimAnswers, 0);
    await cubit.close();
  });

  test('a valid dispute returns the support case number', () async {
    final cubit = build(bookingId: _booking25, claimId: _claim1);
    await cubit.load();

    await cubit.dispute('a valid long reason text');

    final ready = cubit.state as ClaimReady;
    expect(ready.claim.status, DamageClaimStatus.guestDisputed);
    expect(ready.claim.supportCaseNumber, 'SC-1001');
    await cubit.close();
  });

  test('answering an answered claim reloads it', () async {
    final cubit = build(bookingId: _booking25, claimId: _claim2);
    final states = <ClaimState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.load();

    await cubit.agree();

    // CLAIM_ALREADY_ANSWERED: the key is cleared and the claim reloads.
    final afterSubmitting = states.sublist(
      states.lastIndexOf(states.whereType<ClaimSubmitting>().first),
    );
    expect(
      afterSubmitting.whereType<ClaimLoading>().length,
      1,
      reason: 'the claim was fetched again',
    );
    expect(cubit.state, isA<ClaimReady>());
    expect(backend.stay.claimAnswers, 1);
    await subscription.cancel();
    await cubit.close();
  });

  test('a double agree makes one call', () async {
    final cubit = build(bookingId: _booking25, claimId: _claim1);
    await cubit.load();

    final first = cubit.agree();
    await cubit.agree();
    await first;

    expect(backend.stay.claimAnswers, 1);
    await cubit.close();
  });
}
