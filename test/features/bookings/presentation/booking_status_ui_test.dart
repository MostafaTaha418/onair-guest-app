import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/presentation/booking_status_ui.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    CairoTime.initialize();
  });

  test('every booking status has its own label', () {
    final labels = {
      BookingStatus.paymentPending: l10n.bookingStatusPaymentPending,
      BookingStatus.paymentVerifying: l10n.bookingStatusPaymentVerifying,
      BookingStatus.awaitingOwner: l10n.bookingStatusAwaitingOwner,
      BookingStatus.paymentConflict: l10n.bookingStatusPaymentConflict,
      BookingStatus.confirmed: l10n.bookingStatusConfirmed,
      BookingStatus.checkedIn: l10n.bookingStatusCheckedIn,
      BookingStatus.completed: l10n.bookingStatusCompleted,
      BookingStatus.rejected: l10n.bookingStatusRejected,
      BookingStatus.expired: l10n.bookingStatusExpired,
      BookingStatus.cancelled: l10n.bookingStatusCancelled,
      BookingStatus.noShow: l10n.bookingStatusNoShow,
      BookingStatus.abandoned: l10n.bookingStatusAbandoned,
      BookingStatus.unknown: l10n.bookingStatusUnknown,
    };
    for (final status in BookingStatus.values) {
      expect(bookingStatusLabel(status, l10n), labels[status]);
    }
  });

  test('every booking status has its chip tone (Guest Plan §4.6)', () {
    final tones = {
      BookingStatus.paymentPending: StatusTone.warning,
      BookingStatus.paymentVerifying: StatusTone.info,
      BookingStatus.awaitingOwner: StatusTone.pending,
      BookingStatus.confirmed: StatusTone.success,
      BookingStatus.checkedIn: StatusTone.badge,
      BookingStatus.completed: StatusTone.completed,
      BookingStatus.rejected: StatusTone.rejected,
      BookingStatus.expired: StatusTone.rejected,
      BookingStatus.paymentConflict: StatusTone.rejected,
      BookingStatus.cancelled: StatusTone.cancelled,
      BookingStatus.noShow: StatusTone.cancelled,
      BookingStatus.abandoned: StatusTone.cancelled,
      BookingStatus.unknown: StatusTone.cancelled,
    };
    for (final status in BookingStatus.values) {
      expect(bookingStatusTone(status), tones[status], reason: status.name);
    }
  });

  test('refund stage labels group as specified', () {
    expect(
      refundStageLabel(RefundStage.requested, l10n),
      l10n.refundChipRequested,
    );
    expect(
      refundStageLabel(RefundStage.approved, l10n),
      l10n.refundChipInProgress,
    );
    expect(
      refundStageLabel(RefundStage.executed, l10n),
      l10n.refundChipInProgress,
    );
    expect(refundStageLabel(RefundStage.verified, l10n), l10n.refundChipDone);
    expect(refundStageLabel(RefundStage.failed, l10n), l10n.refundChipProblem);
    expect(
      refundStageLabel(RefundStage.cancelled, l10n),
      l10n.refundChipProblem,
    );
    expect(refundStageLabel(RefundStage.unknown, l10n), l10n.refundChipProblem);
  });

  test('refund stage tones follow the same grouping', () {
    expect(refundStageTone(RefundStage.requested), StatusTone.warning);
    expect(refundStageTone(RefundStage.approved), StatusTone.info);
    expect(refundStageTone(RefundStage.executed), StatusTone.info);
    expect(refundStageTone(RefundStage.verified), StatusTone.completed);
    expect(refundStageTone(RefundStage.failed), StatusTone.rejected);
    expect(refundStageTone(RefundStage.cancelled), StatusTone.rejected);
    expect(refundStageTone(RefundStage.unknown), StatusTone.rejected);
  });

  BookingDetails detailsWith(String status) => BookingDetails.fromJson({
    'id': 'b0000000-0000-4000-8000-000000000001',
    'code': 'OA-MOCK001',
    'status': status,
    'property': const <String, dynamic>{
      'id': 'p',
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
    'owner_response_deadline': '2026-11-02T10:00:00Z',
    'payment_state': 'succeeded',
    'payments': const <Object>[],
    'refund': null,
    'terms_snapshot': null,
    'available_actions': const <String>['contact_support'],
    'events': const <Object>[],
    'created_at': '2026-10-28T08:55:00Z',
  });

  test('every booking status has its own message (Guest Plan §7.2)', () {
    final paid = MoneyFormatter().format(Money(112500));
    final remaining = MoneyFormatter().format(Money(337500));
    final deadline = formatCairoDayMonthTime(
      DateTime.parse('2026-11-02T10:00:00Z'),
    );
    final messages = {
      'payment_pending': l10n.bookingMsgPaymentPending,
      'payment_verifying': l10n.bookingMsgPaymentVerifying,
      'awaiting_owner': l10n.bookingMsgAwaitingOwner(deadline),
      'confirmed': l10n.bookingMsgConfirmedWithRemaining(remaining),
      'checked_in': l10n.bookingMsgCheckedIn,
      'completed': l10n.bookingMsgCompleted,
      'rejected': l10n.bookingMsgRejected(paid),
      'expired': l10n.bookingMsgExpired(paid),
      'cancelled': l10n.bookingMsgCancelled,
      'no_show': l10n.bookingMsgNoShow,
      'payment_conflict': l10n.bookingMsgConflict(paid),
      'abandoned': l10n.bookingMsgAbandoned,
      'weird': l10n.bookingMsgUnknown,
    };
    for (final entry in messages.entries) {
      expect(
        bookingStatusMessage(detailsWith(entry.key), l10n),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test(
    'the confirmed message drops the remaining amount when nothing is due',
    () async {
      final json = {
        'id': 'b0000000-0000-4000-8000-000000000001',
        'code': 'OA-MOCK001',
        'status': 'confirmed',
        'property': <String, dynamic>{
          'id': 'p',
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
        'pay_now_minor': 450000,
        'paid_minor': 450000,
        'remaining_minor': 0,
        'remaining_due_at': null,
        'owner_response_deadline': null,
        'payment_state': 'succeeded',
        'payments': <Object>[],
        'refund': null,
        'terms_snapshot': null,
        'available_actions': <String>['contact_support'],
        'events': <Object>[],
        'created_at': '2026-10-28T08:55:00Z',
      };
      expect(
        bookingStatusMessage(BookingDetails.fromJson(json), l10n),
        l10n.bookingMsgConfirmed,
      );
    },
  );

  test(
    'an awaiting-owner booking without a deadline uses its own message',
    () async {
      final json = {
        'id': 'b0000000-0000-4000-8000-000000000001',
        'code': 'OA-MOCK001',
        'status': 'awaiting_owner',
        'property': <String, dynamic>{
          'id': 'p',
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
        'owner_response_deadline': null,
        'payment_state': 'succeeded',
        'payments': <Object>[],
        'refund': null,
        'terms_snapshot': null,
        'available_actions': <String>['contact_support'],
        'events': <Object>[],
        'created_at': '2026-10-28T08:55:00Z',
      };
      expect(
        bookingStatusMessage(BookingDetails.fromJson(json), l10n),
        l10n.bookingMsgAwaitingOwnerNoDeadline,
      );
    },
  );
}
