import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/stay_range.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/range_calendar.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
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
  /// The first tap of a range, before the departure is picked.
  DateOnly? _pickedArrival;

  BookingFlowCubit get _cubit => context.read<BookingFlowCubit>();

  void _onDayTap(DateOnly day) {
    final cubit = _cubit;
    final state = cubit.state;
    final arrival = _pickedArrival;
    if (arrival == null || state.stay != null) {
      setState(() {
        _pickedArrival = day;
      });
      cubit.setStay(null);
      return;
    }
    if (!day.isAfter(arrival)) {
      setState(() {
        _pickedArrival = day;
      });
      return;
    }
    final range = StayRange(arrival, day);
    if (!range.isSelectable(state.unavailable)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).bookingRangeHasUnavailable,
          ),
        ),
      );
      setState(() {
        _pickedArrival = null;
      });
      cubit.setStay(null);
      return;
    }
    setState(() {
      _pickedArrival = null;
    });
    cubit.setStay(range);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = _cubit;
    if (cubit.state.termsHash.isEmpty) {
      // The booking only starts from "Book now", which carries the accepted
      // terms (AC-013); a hand-typed URL has none.
      return Scaffold(
        // The booking shell owns a nested navigator, so the automatic back
        // button never appears: the route is its first entry.
        appBar: AppBar(
          title: Text(l10n.bookingDatesTitle),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: ErrorView(
          message: l10n.bookingStartFromProperty,
          onRetry: () => context.go(AppRoutes.property(widget.propertyId)),
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
        appBar: AppBar(
          title: Text(l10n.bookingDatesTitle),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
          builder: (context, state) => switch (state.load) {
            FlowLoad.loading => const _DatesSkeleton(),
            FlowLoad.notAvailable => EmptyView(
              icon: AppIcons.homeOutlined,
              message: l10n.propertyNotAvailable,
            ),
            FlowLoad.failed => ErrorView(
              message: apiErrorMessage(state.error!, l10n),
              onRetry: cubit.retry,
              referenceNumber: state.error!.requestId,
            ),
            FlowLoad.offline => ErrorView(
              message: l10n.offline,
              onRetry: cubit.retry,
            ),
            FlowLoad.ready => _ReadyBody(
              state: state,
              today: widget.today ?? CairoTime.today(),
              pickedArrival: _pickedArrival,
              onDayTap: _onDayTap,
            ),
          },
        ),
        bottomNavigationBar: BlocBuilder<BookingFlowCubit, BookingFlowState>(
          builder: (context, state) {
            final online = context.read<ConnectivityCubit>().state.isOnline;
            return BottomActionBar(
              leading: const SizedBox.shrink(),
              action: OnAirPrimaryButton(
                key: const ValueKey('dates-continue'),
                label: l10n.bookingContinue,
                isLoading: state.quoting,
                onPressed: state.canContinue && online
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
    required this.onDayTap,
  });

  final BookingFlowState state;
  final DateOnly today;
  final DateOnly? pickedArrival;
  final void Function(DateOnly) onDayTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final stay = state.stay;
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        // The same availability container the details screen displays,
        // interactive here: this is where the stay is picked.
        Text(
          l10n.propertyAvailability,
          style: context.textStyles.sectionTitle.copyWith(
            color: colors['textAccent'],
          ),
        ),
        const SizedBox(height: 12),
        RangeCalendar(
          today: today,
          initialMonth: today,
          selectedCheckIn: pickedArrival ?? stay?.checkIn,
          selectedCheckOut: stay?.checkOut,
          unavailableNights: state.unavailable,
          lastSelectableDay: today.addDays(364),
          onDayTap: onDayTap,
        ),
        if (stay != null) ...[
          const SizedBox(height: Dimens.space8),
          Text(
            l10n.bookingNightsCount('${stay.nights}'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ] else ...[
          // Two-step picking: the hint names the step the guest is on, so a
          // fresh calendar never reads like a stuck selection.
          const SizedBox(height: Dimens.space8),
          Text(
            pickedArrival == null
                ? l10n.bookingPickCheckIn
                : l10n.bookingPickCheckOut,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: Dimens.space8),
          Text(
            apiErrorMessage(state.error!, l10n),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.errorText,
            ),
          ),
        ],
      ],
    );
  }
}

final class _DatesSkeleton extends StatelessWidget {
  const _DatesSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
    children: const [
      SkeletonBox(height: 32, width: 180),
      SizedBox(height: Dimens.space16),
      SkeletonBox(height: 360),
      SizedBox(height: Dimens.space16),
      SkeletonBox(height: 48),
    ],
  );
}
