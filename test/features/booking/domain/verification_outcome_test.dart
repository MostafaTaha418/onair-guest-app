import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/features/booking/domain/verification_outcome.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';

const _example = <String, dynamic>{
  'id': 'b0000000-0000-4000-8000-000000000001',
  'code': 'OA-MOCK001',
  'status': 'confirmed',
  'property': {
    'id': '00000000-0000-4000-8000-00000000001f',
    'title': 'شقة',
    'cover_image': null,
    'area_name': 'المعادي',
    'city_name': 'القاهرة',
    'address_text': null,
    'check_in_time': '14:00',
    'check_out_time': '12:00',
  },
  'check_in': '2026-11-20',
  'check_out': '2026-11-23',
  'nights': 3,
  'guests_count': 2,
  'nightly_minor': 150000,
  'total_minor': 450000,
  'pay_now_minor': 112500,
  'paid_minor': 112500,
  'remaining_minor': 337500,
  'remaining_due_at': null,
  'currency': 'EGP',
  'owner_response_deadline': '2026-11-02T10:00:00Z',
  'payment_state': 'succeeded',
  'payments': <Object>[],
  'refund': null,
  'terms_snapshot': null,
  'access_instructions': null,
  'available_actions': ['contact_support'],
  'events': <Object>[],
  'created_at': '2026-10-28T08:55:00Z',
};

BookingDetails detailsWith(String status, {String? paymentState}) =>
    BookingDetails.fromJson({
      ..._example,
      'status': status,
      'payment_state': ?paymentState,
    });

void main() {
  test('every owner-decided or later status is a success', () {
    for (final status in const <String>[
      'awaiting_owner',
      'confirmed',
      'checked_in',
      'completed',
      'rejected',
      'expired',
      'cancelled',
      'no_show',
    ]) {
      expect(
        verificationOutcomeFor(detailsWith(status)),
        VerificationOutcome.success,
        reason: status,
      );
    }
  });

  test('a conflict booking is a conflict', () {
    expect(
      verificationOutcomeFor(detailsWith('payment_conflict')),
      VerificationOutcome.conflict,
    );
  });

  test('a failed payment is a failure, and abandoned too', () {
    expect(
      verificationOutcomeFor(
        detailsWith('payment_pending', paymentState: 'failed'),
      ),
      VerificationOutcome.failed,
    );
    expect(
      verificationOutcomeFor(detailsWith('abandoned')),
      VerificationOutcome.failed,
    );
  });

  test('pending and verifying states keep waiting, unknown too', () {
    for (final (status, state) in const <(String, String)>[
      ('payment_pending', 'pending'),
      ('payment_verifying', 'pending'),
      ('payment_verifying', 'failed'),
      ('unknown', 'pending'),
    ]) {
      expect(
        verificationOutcomeFor(detailsWith(status, paymentState: state)),
        VerificationOutcome.waiting,
        reason: '$status/$state',
      );
    }
  });
}
