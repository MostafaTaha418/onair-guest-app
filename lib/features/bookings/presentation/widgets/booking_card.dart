import 'package:flutter/material.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/countdown.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/countdown_text.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/presentation/booking_status_ui.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// One row in a My Bookings tab (US3). [now] pins the countdown clock in
/// tests and goldens; production uses the real time.
final class BookingCard extends StatefulWidget {
  const BookingCard({
    required this.booking,
    required this.onTap,
    this.now,
    super.key,
  });

  final BookingSummary booking;
  final VoidCallback onTap;
  final DateTime Function()? now;

  @override
  State<BookingCard> createState() => _BookingCardState();
}

final class _BookingCardState extends State<BookingCard> {
  Countdown? _countdown;
  DateTime? _countdownDeadline;

  @override
  void didUpdateWidget(BookingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final deadline = widget.booking.ownerResponseDeadline;
    if (deadline != _countdownDeadline) {
      _countdown?.cancel();
      _countdown = null;
      _countdownDeadline = deadline;
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  Countdown? _countdownFor(BookingSummary booking) {
    if (booking.status != BookingStatus.awaitingOwner ||
        booking.ownerResponseDeadline == null) {
      return null;
    }
    if (_countdown == null || _countdownDeadline == null) {
      _countdownDeadline = booking.ownerResponseDeadline;
      _countdown = Countdown(
        deadlineUtc: booking.ownerResponseDeadline!,
        now: widget.now,
      );
    }
    return _countdown;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final booking = widget.booking;
    final statusLabel = bookingStatusLabel(booking.status, l10n);
    final countdown = _countdownFor(booking);
    // One static announcement with the absolute Cairo deadline (FR-038):
    // the ticking CountdownText is excluded from the card's merged
    // semantics so the announcement never changes every second.
    final deadlineLabel = countdown == null
        ? null
        : l10n.bookingMsgAwaitingOwner(
            formatCairoDayMonthTime(booking.ownerResponseDeadline!),
          );
    return Card(
      margin: const EdgeInsetsDirectional.only(
        start: Dimens.screenSide,
        end: Dimens.screenSide,
        bottom: Dimens.space12,
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        child: Semantics(
          button: true,
          label: deadlineLabel == null
              ? '${booking.title}، $statusLabel'
              : '${booking.title}، $statusLabel، $deadlineLabel',
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Dimens.space12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.radiusChip),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: OnAirNetworkImage(
                      variants: booking.coverImage?.variants ?? const [],
                    ),
                  ),
                ),
                const SizedBox(width: Dimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: context.colors.textPrimary),
                      ),
                      const SizedBox(height: Dimens.space4),
                      Text(
                        '${DateOnlyFormatter.dayMonth(booking.stay.checkIn)}'
                        ' – ${DateOnlyFormatter.dayMonth(booking.stay.checkOut)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Dimens.space8),
                      Wrap(
                        spacing: Dimens.space8,
                        runSpacing: Dimens.space4,
                        children: [
                          StatusChip(
                            label: statusLabel,
                            tone: bookingStatusTone(booking.status),
                          ),
                          // The refund chip rides along only when the
                          // server reported a refund (US4).
                          if (booking.refundStage != null)
                            StatusChip(
                              label: refundStageLabel(
                                booking.refundStage!,
                                l10n,
                              ),
                              tone: refundStageTone(booking.refundStage!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (countdown != null)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: Dimens.space8,
                      ),
                      child: ExcludeSemantics(
                        child: CountdownText(
                          remaining: countdown.remaining,
                          format: (remaining) => l10n.ownerDeadlineCountdown(
                            Countdown.format(remaining),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
