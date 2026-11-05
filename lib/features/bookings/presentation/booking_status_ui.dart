import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/design_system/components/acknowledgement_tracker.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Pure display helpers for booking status and refund stage
/// (Guest Plan §4.6 and §7.2). No widget state, no amounts computed here.
String bookingStatusLabel(BookingStatus status, AppLocalizations l10n) =>
    switch (status) {
      BookingStatus.paymentPending => l10n.bookingStatusPaymentPending,
      BookingStatus.paymentVerifying => l10n.bookingStatusPaymentVerifying,
      BookingStatus.awaitingOwner => l10n.bookingStatusAwaitingOwner,
      BookingStatus.paymentConflict => l10n.bookingStatusPaymentConflict,
      BookingStatus.confirmed => l10n.bookingStatusConfirmed,
      BookingStatus.checkedIn => l10n.bookingStatusCheckedIn,
      BookingStatus.completed => l10n.bookingStatusCompleted,
      BookingStatus.rejected => l10n.bookingStatusRejected,
      BookingStatus.expired => l10n.bookingStatusExpired,
      BookingStatus.cancelled => l10n.bookingStatusCancelled,
      BookingStatus.noShow => l10n.bookingStatusNoShow,
      BookingStatus.abandoned => l10n.bookingStatusAbandoned,
      BookingStatus.unknown => l10n.bookingStatusUnknown,
    };

StatusTone bookingStatusTone(BookingStatus status) => switch (status) {
  BookingStatus.paymentPending => StatusTone.warning,
  BookingStatus.paymentVerifying => StatusTone.info,
  BookingStatus.awaitingOwner => StatusTone.pending,
  BookingStatus.confirmed => StatusTone.success,
  BookingStatus.checkedIn => StatusTone.badge,
  BookingStatus.completed => StatusTone.completed,
  BookingStatus.rejected ||
  BookingStatus.expired ||
  BookingStatus.paymentConflict => StatusTone.rejected,
  BookingStatus.cancelled ||
  BookingStatus.noShow ||
  BookingStatus.abandoned ||
  BookingStatus.unknown => StatusTone.cancelled,
};

String refundStageLabel(RefundStage stage, AppLocalizations l10n) =>
    switch (stage) {
      RefundStage.requested => l10n.refundChipRequested,
      RefundStage.approved || RefundStage.executed => l10n.refundChipInProgress,
      RefundStage.verified => l10n.refundChipDone,
      RefundStage.failed ||
      RefundStage.cancelled ||
      RefundStage.unknown => l10n.refundChipProblem,
    };

StatusTone refundStageTone(RefundStage stage) => switch (stage) {
  RefundStage.requested => StatusTone.warning,
  RefundStage.approved || RefundStage.executed => StatusTone.info,
  RefundStage.verified => StatusTone.completed,
  RefundStage.failed ||
  RefundStage.cancelled ||
  RefundStage.unknown => StatusTone.rejected,
};

/// The status message under the details header (Guest Plan §7.2). Amounts
/// are the server's `paid`/`remaining` values shown as received — nothing
/// is computed here.
String bookingStatusMessage(BookingDetails details, AppLocalizations l10n) {
  // G3 acknowledgements refine the confirmed / checked-in / cancelled
  // messages (data-model §4); everything else keeps the G2 wording.
  final acknowledgements = details.acknowledgements;
  final status = details.status;
  if (status == BookingStatus.confirmed) {
    if (acknowledgements.guestCheckInAt != null &&
        acknowledgements.hostCheckInAt == null) {
      return l10n.bookingMsgWaitingHandover;
    }
    if (acknowledgements.hostCheckInAt != null &&
        acknowledgements.guestCheckInAt == null) {
      return l10n.bookingMsgHostHandedOver;
    }
    if (!acknowledgements.hasAny &&
        details.events.isNotEmpty &&
        details.events.last.eventType == 'booking.reopened') {
      return l10n.bookingMsgReopened;
    }
  }
  if (status == BookingStatus.checkedIn &&
      acknowledgements.guestCheckOutAt != null) {
    return l10n.bookingMsgWaitingCheckout;
  }
  if (status == BookingStatus.cancelled) {
    final scope = details.cancellation?.byScope;
    if (scope == 'platform') return l10n.bookingMsgCancelledByPlatform;
    if (scope == 'guest') return l10n.bookingMsgCancelledByGuest;
  }
  return switch (details.status) {
    BookingStatus.paymentPending => l10n.bookingMsgPaymentPending,
    BookingStatus.paymentVerifying => l10n.bookingMsgPaymentVerifying,
    BookingStatus.awaitingOwner =>
      details.ownerResponseDeadline == null
          ? l10n.bookingMsgAwaitingOwnerNoDeadline
          : l10n.bookingMsgAwaitingOwner(
              formatCairoDayMonthTime(details.ownerResponseDeadline!),
            ),
    BookingStatus.confirmed =>
      details.remaining.amountMinor > 0
          ? l10n.bookingMsgConfirmedWithRemaining(
              MoneyFormatter().format(details.remaining),
            )
          : l10n.bookingMsgConfirmed,
    BookingStatus.checkedIn => l10n.bookingMsgCheckedIn,
    BookingStatus.completed => l10n.bookingMsgCompleted,
    BookingStatus.rejected => l10n.bookingMsgRejected(
      MoneyFormatter().format(details.paid),
    ),
    BookingStatus.expired => l10n.bookingMsgExpired(
      MoneyFormatter().format(details.paid),
    ),
    BookingStatus.cancelled => l10n.bookingMsgCancelled,
    BookingStatus.noShow => l10n.bookingMsgNoShow,
    BookingStatus.paymentConflict => l10n.bookingMsgConflict(
      MoneyFormatter().format(details.paid),
    ),
    BookingStatus.abandoned => l10n.bookingMsgAbandoned,
    BookingStatus.unknown => l10n.bookingMsgUnknown,
  };
}

/// The handover tracker under the status card, or null when there is
/// nothing to track (data-model §4). The check-out tracker wins over the
/// check-in one; a completed booking with no check-out times has none.
({String title, List<AckStep> steps, String? note})? ackStepsFor(
  BookingDetails details,
  AppLocalizations l10n,
) {
  final acknowledgements = details.acknowledgements;
  final checkoutTracker =
      (details.status == BookingStatus.checkedIn &&
          (acknowledgements.guestCheckOutAt != null ||
              acknowledgements.hostCheckOutAt != null)) ||
      details.status == BookingStatus.completed;
  if (checkoutTracker) {
    if (acknowledgements.guestCheckOutAt == null &&
        acknowledgements.hostCheckOutAt == null) {
      return null;
    }
    return (
      title: l10n.ackTitleCheckout,
      steps: [
        _ackStep(
          label: l10n.ackYou,
          at: acknowledgements.guestCheckOutAt,
          l10n: l10n,
        ),
        _ackStep(
          label: l10n.ackOwner,
          at: acknowledgements.hostCheckOutAt,
          l10n: l10n,
        ),
      ],
      note: acknowledgements.keyLeftSafe ? l10n.ackKeyLeftSafe : null,
    );
  }
  final checkinTracker =
      (details.status == BookingStatus.confirmed ||
          details.status == BookingStatus.checkedIn) &&
      (acknowledgements.guestCheckInAt != null ||
          acknowledgements.hostCheckInAt != null);
  if (checkinTracker) {
    return (
      title: l10n.ackTitleCheckin,
      steps: [
        _ackStep(
          label: l10n.ackYou,
          at: acknowledgements.guestCheckInAt,
          l10n: l10n,
        ),
        _ackStep(
          label: l10n.ackOwner,
          at: acknowledgements.hostCheckInAt,
          l10n: l10n,
        ),
      ],
      note: null,
    );
  }
  return null;
}

AckStep _ackStep({
  required String label,
  required DateTime? at,
  required AppLocalizations l10n,
}) => AckStep(
  label: label,
  statusText: at == null
      ? l10n.ackWaiting
      : l10n.ackConfirmedAt(formatCairoDayMonthTime(at)),
  done: at != null,
);
