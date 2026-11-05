import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/features/stay/domain/damage_claim.dart';

import '../../../helpers/fake_booking_backend.dart';

const _b20 = 'b0000000-0000-4000-8000-000000000020';
const _b21 = 'b0000000-0000-4000-8000-000000000021';
const _b22 = 'b0000000-0000-4000-8000-000000000022';
const _b23 = 'b0000000-0000-4000-8000-000000000023';
const _claim1 = 'e0000000-0000-4000-8000-000000000001';
const _claim2 = 'e0000000-0000-4000-8000-000000000002';
const _offer1 = 'f0000000-0000-4000-8000-000000000001';
const _offer2 = 'f0000000-0000-4000-8000-000000000002';

void main() {
  late FakeBookingBackend backend;

  setUp(() => backend = FakeBookingBackend(includeG3Fixtures: true));
  tearDown(() => backend.dispose());

  test(
    'preview cancellation succeeds and rejects an invalid booking',
    () async {
      final preview = await backend.stay.previewCancellation(_b21);
      expect(preview.refund, Money(270000));
      await expectLater(
        backend.stay.previewCancellation(_b22),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test('cancel is idempotent and detects changed terms', () async {
    final preview = await backend.stay.previewCancellation(_b23);
    final first = await backend.stay.cancelBooking(
      bookingId: _b23,
      expectedRefund: preview.refund,
      reason: CancellationReason.changeOfPlans,
      reasonNote: null,
      idempotencyKey: 'cancel-1',
    );
    final second = await backend.stay.cancelBooking(
      bookingId: _b23,
      expectedRefund: preview.refund,
      reason: CancellationReason.changeOfPlans,
      reasonNote: null,
      idempotencyKey: 'cancel-1',
    );
    expect(second, first);

    backend.stay.forceTermsChangeOnce(_b21);
    await expectLater(
      backend.stay.cancelBooking(
        bookingId: _b21,
        expectedRefund: Money(270000),
        reason: null,
        reasonNote: null,
        idempotencyKey: 'cancel-2',
      ),
      throwsA(isA<AppFailure>()),
    );
  });

  test('check-in succeeds only after full payment', () async {
    expect(await backend.stay.confirmCheckIn(_b21), 'confirmed');
    await expectLater(
      backend.stay.confirmCheckIn(_b20),
      throwsA(isA<AppFailure>()),
    );
  });

  test('check-out succeeds only for checked-in bookings', () async {
    expect(await backend.stay.confirmCheckOut(_b22), 'checked_in');
    await expectLater(
      backend.stay.confirmCheckOut(_b21),
      throwsA(isA<AppFailure>()),
    );
  });

  test('cash start is idempotent and validates cash eligibility', () async {
    final first = await backend.stay.startCashConfirmation(
      bookingId: _b20,
      collectorPhoneE164: '+201000000001',
      expectedAmount: Money(337500),
      idempotencyKey: 'cash-1',
    );
    final second = await backend.stay.startCashConfirmation(
      bookingId: _b20,
      collectorPhoneE164: '+201000000001',
      expectedAmount: Money(337500),
      idempotencyKey: 'cash-1',
    );
    expect(second, first);
    await expectLater(
      backend.stay.startCashConfirmation(
        bookingId: _b23,
        collectorPhoneE164: '+201000000001',
        expectedAmount: Money(0),
        idempotencyKey: 'cash-2',
      ),
      throwsA(isA<AppFailure>()),
    );
  });

  test('send cash code succeeds and surfaces rate limiting', () async {
    await backend.stay.sendCashCode('challenge');
    expect(backend.stay.codesSent, 1);
    backend.stay.rateLimitNextSend = true;
    await expectLater(
      backend.stay.sendCashCode('challenge'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('cash confirmation validates OTP then returns a receipt', () async {
    final request = await backend.stay.startCashConfirmation(
      bookingId: _b20,
      collectorPhoneE164: '+201000000001',
      expectedAmount: Money(337500),
      idempotencyKey: 'cash-confirm',
    );
    await expectLater(
      backend.stay.confirmCashPayment(
        paymentId: request.paymentId,
        challengeId: request.challengeId,
        code: '000000',
      ),
      throwsA(isA<AppFailure>()),
    );
    final receipt = await backend.stay.confirmCashPayment(
      paymentId: request.paymentId,
      challengeId: request.challengeId,
      code: '123456',
    );
    expect(receipt.receiptNo, startsWith('R-2026-'));
  });

  test('damage claim read succeeds and rejects missing claims', () async {
    expect((await backend.stay.getDamageClaim(_claim1)).id, _claim1);
    await expectLater(
      backend.stay.getDamageClaim('missing'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('damage claim response validates state and records dispute', () async {
    final result = await backend.stay.respondDamageClaim(
      claimId: _claim1,
      decision: ClaimDecision.dispute,
      note: 'المطالبة غير صحيحة تمامًا',
      idempotencyKey: 'claim-1',
    );
    expect(result.supportCaseNumber, 'SC-1001');
    await expectLater(
      backend.stay.respondDamageClaim(
        claimId: _claim2,
        decision: ClaimDecision.accept,
        note: null,
        idempotencyKey: 'claim-2',
      ),
      throwsA(isA<AppFailure>()),
    );
  });

  test('file URL succeeds and propagates a network error', () async {
    expect(
      (await backend.stay.fileUrl('file-1')).url.host,
      'files.mock.onair.test',
    );
    backend.stay.failNextWithNetwork = true;
    await expectLater(
      backend.stay.fileUrl('file-2'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('replacement offer can be answered only while pending', () async {
    final result = await backend.stay.respondReplacementOffer(
      offerId: _offer1,
      accept: true,
      idempotencyKey: 'offer-1',
    );
    expect(result.status.name, 'accepted');
    await expectLater(
      backend.stay.respondReplacementOffer(
        offerId: _offer2,
        accept: false,
        idempotencyKey: 'offer-2',
      ),
      throwsA(isA<AppFailure>()),
    );
  });

  test(
    'owner and collector helpers mutate bookings and reject missing ids',
    () async {
      await backend.stay.confirmCheckIn(_b21);
      await backend.stay.ownerConfirmsHandover(_b21);
      expect((await backend.server.bookings)[_b21]!['status'], 'checked_in');

      await backend.stay.confirmCheckOut(_b22);
      await backend.stay.ownerConfirmsCheckout(_b22, keyLeftSafe: true);
      expect((await backend.server.bookings)[_b22]!['status'], 'completed');

      await backend.stay.collectorRecordsCash(_b20);
      expect((await backend.server.bookings)[_b20]!['pending_cash'], isNotNull);

      await expectLater(
        backend.stay.ownerConfirmsHandover('missing'),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(
        backend.stay.collectorRecordsCash('missing'),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test(
    'claim and refund helpers mutate fixtures and reject missing ids',
    () async {
      const bookingId = 'b0000000-0000-4000-8000-000000000025';
      final before = (await backend.server.bookings)[bookingId]!;
      final count = (before['damage_claims'] as List).length;
      await backend.stay.openClaim(bookingId);
      expect(before['damage_claims'] as List, hasLength(count + 1));

      const refundBooking = 'b0000000-0000-4000-8000-000000000026';
      await backend.stay.advanceRefund(refundBooking);
      final refund =
          (await backend.server.bookings)[refundBooking]!['refund'] as Map;
      expect(refund['status'], 'approved');

      await expectLater(
        backend.stay.openClaim('missing'),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(
        backend.stay.advanceRefund('missing'),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test(
    'forced terms and amount changes are visible to the next calls',
    () async {
      backend.stay.forceTermsChangeOnce(_b21);
      expect(
        (await backend.stay.previewCancellation(_b21)).refund,
        Money(260000),
      );

      backend.stay.changeAmountOnce(_b20);
      await expectLater(
        backend.stay.startCashConfirmation(
          bookingId: _b20,
          collectorPhoneE164: '+201000000001',
          expectedAmount: Money(337500),
          idempotencyKey: 'changed-amount',
        ),
        throwsA(isA<AppFailure>()),
      );
    },
  );
}
