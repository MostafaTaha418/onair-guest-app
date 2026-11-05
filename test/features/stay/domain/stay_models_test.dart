import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/features/stay/domain/damage_claim.dart';
import 'package:on_air/features/stay/domain/stay_results.dart';

void main() {
  test('cancellation preview parses amounts and detects changes', () {
    final first = CancellationPreview.fromJson(const {
      'refund_minor': 270000,
      'non_refundable_minor': 90000,
      'policy_case': 'deposit_lost',
      'free_cancellation_until': '2026-10-29T10:00:00Z',
      'preview_token': 't1',
      'valid_until': '2026-11-01T10:10:00Z',
    });
    final second = CancellationPreview.fromJson(const {
      'refund_minor': 260000,
      'non_refundable_minor': 100000,
      'policy_case': 'no_refund',
    });

    expect(first.refund, Money(270000));
    expect(first.policyCase, PolicyCase.depositLost);
    expect(PreviewChange.between(first, second).any, isTrue);
    expect(PreviewChange.between(first, first), PreviewChange.none);
  });

  test('damage claim parses nested response and resolution', () {
    final claim = DamageClaim.fromJson(const {
      'id': 'claim-1',
      'booking_id': 'booking-1',
      'description': 'ضرر',
      'amount_minor': 30000,
      'status': 'resolved',
      'created_at': '2026-10-23T15:00:00Z',
      'evidence': [
        {'attachment_id': 'file-1', 'kind': 'image', 'width': 1600},
      ],
      'guest_response': {
        'decision': 'dispute',
        'note': 'لا أوافق على المطالبة',
        'responded_at': '2026-10-24T15:00:00Z',
      },
      'support_case_number': 'SC-1000',
      'resolution': {
        'outcome_code': 'no_charge',
        'amount_minor': null,
        'decided_at': '2026-10-25T15:00:00Z',
      },
    });

    expect(claim.status, DamageClaimStatus.resolved);
    expect(claim.response?.decision, ClaimDecision.dispute);
    expect(claim.resolution?.outcome, ClaimOutcome.noCharge);
    expect(
      claim,
      DamageClaim.fromJson(const {
        'id': 'claim-1',
        'booking_id': 'booking-1',
        'description': 'ضرر',
        'amount_minor': 30000,
        'status': 'resolved',
        'created_at': '2026-10-23T15:00:00Z',
        'evidence': [
          {'attachment_id': 'file-1', 'kind': 'image', 'width': 1600},
        ],
        'guest_response': {
          'decision': 'dispute',
          'note': 'لا أوافق على المطالبة',
          'responded_at': '2026-10-24T15:00:00Z',
        },
        'support_case_number': 'SC-1000',
        'resolution': {
          'outcome_code': 'no_charge',
          'amount_minor': null,
          'decided_at': '2026-10-25T15:00:00Z',
        },
      }),
    );
  });

  test('claim limits trim input and stay results parse', () {
    expect(ClaimLimits.validDisputeNote(' 1234567890 '), isTrue);
    expect(ClaimLimits.validDisputeNote('short'), isFalse);
    final answer = ClaimAnswerResult.fromJson(const {
      'status': 'guest_disputed',
      'support_case_number': 'SC-1001',
    });
    final offer = OfferAnswerResult.fromJson(const {
      'status': 'accepted',
      'new_booking_id': null,
    });
    expect(answer.status, DamageClaimStatus.guestDisputed);
    expect(offer.status, OfferStatus.accepted);
  });
}
