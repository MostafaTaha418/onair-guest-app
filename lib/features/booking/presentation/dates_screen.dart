import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/booking_flow_kit.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/booking/presentation/booking_flow_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The date step of the booking flow: the availability calendar lives here,
/// so the guest picks the stay (guests stay at their initial count) and
/// continues to the summary with a fresh server quote.
final class DatesScreen extends StatefulWidget {
  const DatesScreen({
    required this.propertyId,
    this.today,
    super.key,
  });

  final String propertyId;

  /// Overrides Cairo's current date for deterministic widget and golden tests.
  /// Production callers leave this unset and use the real Cairo calendar day.
  final DateOnly? today;

  @override
  State<DatesScreen> createState() => _DatesScreenState();
}

final class _DatesScreenState extends State<DatesScreen> {
  // The pick is in exactly one of four states: nothing, an arrival alone
  // ([_pickedArrival]), a departure alone ([_pickedDeparture], left after
  // the guest removed the arrival), or a full stay (the cubit's `stay`).

  /// The first tap of a range, before the departure is picked.
  DateOnly? _pickedArrival;

  /// The departure that stays after the guest tapped the arrival away; the
  /// next tap completes the stay around it.
  DateOnly? _pickedDeparture;

  BookingFlowCubit get _cubit => context.read<BookingFlowCubit>();

  /// Moves the pick to one state: at most one of the three is given.
  void _select({DateOnly? arrival, DateOnly? departure, StayRange? stay}) {
    setState(() {
      _pickedArrival = arrival;
      _pickedDeparture = departure;
    });
    _cubit.setStay(stay);
  }

  /// Whether every night of [range] can be booked; a refused range shows
  /// the notice.
  bool _bookable(StayRange range) {
    if (range.isSelectable(_cubit.state.unavailable)) return true;
    showFlowSnack(
      context,
      AppLocalizations.of(context).bookingRangeHasUnavailable,
    );
    return false;
  }

  /// A tap on a picked day removes it; any other tap extends or restarts
  /// the pick.
  void _onDayTap(DateOnly day) {
    final stay = _cubit.state.stay;
    final departure = _pickedDeparture;
    final arrival = _pickedArrival;
    if (stay != null) {
      _tapWithStay(day, stay);
    } else if (departure != null) {
      _tapWithDeparture(day, departure);
    } else if (arrival != null) {
      _tapWithArrival(day, arrival);
    } else {
      _select(arrival: day);
    }
  }

  void _tapWithStay(DateOnly day, StayRange stay) {
    if (day == stay.checkIn) {
      // The arrival is removed; the departure waits for a new partner.
      _select(departure: stay.checkOut);
    } else if (day == stay.checkOut) {
      // The departure is removed; the arrival waits for a new departure.
      _select(arrival: stay.checkIn);
    } else if (day.isAfter(stay.checkIn)) {
      // Any later day moves the departure in place; a refused range keeps
      // the current stay.
      final range = StayRange(stay.checkIn, day);
      if (_bookable(range)) _select(stay: range);
    } else {
      // An earlier day restarts the pick from a new arrival.
      _select(arrival: day);
    }
  }

  void _tapWithDeparture(DateOnly day, DateOnly departure) {
    if (day == departure) {
      _select();
      return;
    }
    // Before the kept departure, the tap is the new arrival. After it, the
    // kept day turns into the arrival and the tap is the new departure.
    final range = day.isBefore(departure)
        ? StayRange(day, departure)
        : StayRange(departure, day);
    // A refused range keeps the departure, so the guest only re-taps.
    if (_bookable(range)) _select(stay: range);
  }

  void _tapWithArrival(DateOnly day, DateOnly arrival) {
    if (day == arrival) {
      _select();
    } else if (day.isBefore(arrival)) {
      _select(arrival: day);
    } else {
      // A range over an unavailable night is refused and the pick cleared
      // (booking spec: the notice, then a fresh start).
      final range = StayRange(arrival, day);
      if (_bookable(range)) {
        _select(stay: range);
      } else {
        _select();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = _cubit;
    // The booking shell owns a nested navigator, so the automatic back
    // button never appears: the route is its first entry.
    final appBar = flowAppBar(
      context,
      title: l10n.bookingDatesTitle,
      onBack: () => context.pop(),
    );
    if (cubit.state.termsHash.isEmpty) {
      // The booking only starts from "Book now", which carries the accepted
      // terms (AC-013); a hand-typed URL has none.
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: appBar,
        body: FlowStateView(
          icon: AppIcons.apartment,
          message: l10n.bookingStartFromProperty,
          action: FlowButton(
            label: l10n.bookingBackToProperty,
            icon: AppIcons.arrowBackRounded,
            expand: false,
            onPressed: () => context.go(AppRoutes.property(widget.propertyId)),
          ),
        ),
      );
    }
    return BlocListener<BookingFlowCubit, BookingFlowState>(
      listenWhen: (previous, current) =>
          current.load == FlowLoad.ready &&
          !previous.needsVerification &&
          current.needsVerification,
      listener: (context, state) async {
        final ok = await context.push<bool>(
          AppRoutes.bookingVerify(widget.propertyId, returnTo: 'dates'),
        );
        if (!context.mounted) return;
        if (ok == true) {
          _cubit.verificationDone();
        } else {
          context.go(AppRoutes.property(widget.propertyId));
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: appBar,
        body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
          builder: (context, state) {
            final retry = FlowButton(
              label: l10n.retry,
              icon: AppIcons.refresh,
              kind: FlowButtonKind.outlined,
              expand: false,
              onPressed: cubit.retry,
            );
            return switch (state.load) {
              FlowLoad.loading => const _DatesSkeleton(),
              FlowLoad.notAvailable => FlowStateView(
                icon: AppIcons.eventBusy,
                message: l10n.propertyNotAvailable,
              ),
              FlowLoad.failed => FlowStateView(
                icon: AppIcons.errorOutline,
                iconColor: context.colors.errorText,
                message: apiErrorMessage(state.error!, l10n),
                action: retry,
                reference: state.error!.requestId,
              ),
              FlowLoad.offline => FlowStateView(
                icon: AppIcons.wifiOff,
                message: l10n.offline,
                action: retry,
              ),
              FlowLoad.ready => _ReadyBody(
                state: state,
                today: widget.today ?? CairoTime.today(),
                pickedArrival: _pickedArrival,
                pickedDeparture: _pickedDeparture,
                onDayTap: _onDayTap,
              ),
            };
          },
        ),
        bottomNavigationBar: BlocBuilder<BookingFlowCubit, BookingFlowState>(
          builder: (context, state) {
            // The bar belongs to the ready page and its skeleton only.
            if (state.load != FlowLoad.ready &&
                state.load != FlowLoad.loading) {
              return const SizedBox.shrink();
            }
            final online = context.watch<ConnectivityCubit>().state.isOnline;
            return FlowActionBar(
              child: FlowButton(
                key: const ValueKey('dates-continue'),
                label: l10n.bookingContinue,
                minHeight: 52,
                fontSize: 16,
                loading: state.quoting,
                onPressed:
                    state.load == FlowLoad.ready && state.canContinue && online
                    ? () async {
                        final quoted = await cubit.requestQuote();
                        if (quoted && context.mounted) {
                          await context.push(
                            AppRoutes.bookingSummary(widget.propertyId),
                          );
                        }
                      }
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.state,
    required this.today,
    required this.pickedArrival,
    required this.pickedDeparture,
    required this.onDayTap,
  });

  final BookingFlowState state;
  final DateOnly today;
  final DateOnly? pickedArrival;

  /// A departure kept alone after its arrival was removed.
  final DateOnly? pickedDeparture;
  final void Function(DateOnly) onDayTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    final stay = state.stay;
    final arrival = pickedArrival ?? stay?.checkIn;
    final departure = stay?.checkOut ?? pickedDeparture;
    // A missing arrival is always the current step, even when a departure
    // was kept.
    final step = arrival == null ? 0 : (stay == null ? 1 : 2);
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Dimens.screenSide,
        Dimens.space8,
        Dimens.screenSide,
        Dimens.space24,
      ),
      children: [
        if (!online) ...[
          const FlowOfflineBanner(icon: AppIcons.wifiOff),
          const SizedBox(height: Dimens.space16),
        ],
        FlowFadeUp(
          child: _StepIndicator(
            step: step,
            arrival: arrival,
            departure: departure,
          ),
        ),
        const SizedBox(height: Dimens.space16),
        FlowFadeUp(
          delayMs: 60,
          child: FlowCard(
            padding: const EdgeInsetsDirectional.fromSTEB(
              Dimens.space4,
              Dimens.space4,
              Dimens.space4,
              Dimens.space12,
            ),
            child: RangeCalendar(
              style: RangeCalendarStyle.banded,
              today: today,
              initialMonth: today,
              selectedCheckIn: arrival,
              selectedCheckOut: departure,
              unavailableNights: state.unavailable,
              lastSelectableDay: today.addDays(364),
              onDayTap: onDayTap,
            ),
          ),
        ),
        const SizedBox(height: Dimens.space16),
        // Two-step picking: the hint names the step the guest is on, so a
        // fresh calendar never reads like a stuck selection.
        Semantics(
          liveRegion: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Dimens.minTouchTarget),
            child: Center(
              child: stay != null
                  ? _NightsChip(nights: stay.nights)
                  : _Hint(
                      key: ValueKey(step),
                      text: step == 0
                          ? l10n.bookingPickCheckIn
                          : l10n.bookingPickCheckOut,
                    ),
            ),
          ),
        ),
        if (state.error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              apiErrorMessage(state.error!, l10n),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.errorText,
              ),
            ),
          ),
      ],
    );
  }
}

/// Two equal cells, check-in and check-out: the current one is outlined in
/// primary, a picked one shows its date.
final class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.arrival,
    required this.departure,
  });

  final int step;
  final DateOnly? arrival;
  final DateOnly? departure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StepCell(
              number: 1,
              label: l10n.bookingStepCheckIn,
              value: arrival,
              current: step == 0,
            ),
          ),
          const SizedBox(width: Dimens.space8),
          Expanded(
            child: _StepCell(
              number: 2,
              label: l10n.bookingStepCheckOut,
              value: departure,
              current: step == 1,
            ),
          ),
        ],
      ),
    );
  }
}

final class _StepCell extends StatelessWidget {
  const _StepCell({
    required this.number,
    required this.label,
    required this.value,
    required this.current,
  });

  final int number;
  final String label;
  final DateOnly? value;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final palette = FlowPalette.of(context);
    final done = value != null;
    final duration = flowDuration(context, 220);
    final (numberBg, numberFg) = current
        ? (colors.primary, colors.onPrimary)
        : done
        ? (palette.highlight, palette.badge)
        : (colors['cancelledBackground'], colors['cancelledText']);
    final shown = done
        ? DateOnlyFormatter.dayMonth(value!, locale: l10n.localeName)
        : '—';
    final base = Theme.of(context).textTheme.bodyMedium!;
    return Semantics(
      container: true,
      excludeSemantics: true,
      selected: current,
      label: '$label، $shown',
      child: AnimatedContainer(
        duration: duration,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: Dimens.space12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimens.radiusField),
          border: Border.all(
            color: current ? colors.primary : palette.border2,
          ),
          // The ring makes the current step's outline 2dp without moving
          // its content.
          boxShadow: [
            BoxShadow(
              color: current ? colors.primary : colors.transparent,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: duration,
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: numberBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: base.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: numberFg,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: base.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: current ? palette.accent : colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimens.space4),
            Text(
              shown,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: done ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Hint extends StatelessWidget {
  const _Hint({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FlowFadeUp(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              AppIcons.tapHint,
              size: 20,
              color: FlowPalette.of(context).accent,
            ),
          ),
          const SizedBox(width: Dimens.space8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The nights count once the stay is complete; it pulses on each change.
final class _NightsChip extends StatelessWidget {
  const _NightsChip({required this.nights});

  final int nights;

  @override
  Widget build(BuildContext context) {
    final palette = FlowPalette.of(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(nights),
      tween: Tween(begin: 0, end: 1),
      duration: flowDuration(context, 420),
      curve: flowEmphasized,
      builder: (context, t, child) => Transform.scale(
        scale: TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.86, end: 1.08), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 45),
        ]).transform(t),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: palette.highlight,
          borderRadius: BorderRadius.circular(Dimens.radiusChip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(AppIcons.nights, size: 18, color: palette.badge),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                AppLocalizations.of(context).bookingNightsCount('$nights'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.badge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ready page's shape: two step cells, the calendar card and the hint.
final class _DatesSkeleton extends StatelessWidget {
  const _DatesSkeleton();

  @override
  Widget build(BuildContext context) => FlowSkeletonScope(
    child: ListView(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Dimens.screenSide,
        vertical: Dimens.space8,
      ),
      children: [
        const Row(
          children: [
            Expanded(
              child: FlowSkeletonBlock(height: 68, radius: Dimens.radiusField),
            ),
            SizedBox(width: Dimens.space8),
            Expanded(
              child: FlowSkeletonBlock(height: 68, radius: Dimens.radiusField),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space16),
        FlowCard(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: Dimens.space12,
            vertical: Dimens.space16,
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FlowSkeletonBlock(height: 32, circle: true),
                  FlowSkeletonBlock(width: 120, height: 18),
                  FlowSkeletonBlock(height: 32, circle: true),
                ],
              ),
              const SizedBox(height: Dimens.space16),
              for (var week = 0; week < 5; week++) ...[
                if (week > 0) const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var day = 0; day < 7; day++)
                      const FlowSkeletonBlock(height: 32, circle: true),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Dimens.space16),
        const Center(child: FlowSkeletonBlock(width: 150, height: 16)),
      ],
    ),
  );
}
