import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/presentation/booking_status_ui.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
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
}
