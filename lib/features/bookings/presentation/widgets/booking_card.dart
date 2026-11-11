import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/countdown.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/countdown_text.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/domain/booking_summary.dart';
import 'package:on_air/features/bookings/presentation/booking_action_ui.dart';
import 'package:on_air/features/bookings/presentation/booking_status_ui.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// One row in a My Bookings tab (US3). [now] pins the countdown clock in
/// tests and goldens; production uses the real time. [onDeadlineReached]
/// fires once when the owner's deadline passes (FR-029): the screen asks
/// the server again — the card never touches the status itself.
final class BookingCard extends StatefulWidget {
  const BookingCard({
    required this.booking,
    required this.onTap,
    this.now,
    this.onDeadlineReached,
    super.key,
  });

  final BookingSummary booking;
  final VoidCallback onTap;
  final DateTime Function()? now;
  final VoidCallback? onDeadlineReached;

  @override
  State<BookingCard> createState() => _BookingCardState();
}

final class _BookingCardState extends State<BookingCard> {
  Countdown? _countdown;
  DateTime? _countdownDeadline;
  StreamSubscription<Duration>? _deadlineSubscription;
  var _deadlineNotified = false;
  var _focused = false;

  @override
  void didUpdateWidget(BookingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final deadline = widget.booking.ownerResponseDeadline;
    if (deadline != _countdownDeadline) {
      _countdown?.cancel();
      _countdown = null;
      _countdownDeadline = deadline;
      unawaited(_deadlineSubscription?.cancel());
      _deadlineSubscription = null;
      _deadlineNotified = false;
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    unawaited(_deadlineSubscription?.cancel());
    super.dispose();
  }

  void _notifyDeadlineReached() {
    if (_deadlineNotified) return;
    _deadlineNotified = true;
    widget.onDeadlineReached?.call();
  }

  Countdown? _countdownFor(BookingSummary booking) {
    if (booking.status != BookingStatus.awaitingOwner ||
        booking.ownerResponseDeadline == null) {
      return null;
    }
    if (_countdown == null || _countdownDeadline == null) {
      _countdownDeadline = booking.ownerResponseDeadline;
      _deadlineNotified = false;
      final countdown = _countdown = Countdown(
        deadlineUtc: booking.ownerResponseDeadline!,
        now: widget.now,
      );
      // FR-029: the card notices the deadline passing even though the
      // ticking text is excluded from semantics; the screen refreshes.
      // The subscription must not precede CountdownText's: a sync broadcast
      // controller delivers the first value only through onListen (first
      // listener), and the card only waits for the closing zero.
      scheduleMicrotask(() {
        if (!mounted || !identical(_countdown, countdown)) return;
        _deadlineSubscription = countdown.remaining.listen(
          (remaining) {
            if (remaining == Duration.zero) _notifyDeadlineReached();
          },
          onDone: _notifyDeadlineReached,
        );
      });
    }
    return _countdown;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? colors['textAccent'] : colors.primary;
    final booking = widget.booking;
    final locale = l10n.localeName;
    final statusLabel = bookingStatusLabel(booking.status, l10n);
    final refundLabel = booking.refundStage == null
        ? null
        : refundStageLabel(booking.refundStage!, l10n);
    final registry = _registryFor(context);
    final action = needsActionCode(
      registry.visible(booking.availableActions),
    );
    final actionName = action == null ? null : bookingActionLabel(action, l10n);
    final actionLabel = actionName == null
        ? null
        : l10n.bookingNeedsAction(actionName);
    final countdown = _countdownFor(booking);
    // One static announcement with the absolute Cairo deadline (FR-038):
    // the ticking strip is excluded from the card's semantics so the
    // announcement never changes every second.
    final deadlineLabel = countdown == null
        ? null
        : l10n.bookingMsgAwaitingOwner(
            formatCairoDayMonthTime(
              booking.ownerResponseDeadline!,
              locale: locale,
            ),
          );
    final base = theme.textTheme.bodyMedium!;
    final metaStyle = base.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: colors.textSecondary,
    );
    final overlay = ink.withValues(alpha: dark ? 0.08 : 0.07);
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        side: _focused
            ? BorderSide(color: ink, width: 2)
            : BorderSide(
                color: dark ? colors.border : colors['borderNeutral'],
              ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _focused = focused),
        splashColor: overlay,
        highlightColor: overlay,
        overlayColor: WidgetStatePropertyAll(overlay),
        child: Semantics(
          button: true,
          excludeSemantics: true,
          label: [
            booking.title,
            statusLabel,
            ?refundLabel,
            ?actionLabel,
            ?deadlineLabel,
          ].join(locale == 'ar' ? '، ' : ', '),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Dimens.minTouchTarget,
            ),
            child: AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              alignment: AlignmentDirectional.topStart,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      Dimens.space12,
                      Dimens.space12,
                      Dimens.space12,
                      actionName == null ? Dimens.space12 : Dimens.space8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Dimens.radiusField,
                          ),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: OnAirNetworkImage(
                              variants:
                                  booking.coverImage?.variants ?? const [],
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
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: base.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    AppIcons.calendarMonth,
                                    size: 14,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${DateOnlyFormatter.dayMonth(booking.stay.checkIn, locale: locale)}'
                                      ' – ${DateOnlyFormatter.dayMonth(booking.stay.checkOut, locale: locale)}',
                                      style: metaStyle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: Dimens.space4,
                                runSpacing: Dimens.space4,
                                children: [
                                  StatusChip(
                                    label: statusLabel,
                                    tone: bookingStatusTone(booking.status),
                                    style: StatusChipStyle.dot,
                                  ),
                                  // The refund chip rides along only when the
                                  // server reported a refund (US4).
                                  if (refundLabel != null)
                                    StatusChip(
                                      label: refundLabel,
                                      tone: refundStageTone(
                                        booking.refundStage!,
                                      ),
                                      style: StatusChipStyle.dot,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionName != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        96,
                        0,
                        Dimens.space12,
                        Dimens.space12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: 2),
                            child: Icon(
                              AppIcons.infoOutline,
                              size: 16,
                              color: colors['warning'],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: l10n.bookingNeedsActionLead,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: ' $actionName'),
                                ],
                              ),
                              style: metaStyle.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (countdown != null)
                    ExcludeSemantics(
                      child: _CountdownStrip(
                        countdown: countdown,
                        ink: ink,
                        style: metaStyle.copyWith(color: ink),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BookingActionRegistry _registryFor(BuildContext context) {
    try {
      return context.read<BookingActionRegistry>();
    } on Object {
      // Isolated legacy widget/golden harnesses have no repository stack.
      return BookingActionRegistry.g2();
    }
  }
}

/// The owner-deadline strip under an awaiting-owner card. Only its text
/// rebuilds on a tick; at zero it turns into "updating status" at the same
/// height while the screen asks the server again.
final class _CountdownStrip extends StatelessWidget {
  const _CountdownStrip({
    required this.countdown,
    required this.ink,
    required this.style,
  });

  final Countdown countdown;
  final Color ink;
  final TextStyle style;

  String _time(Duration remaining, AppLocalizations l10n) =>
      remaining >= const Duration(hours: 24)
      ? l10n.ownerDeadlineDays(remaining.inDays)
      : Countdown.format(remaining);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    // The sentence around the time comes from one translation; the time
    // itself is isolated left-to-right so its digits never reorder in RTL.
    const marker = '\u0000';
    final parts = l10n.ownerDeadlineCountdown(marker).split(marker);
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Dimens.space12,
        vertical: 6,
      ),
      color: colors['badgeNavActive'],
      alignment: AlignmentDirectional.centerStart,
      child: CountdownText(
        remaining: countdown.remaining,
        format: (remaining) =>
            l10n.ownerDeadlineCountdown(_time(remaining, l10n)),
        builder: (context, remaining) {
          if (remaining == Duration.zero) {
            return Row(
              children: [
                _UpdatingIndicator(ink: ink, track: colors.border),
                const SizedBox(width: Dimens.space8),
                Flexible(
                  child: Text(
                    l10n.bookingsStatusUpdating,
                    style: style.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Icon(AppIcons.schedule, size: 16, color: ink),
              const SizedBox(width: Dimens.space8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: parts.first),
                      TextSpan(
                        text: '\u2066${_time(remaining, l10n)}\u2069',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (parts.length > 1) TextSpan(text: parts.last),
                    ],
                  ),
                  style: style,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The spinner beside "updating status". It stops after a few seconds (and
/// never runs with animations off): if the refresh brings no new status the
/// strip rests instead of spinning forever.
final class _UpdatingIndicator extends StatefulWidget {
  const _UpdatingIndicator({required this.ink, required this.track});

  final Color ink;
  final Color track;

  @override
  State<_UpdatingIndicator> createState() => _UpdatingIndicatorState();
}

final class _UpdatingIndicatorState extends State<_UpdatingIndicator> {
  Timer? _stop;
  var _resting = false;

  @override
  void initState() {
    super.initState();
    _stop = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _resting = true);
    });
  }

  @override
  void dispose() {
    _stop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_resting || MediaQuery.disableAnimationsOf(context)) {
      return Icon(AppIcons.schedule, size: 16, color: widget.ink);
    }
    return SizedBox.square(
      dimension: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: widget.ink,
        backgroundColor: widget.track,
      ),
    );
  }
}
