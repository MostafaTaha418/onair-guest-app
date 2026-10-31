import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
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
String bookingStatusMessage(BookingDetails details, AppLocalizations l10n) =>
    switch (details.status) {
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
