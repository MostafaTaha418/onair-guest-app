import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';

Future<Map<String, dynamic>> _baseJson() async {
  final decoded =
      jsonDecode(
            await File(
              'lib/features/bookings/data/fixtures/bookings.json',
            ).readAsString(),
          )
          as List<dynamic>;
  return Map<String, dynamic>.from(decoded.first as Map);
}

Map<String, dynamic> _g3Fields() => {
  'acknowledgements': {
    'guest_checkin_at': '2026-10-30T14:10:00Z',
    'host_checkin_at': '2026-10-30T14:05:00Z',
    'guest_checkout_at': null,
    'host_checkout_at': null,
    'key_left_safe': false,
  },
  'pending_cash': {
    'payment_id': 'c0000000-0000-4000-8000-000000000281',
    'challenge_id': 'a0000000-0000-4000-8000-000000000281',
    'collector_display_name': 'أحمد م.',
    'amount_minor': 337500,
    'masked_email': 'g***@mock.onair.test',
    'code_expires_at': '2026-11-01T10:15:00Z',
    'retry_after_seconds': 0,
    'origin': 'collector',
  },
  'pending_remaining_payment_id': 'c0000000-0000-4000-8000-000000000099',
  'damage_claims': [
    {
      'id': 'e0000000-0000-4000-8000-000000000001',
      'amount_minor': 50000,
      'status': 'open',
      'created_at': '2026-10-24T09:00:00Z',
    },
    {
      'id': 'e0000000-0000-4000-8000-000000000002',
      'amount_minor': 30000,
      'status': 'resolved',
      'created_at': '2026-10-23T15:00:00Z',
    },
  ],
  'replacement_offer': {
    'id': 'f0000000-0000-4000-8000-000000000001',
    'status': 'pending',
    'offered_property': {
      'id': '00000000-0000-4000-8000-00000000002f',
      'title': 'شقة بديلة على البحر',
      'area_name': 'رأس البر',
      'cover_image': null,
    },
    'check_in': '2026-11-15',
    'check_out': '2026-11-18',
    'price_difference_minor': 50000,
    'expires_at': '2026-11-02T10:00:00Z',
  },
  'cancellation': {
    'cancelled_at': '2026-10-31T10:00:00Z',
    'by_scope': 'guest',
    'reason_code': 'change_of_plans',
  },
};

Map<String, dynamic> _cashPayment() => {
  'id': 'c0000000-0000-4000-8000-000000000222',
  'purpose': 'remaining',
  'method': 'cash',
  'status': 'succeeded',
  'amount_minor': 225000,
  'paid_at': '2026-10-30T13:00:00Z',
  'receipt': {
    'receipt_no': 'R-2026-000123',
    'collector_display_name': 'أحمد م.',
    'confirmed_at': '2026-10-30T13:00:00Z',
  },
};

void main() {
  test('parses every G3 booking details field', () async {
    final json = await _baseJson();
    json.addAll(_g3Fields());
    json['payments'] = [...json['payments'] as List<dynamic>, _cashPayment()];

    final details = BookingDetails.fromJson(json);

    expect(details.acknowledgements.hasAny, isTrue);
    expect(
      details.acknowledgements.guestCheckInAt,
      DateTime.parse('2026-10-30T14:10:00Z'),
    );
    expect(details.pendingCash?.paymentId, endsWith('281'));
    expect(details.pendingCash?.origin, CashOrigin.collector);
    expect(details.pendingCash?.amount, Money(337500));
    expect(details.pendingRemainingPaymentId, endsWith('099'));
    expect(details.damageClaims, hasLength(2));
    expect(details.damageClaims.first.status, DamageClaimStatus.open);
    expect(details.replacementOffer?.direction, OfferDirection.guestPays);
    expect(details.replacementOffer?.difference, Money(50000));
    expect(details.cancellation?.reasonCode, 'change_of_plans');
    expect(details.payments.last.receipt?.receiptNo, 'R-2026-000123');
  });

  test('missing G3 fields use backward-compatible defaults', () async {
    final details = BookingDetails.fromJson(await _baseJson());
    expect(details.acknowledgements, StayAcknowledgements.empty);
    expect(details.acknowledgements.keyLeftSafe, isFalse);
    expect(details.pendingCash, isNull);
    expect(details.pendingRemainingPaymentId, isNull);
    expect(details.damageClaims, isEmpty);
    expect(details.replacementOffer, isNull);
    expect(details.cancellation, isNull);
  });

  test('cache keeps G3 fields but drops the cash challenge id', () async {
    final json = await _baseJson()
      ..addAll(_g3Fields());
    json['payments'] = [...json['payments'] as List<dynamic>, _cashPayment()];
    final details = BookingDetails.fromJson(json);

    final cached = details.toCacheJson();
    expect(cached['acknowledgements'], isNotNull);
    expect(cached['damage_claims'], isNotEmpty);
    expect(cached['replacement_offer'], isNotNull);
    expect(cached['cancellation'], isNotNull);
    expect(cached['pending_remaining_payment_id'], endsWith('099'));
    expect(
      (cached['pending_cash'] as Map<String, dynamic>).containsKey(
        'challenge_id',
      ),
      isFalse,
    );
    expect(BookingDetails.fromJson(cached).pendingCash?.challengeId, isEmpty);
  });

  test('replacement offer splits the signed difference once', () {
    final base = Map<String, dynamic>.from(
      _g3Fields()['replacement_offer']! as Map,
    );
    ReplacementOffer parse(int amount) => ReplacementOffer.fromJson({
      ...base,
      'price_difference_minor': amount,
    });

    expect(parse(50000).direction, OfferDirection.guestPays);
    expect(parse(50000).difference, Money(50000));
    expect(parse(-50000).direction, OfferDirection.guestRefunded);
    expect(parse(-50000).difference, Money(50000));
    expect(parse(0).direction, OfferDirection.none);
    expect(parse(0).difference, Money(0));
  });

  test('damage claim status has wire mapping and unknown fallback', () {
    expect(
      DamageClaimStatus.fromWire('in_mediation'),
      DamageClaimStatus.inMediation,
    );
    expect(DamageClaimStatus.fromWire('??'), DamageClaimStatus.unknown);
  });
}
