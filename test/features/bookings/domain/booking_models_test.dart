import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';

const _exampleDetails = <String, dynamic>{
  'id': 'b0000000-0000-4000-8000-000000000001',
  'code': 'OA-MOCK001',
  'status': 'confirmed',
  'property': {
    'id': '00000000-0000-4000-8000-00000000001f',
    'title': 'شقة 3 غرف للتجربة',
    'cover_image': {
      'variants': [
        {'width': 320, 'url': 'https://cdn.mock.onair.test/310-320.jpg'},
        {'width': 720, 'url': 'https://cdn.mock.onair.test/310-720.jpg'},
      ],
      'blurhash': null,
    },
    'area_name': 'المعادي',
    'city_name': 'القاهرة',
    'address_text': 'شارع 9، المعادي، القاهرة',
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
  'remaining_due_at': '2026-11-19T22:00:00Z',
  'currency': 'EGP',
  'owner_response_deadline': null,
  'payment_state': 'succeeded',
  'payments': [
    {
      'id': 'c0000000-0000-4000-8000-000000000001',
      'purpose': 'initial',
      'method': 'kashier',
      'status': 'succeeded',
      'amount_minor': 112500,
      'paid_at': '2026-10-28T09:00:00Z',
    },
  ],
  'refund': null,
  'terms_snapshot': {
    'policy_summary': {
      'deposit_type': 'percent',
      'deposit_percent_bp': 2500,
      'deposit_amount_minor': null,
      'free_cancellation_hours': 72,
    },
  },
  'access_instructions': 'المفتاح مع حارس العمارة. اطلب منه باسم الحجز.',
  'available_actions': ['contact_support'],
  'events': [
    {
      'event_type': 'booking.started',
      'to_status': 'payment_pending',
      'created_at': '2026-10-28T08:55:00Z',
      'note': null,
    },
    {
      'event_type': 'booking.confirmed',
      'to_status': 'confirmed',
      'created_at': '2026-10-28T12:00:00Z',
      'note': null,
    },
  ],
  'created_at': '2026-10-28T08:55:00Z',
};

const _exampleListItem = <String, dynamic>{
  'id': 'b0000000-0000-4000-8000-000000000002',
  'code': 'OA-MOCK002',
  'property_id': '00000000-0000-4000-8000-000000000020',
  'title': 'شقة 3 غرف',
  'cover_image': null,
  'check_in': '2026-11-10',
  'check_out': '2026-11-12',
  'status': 'awaiting_owner',
  'refund_status': null,
  'owner_response_deadline': '2026-11-02T10:00:00Z',
  'created_at': '2026-10-20T02:00:00Z',
};

void main() {
  group('BookingStatus', () {
    test('fromWire maps every server value', () {
      final cases = <String, BookingStatus>{
        'payment_pending': BookingStatus.paymentPending,
        'payment_verifying': BookingStatus.paymentVerifying,
        'awaiting_owner': BookingStatus.awaitingOwner,
        'payment_conflict': BookingStatus.paymentConflict,
        'confirmed': BookingStatus.confirmed,
        'checked_in': BookingStatus.checkedIn,
        'completed': BookingStatus.completed,
        'rejected': BookingStatus.rejected,
        'expired': BookingStatus.expired,
        'cancelled': BookingStatus.cancelled,
        'no_show': BookingStatus.noShow,
        'abandoned': BookingStatus.abandoned,
      };
      for (final entry in cases.entries) {
        expect(
          BookingStatus.fromWire(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
      expect(BookingStatus.fromWire('weird'), BookingStatus.unknown);
      expect(BookingStatus.fromWire(null), BookingStatus.unknown);
    });

    test('terminal statuses match the glossary', () {
      expect(BookingStatus.confirmed.isTerminal, isFalse);
      expect(BookingStatus.paymentVerifying.isTerminal, isFalse);
      expect(BookingStatus.awaitingOwner.isTerminal, isFalse);
      expect(BookingStatus.checkedIn.isTerminal, isFalse);
      for (final status in [
        BookingStatus.completed,
        BookingStatus.cancelled,
        BookingStatus.rejected,
        BookingStatus.expired,
        BookingStatus.noShow,
        BookingStatus.paymentConflict,
        BookingStatus.abandoned,
      ]) {
        expect(status.isTerminal, isTrue, reason: status.name);
      }
    });

    test('arrival instructions show only while staying', () {
      expect(BookingStatus.confirmed.showsArrivalInstructions, isTrue);
      expect(BookingStatus.checkedIn.showsArrivalInstructions, isTrue);
      expect(BookingStatus.completed.showsArrivalInstructions, isFalse);
      expect(BookingStatus.awaitingOwner.showsArrivalInstructions, isFalse);
    });
  });

  test('BookingTab wire values', () {
    expect(BookingTab.current.wire, 'current');
    expect(BookingTab.past.wire, 'past');
    expect(BookingTab.cancelled.wire, 'cancelled');
    expect(BookingTab.pending.wire, 'pending');
  });

  test('RefundStage.fromWire', () {
    expect(RefundStage.fromWire('requested'), RefundStage.requested);
    expect(RefundStage.fromWire('approved'), RefundStage.approved);
    expect(RefundStage.fromWire('executed'), RefundStage.executed);
    expect(RefundStage.fromWire('verified'), RefundStage.verified);
    expect(RefundStage.fromWire('failed'), RefundStage.failed);
    expect(RefundStage.fromWire('cancelled'), RefundStage.cancelled);
    expect(RefundStage.fromWire('weird'), RefundStage.unknown);
  });

  test('PaymentState.fromWire', () {
    expect(PaymentState.fromWire('pending'), PaymentState.pending);
    expect(PaymentState.fromWire('failed'), PaymentState.failed);
    expect(PaymentState.fromWire('succeeded'), PaymentState.succeeded);
    expect(PaymentState.fromWire(null), PaymentState.pending);
    expect(PaymentState.fromWire('weird'), PaymentState.pending);
  });

  test('BookingDetails.fromJson reads the D1 example', () {
    final details = BookingDetails.fromJson(_exampleDetails);
    expect(details.id, 'b0000000-0000-4000-8000-000000000001');
    expect(details.code, 'OA-MOCK001');
    expect(details.status, BookingStatus.confirmed);
    expect(details.property.id, '00000000-0000-4000-8000-00000000001f');
    expect(details.property.title, 'شقة 3 غرف للتجربة');
    expect(details.property.areaName, 'المعادي');
    expect(details.property.cityName, 'القاهرة');
    expect(details.property.addressText, 'شارع 9، المعادي، القاهرة');
    expect(details.property.checkInTime, '14:00');
    expect(details.property.checkOutTime, '12:00');
    expect(details.property.coverImage, isNotNull);
    expect(details.stay.checkIn.toString(), '2026-11-20');
    expect(details.stay.checkOut.toString(), '2026-11-23');
    expect(details.nights, 3);
    expect(details.guests, 2);
    expect(details.nightly, Money(150000));
    expect(details.total, Money(450000));
    expect(details.payNow, Money(112500));
    expect(details.paid, Money(112500));
    expect(details.remaining, Money(337500));
    expect(details.remainingDueAt, DateTime.parse('2026-11-19T22:00:00Z'));
    expect(details.ownerResponseDeadline, isNull);
    expect(details.paymentState, PaymentState.succeeded);
    expect(details.payments, hasLength(1));
    expect(details.payments.first.id, 'c0000000-0000-4000-8000-000000000001');
    expect(details.payments.first.amount, Money(112500));
    expect(
      details.payments.first.paidAt,
      DateTime.parse('2026-10-28T09:00:00Z'),
    );
    expect(details.refund, isNull);
    expect(details.termsSnapshot, isNotNull);
    expect(
      details.accessInstructions,
      'المفتاح مع حارس العمارة. اطلب منه باسم الحجز.',
    );
    expect(details.availableActions, ['contact_support']);
    expect(details.events, hasLength(2));
    expect(details.createdAt, DateTime.parse('2026-10-28T08:55:00Z'));
  });

  test('toCacheJson drops the arrival instructions', () {
    final details = BookingDetails.fromJson(_exampleDetails);
    final cached = details.toCacheJson();
    expect(cached.containsKey('access_instructions'), isFalse);
    expect(BookingDetails.fromJson(cached), details.copyWithoutInstructions());
  });

  test('BookingSummary.fromJson reads the list item example', () {
    final summary = BookingSummary.fromJson(_exampleListItem);
    expect(summary.id, 'b0000000-0000-4000-8000-000000000002');
    expect(summary.code, 'OA-MOCK002');
    expect(summary.propertyId, '00000000-0000-4000-8000-000000000020');
    expect(summary.title, 'شقة 3 غرف');
    expect(summary.coverImage, isNull);
    expect(
      summary.stay,
      StayRange(DateOnly.parse('2026-11-10'), DateOnly.parse('2026-11-12')),
    );
    expect(summary.status, BookingStatus.awaitingOwner);
    expect(summary.refundStage, isNull);
    expect(
      summary.ownerResponseDeadline,
      DateTime.parse('2026-11-02T10:00:00Z'),
    );
    expect(summary.createdAt, DateTime.parse('2026-10-20T02:00:00Z'));
  });

  test('BookingsPage.fromJson reads items and a null cursor', () {
    final page = BookingsPage.fromJson(
      const {
        'items': [_exampleListItem],
        'next_cursor': null,
      },
    );
    expect(page.items, hasLength(1));
    expect(page.nextCursor, isNull);
  });
}
