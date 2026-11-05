import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/acknowledgement_tracker.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/booking_timeline.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_parts.dart';
import 'package:on_air/features/bookings/presentation/booking_action_ui.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_status_ui.dart';
import 'package:on_air/features/bookings/presentation/widgets/refund_section.dart';
import 'package:on_air/features/property/domain/policy_text.dart';
import 'package:on_air/features/property/presentation/widgets/policy_line_text.dart';
import 'package:on_air/features/stay/presentation/claims/claim_texts.dart';
import 'package:on_air/features/stay/presentation/offer/offer_card.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// One booking's full view (US3): status message, payments, saved terms,
/// timeline, arrival instructions, and only the server-allowed actions.
final class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({
    required this.bookingId,
    this.focus,
    super.key,
  });

  final String bookingId;
  final String? focus;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

final class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final GlobalKey _offerKey = GlobalKey();
  final GlobalKey _claimsKey = GlobalKey();
  final GlobalKey _paymentsKey = GlobalKey();
  var _focused = false;

  void _focusAfterFirstReady() {
    if (_focused || widget.focus == null) return;
    _focused = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = switch (widget.focus) {
        'offer' => _offerKey,
        'claims' => _claimsKey,
        'payments' => _paymentsKey,
        _ => null,
      };
      final target = key?.currentContext;
      if (target != null) {
        unawaited(
          Scrollable.ensureVisible(target),
        );
      }
    });
  }

  Future<void> _run(
    BookingDetails details,
    BookingActionCode action,
  ) async {
    final changed = await launchBookingAction(context, details, action);
    if (!mounted || !changed) return;
    await context.read<BookingDetailsCubit>().refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).stayActionDone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingDetailsCubit>();
    final l10n = AppLocalizations.of(context);
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    final registry = context.read<BookingActionRegistry>();
    return BlocBuilder<BookingDetailsCubit, BookingDetailsState>(
      builder: (context, state) {
        final ready = state is DetailsReady ? state : null;
        final visible = ready == null
            ? const <BookingActionCode>[]
            : registry.visible(ready.details.availableActions);
        final primary = firstGuestAction(visible);
        if (ready != null) _focusAfterFirstReady();
        return Scaffold(
          appBar: AppBar(),
          bottomNavigationBar: ready != null && primary != null
              ? BottomActionBar(
                  leading: const SizedBox.shrink(),
                  action: OnAirPrimaryButton(
                    key: ValueKey('primary-${primary.value}'),
                    label: bookingActionLabel(primary, l10n),
                    onPressed: online
                        ? () => _run(ready.details, primary)
                        : null,
                  ),
                )
              : null,
          body: switch (state) {
            DetailsLoading() => const _DetailsSkeleton(),
            DetailsNotAvailable() => EmptyView(
              icon: AppIcons.infoOutline,
              message: l10n.notAvailable,
            ),
            DetailsFailed() => ErrorView(
              message: apiErrorMessage(state.error, l10n),
              onRetry: cubit.load,
              referenceNumber: state.error.requestId,
            ),
            DetailsOffline() => ErrorView(
              message: l10n.offline,
              onRetry: cubit.load,
            ),
            DetailsReady() => RefreshIndicator(
              onRefresh: cubit.refresh,
              child: _DetailsList(
                state: state,
                primary: primary,
                offerKey: _offerKey,
                claimsKey: _claimsKey,
                paymentsKey: _paymentsKey,
                onRun: (action) => _run(state.details, action),
              ),
            ),
          },
        );
      },
    );
  }
}

final class _DetailsList extends StatelessWidget {
  const _DetailsList({
    required this.state,
    required this.primary,
    required this.offerKey,
    required this.claimsKey,
    required this.paymentsKey,
    required this.onRun,
  });

  final DetailsReady state;
  final BookingActionCode? primary;
  final GlobalKey offerKey;
  final GlobalKey claimsKey;
  final GlobalKey paymentsKey;
  final ValueChanged<BookingActionCode> onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    final details = state.details;
    final canPayRemaining = context
        .read<BookingActionRegistry>()
        .visible(details.availableActions)
        .contains(BookingActionCode.payRemaining);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
          sliver: SliverList.list(
            children: [
              if (state.fromCache)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: Dimens.space8,
                  ),
                  child: Text(
                    l10n.lastUpdated(formatCairoDayMonthTime(state.fetchedAt)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              _Header(details: details),
              const SizedBox(height: Dimens.space16),
              NoticeCard(
                icon: AppIcons.infoOutline,
                message: bookingStatusMessage(details, l10n),
              ),
              if (ackStepsFor(details, l10n) case final ack?) ...[
                const SizedBox(height: Dimens.space16),
                AcknowledgementTracker(
                  title: ack.title,
                  steps: ack.steps,
                  note: ack.note,
                ),
              ],
              if (details.replacementOffer case final offer?) ...[
                const SizedBox(height: Dimens.space16),
                KeyedSubtree(
                  key: offerKey,
                  child: OfferCard(
                    offer: offer,
                    onAnswered: () => unawaited(
                      context.read<BookingDetailsCubit>().refresh(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: Dimens.space16),
              Text(
                l10n.bookingStayTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: Dimens.space8),
              AmountRow(
                label: l10n.bookingArrival,
                value: DateOnlyFormatter.dayMonth(details.stay.checkIn),
              ),
              AmountRow(
                label: l10n.bookingDeparture,
                value: DateOnlyFormatter.dayMonth(details.stay.checkOut),
              ),
              AmountRow(
                label: l10n.bookingNights,
                value: '${details.nights}',
              ),
              AmountRow(
                label: l10n.searchGuestsLabel,
                value: '${details.guests}',
              ),
              if (details.property.checkInTime != null)
                AmountRow(
                  label: l10n.bookingCheckInTime,
                  value: details.property.checkInTime!,
                ),
              if (details.property.checkOutTime != null)
                AmountRow(
                  label: l10n.bookingCheckOutTime,
                  value: details.property.checkOutTime!,
                ),
              const SizedBox(height: Dimens.space16),
              KeyedSubtree(
                key: paymentsKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bookingPaymentsTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Dimens.space8),
                    AmountRow(
                      label: l10n.bookingTotal,
                      value: MoneyFormatter().format(details.total),
                    ),
                    AmountRow(
                      label: l10n.bookingPaid,
                      value: MoneyFormatter().format(details.paid),
                    ),
                    if (details.remaining.amountMinor > 0) ...[
                      AmountRow(
                        label: l10n.bookingRemaining,
                        value: MoneyFormatter().format(details.remaining),
                      ),
                      if (details.remainingDueAt != null)
                        AmountRow(
                          label: l10n.bookingRemaining,
                          value: l10n.bookingRemainingDue(
                            DateOnlyFormatter.dayMonth(
                              DateOnly.fromDateTime(details.remainingDueAt!),
                            ),
                          ),
                        ),
                    ],
                    if (canPayRemaining) ...[
                      const SizedBox(height: Dimens.space8),
                      InfoBanner(
                        message: l10n.remainingNote,
                        tone: StatusTone.info,
                      ),
                    ],
                    for (final line in details.payments) ...[
                      const SizedBox(height: Dimens.space4),
                      if (line.method == 'cash' && line.receipt != null)
                        Semantics(
                          button: true,
                          label: l10n.receiptShow,
                          child: InkWell(
                            onTap: () => context.push(
                              AppRoutes.receipt(details.id, line.id),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: AmountRow(
                                    label: _methodLabel(line, l10n),
                                    value: _lineValue(line, l10n),
                                  ),
                                ),
                                Icon(
                                  Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? AppIcons.chevronLeft
                                      : AppIcons.chevronRight,
                                  size: 16,
                                  color: context.colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        AmountRow(
                          label: _methodLabel(line, l10n),
                          value: _lineValue(line, l10n),
                        ),
                    ],
                  ],
                ),
              ),
              // Section 5: the refund's own progress (US4).
              if (details.refund != null) ...[
                const SizedBox(height: Dimens.space16),
                RefundSection(refund: details.refund!),
              ],
              // Section 6: the damage claims (US5).
              if (details.damageClaims.isNotEmpty)
                KeyedSubtree(
                  key: claimsKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Dimens.space16),
                      Text(
                        l10n.claimsSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: context.colors.textPrimary),
                      ),
                      const SizedBox(height: Dimens.space8),
                      for (final claim in details.damageClaims)
                        Card(
                          child: InkWell(
                            onTap: () => context.push(
                              AppRoutes.damageClaim(details.id, claim.id),
                            ),
                            child: Semantics(
                              button: true,
                              label:
                                  '${l10n.claimTitle} '
                                  '${MoneyFormatter().format(claim.amount)} '
                                  '${claimStatusLabel(claim.status, l10n)}',
                              child: Padding(
                                padding: const EdgeInsetsDirectional.all(
                                  Dimens.space12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        MoneyFormatter().format(claim.amount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: context.colors.textPrimary,
                                            ),
                                      ),
                                    ),
                                    StatusChip(
                                      label: claimStatusLabel(
                                        claim.status,
                                        l10n,
                                      ),
                                      tone: claimStatusTone(claim.status),
                                    ),
                                    const SizedBox(width: Dimens.space8),
                                    Icon(
                                      Directionality.of(context) ==
                                              TextDirection.rtl
                                          ? AppIcons.chevronLeft
                                          : AppIcons.chevronRight,
                                      size: 16,
                                      color: context.colors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: Dimens.space16),
              Text(
                l10n.bookingAddressTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: Dimens.space8),
              if (details.property.addressText != null) ...[
                Text(
                  details.property.addressText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Dimens.space8),
              ],
              if (state.instructions != null &&
                  details.status.showsArrivalInstructions) ...[
                Text(
                  l10n.bookingArrivalInstructions,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Dimens.space4),
                SelectableText(
                  state.instructions!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
              if (details.termsSnapshot != null) ...[
                const SizedBox(height: Dimens.space16),
                Text(
                  l10n.bookingSavedTermsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Dimens.space8),
                for (final line in policyLines(details.termsSnapshot!))
                  Text(policyLineText(line, l10n)),
              ],
              const SizedBox(height: Dimens.space16),
              Text(
                l10n.bookingTimelineTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: Dimens.space8),
              BookingTimeline(
                entries: [
                  for (final event in details.events)
                    TimelineEntry(
                      title: event.toStatus != null
                          ? bookingStatusLabel(event.toStatus!, l10n)
                          : l10n.bookingEventGeneric,
                      time: formatCairoDayMonthTime(event.createdAt),
                    ),
                ],
              ),
              const SizedBox(height: Dimens.space16),
              for (final action
                  in context.read<BookingActionRegistry>().visible(
                    details.availableActions,
                  ))
                if (action != primary &&
                    action != BookingActionCode.requestCancellation &&
                    action != BookingActionCode.contactSupport)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: Dimens.space8,
                    ),
                    child: OutlinedButton(
                      key: ValueKey('action-${action.value}'),
                      onPressed: online ? () => onRun(action) : null,
                      child: Text(bookingActionLabel(action, l10n)),
                    ),
                  ),
              if (context
                  .read<BookingActionRegistry>()
                  .visible(details.availableActions)
                  .contains(BookingActionCode.contactSupport))
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: Dimens.space8,
                  ),
                  child: OutlinedButton(
                    key: const ValueKey('action-contact_support'),
                    onPressed: online
                        ? () => context.push(
                            '${AppRoutes.supportNew}?booking=${details.id}',
                          )
                        : null,
                    child: Text(l10n.bookingContactSupport),
                  ),
                ),
              if (context
                  .read<BookingActionRegistry>()
                  .visible(details.availableActions)
                  .contains(BookingActionCode.requestCancellation))
                TextButton(
                  key: const ValueKey('action-request_cancellation'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.errorText,
                  ),
                  onPressed: online
                      ? () => onRun(BookingActionCode.requestCancellation)
                      : null,
                  child: Text(l10n.actionCancelBooking),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _methodLabel(PaymentLine line, AppLocalizations l10n) =>
      switch (line.method) {
        'cash' => l10n.paymentMethodCash,
        _ => l10n.paymentMethodCard,
      };

  String _lineValue(PaymentLine line, AppLocalizations l10n) {
    final status = switch (line.status) {
      'succeeded' => l10n.paymentLineSucceeded,
      'failed' || 'cancelled' || 'expired' => l10n.paymentLineFailed,
      _ => l10n.paymentLinePending,
    };
    final paidAt = line.paidAt == null ? null : formatCairoTime(line.paidAt!);
    return [
      MoneyFormatter().format(line.amount),
      status,
      ?paidAt,
    ].join(' · ');
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.details});

  final BookingDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.radiusCard),
              child: SizedBox(
                width: 96,
                height: 72,
                child: OnAirNetworkImage(
                  variants: details.property.coverImage?.variants ?? const [],
                ),
              ),
            ),
            const SizedBox(width: Dimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.property.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${details.property.areaName}، ${details.property.cityName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space12),
        Row(
          children: [
            Text(
              l10n.bookingCode,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(width: Dimens.space8),
            Expanded(
              child: Text(
                details.code,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Semantics(
              label: l10n.bookingCopyCode,
              button: true,
              child: IconButton(
                tooltip: l10n.bookingCopyCode,
                icon: const Icon(AppIcons.copy),
                onPressed: () {
                  unawaited(
                    Clipboard.setData(ClipboardData(text: details.code)),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.bookingCodeCopied)),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space4),
        // The refund chip sits next to the status chip only when the
        // server reported a refund (US4).
        Wrap(
          spacing: Dimens.space8,
          runSpacing: Dimens.space4,
          children: [
            StatusChip(
              label: bookingStatusLabel(details.status, l10n),
              tone: bookingStatusTone(details.status),
            ),
            if (details.refund != null)
              StatusChip(
                label: refundStageLabel(details.refund!.stage, l10n),
                tone: refundStageTone(details.refund!.stage),
              ),
          ],
        ),
      ],
    );
  }
}

final class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.all(Dimens.screenSide),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 72),
        SizedBox(height: Dimens.space16),
        SkeletonBox(height: 48),
        SizedBox(height: Dimens.space16),
        SkeletonBox(height: 160),
        SizedBox(height: Dimens.space16),
        SkeletonBox(height: 96),
      ],
    ),
  );
}
