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
import 'package:on_air/core/time/cairo_time.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/acknowledgement_tracker.dart';
import 'package:on_air/design_system/components/booking_flow_kit.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_parts.dart';
import 'package:on_air/features/bookings/domain/booking_status.dart';
import 'package:on_air/features/bookings/presentation/booking_action_ui.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_status_ui.dart';
import 'package:on_air/features/bookings/presentation/widgets/refund_section.dart';
import 'package:on_air/features/property/domain/policy_text.dart';
import 'package:on_air/features/property/presentation/widgets/policy_line_text.dart';
import 'package:on_air/features/stay/data/mock_stay_server.dart';
import 'package:on_air/features/stay/presentation/claims/claim_texts.dart';
import 'package:on_air/features/stay/presentation/mock_stay_tools_sheet.dart';
import 'package:on_air/features/stay/presentation/offer/offer_card.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The details redesign's tone for a booking status (dates · summary ·
/// details spec, §5).
FlowTone bookingFlowTone(BookingStatus status) => switch (status) {
  BookingStatus.paymentPending || BookingStatus.unknown => FlowTone.warning,
  BookingStatus.paymentVerifying || BookingStatus.checkedIn => FlowTone.info,
  BookingStatus.awaitingOwner => FlowTone.badge,
  BookingStatus.confirmed || BookingStatus.completed => FlowTone.success,
  BookingStatus.paymentConflict ||
  BookingStatus.rejected ||
  BookingStatus.noShow => FlowTone.rejected,
  BookingStatus.cancelled ||
  BookingStatus.expired ||
  BookingStatus.abandoned => FlowTone.cancelled,
};

/// The redesign's tone for a shared [StatusTone].
FlowTone flowToneOf(StatusTone tone) => switch (tone) {
  StatusTone.warning => FlowTone.warning,
  StatusTone.info => FlowTone.info,
  StatusTone.pending || StatusTone.badge => FlowTone.badge,
  StatusTone.success || StatusTone.completed => FlowTone.success,
  StatusTone.rejected => FlowTone.rejected,
  StatusTone.cancelled => FlowTone.cancelled,
};

IconData _noticeIcon(BookingStatus status) => switch (bookingFlowTone(status)) {
  FlowTone.success => AppIcons.checkCircleLine,
  FlowTone.rejected => AppIcons.xCircleLine,
  FlowTone.cancelled => AppIcons.blocked,
  FlowTone.badge => AppIcons.hourglass,
  FlowTone.warning => AppIcons.warningOutline,
  FlowTone.info =>
    status == BookingStatus.checkedIn ? AppIcons.leave : AppIcons.infoOutline,
};

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

  /// Blocks a second fast tap in the same frame, before the pushed screen or
  /// sheet is on top. It is released after the next frame, never by waiting
  /// for the opened route: a route that leaves through `go` (the cash
  /// receipt, a notification) never completes its future, and a lock tied
  /// to it would freeze every action on this page.
  var _launching = false;

  Future<void> _run(
    BookingDetails details,
    BookingActionCode action,
  ) => _guarded(() => launchBookingAction(context, details, action));

  /// Opens a claim from its card. The claim screen pops `true` once the
  /// guest answered, so the claim's status and actions are fetched again.
  Future<void> _openClaim(String bookingId, String claimId) => _guarded(
    () async =>
        await context.push<bool>(AppRoutes.damageClaim(bookingId, claimId)) ??
        false,
  );

  Future<void> _guarded(Future<bool> Function() open) async {
    // While another screen or sheet is on top, this page takes no action
    // taps (a tap that slipped through during a transition is ignored).
    if (_launching || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _launching = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _launching = false);
    final changed = await open();
    if (!mounted || !changed) return;
    await context.read<BookingDetailsCubit>().refresh();
    if (!mounted) return;
    showFlowSnack(context, AppLocalizations.of(context).stayActionDone);
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
        final retry = FlowButton(
          label: l10n.retry,
          icon: AppIcons.refresh,
          kind: FlowButtonKind.outlined,
          expand: false,
          onPressed: cubit.load,
        );
        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: flowAppBar(
            context,
            title: l10n.bookingDetailsTitle,
            actions: [
              // Mock-mode only: the owner/collector tools (Appendix D §8).
              if (ready != null && context.read<MockStayServer?>() != null)
                IconButton(
                  icon: const Icon(AppIcons.tuneOutlined),
                  tooltip: l10n.mockToolsTitle,
                  onPressed: () => showMockStayTools(context, ready.details.id),
                ),
            ],
          ),
          bottomNavigationBar: ready != null && primary != null
              ? FlowActionBar(
                  child: FlowButton(
                    key: ValueKey('primary-${primary.value}'),
                    label: bookingActionLabel(primary, l10n),
                    minHeight: 52,
                    textSize: 16,
                    onPressed: online
                        ? () => _run(ready.details, primary)
                        : null,
                  ),
                )
              : null,
          body: switch (state) {
            DetailsLoading() => const _DetailsSkeleton(),
            DetailsNotAvailable() => FlowStateView(
              icon: AppIcons.eventBusy,
              message: l10n.notAvailable,
            ),
            DetailsFailed() => FlowStateView(
              icon: AppIcons.errorOutline,
              iconColor: context.colors.errorText,
              message: apiErrorMessage(state.error, l10n),
              action: retry,
              reference: state.error.requestId,
            ),
            DetailsOffline() => FlowStateView(
              icon: AppIcons.wifiOff,
              message: l10n.offline,
              action: retry,
            ),
            DetailsReady() => RefreshIndicator(
              color: context.colors.primary,
              onRefresh: cubit.refresh,
              child: _DetailsList(
                state: state,
                primary: primary,
                offerKey: _offerKey,
                claimsKey: _claimsKey,
                paymentsKey: _paymentsKey,
                onRun: (action) => _run(state.details, action),
                onOpenClaim: (claimId) => _openClaim(state.details.id, claimId),
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
    required this.onOpenClaim,
  });

  final DetailsReady state;
  final BookingActionCode? primary;
  final GlobalKey offerKey;
  final GlobalKey claimsKey;
  final GlobalKey paymentsKey;
  final ValueChanged<BookingActionCode> onRun;
  final ValueChanged<String> onOpenClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final colors = context.colors;
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    final details = state.details;
    final money = MoneyFormatter();
    final visible = context.read<BookingActionRegistry>().visible(
      details.availableActions,
    );
    final canPayRemaining = visible.contains(
      BookingActionCode.payRemaining,
    );
    final secondary = [
      for (final action in visible)
        if (action != primary &&
            action != BookingActionCode.requestCancellation &&
            action != BookingActionCode.contactSupport)
          action,
    ];
    final hasSupport = visible.contains(BookingActionCode.contactSupport);
    final hasCancel = visible.contains(BookingActionCode.requestCancellation);
    final instructions =
        state.instructions != null && details.status.showsArrivalInstructions
        ? state.instructions
        : null;

    final sections = <Widget>[
      if (state.fromCache)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                AppIcons.history,
                size: 16,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.lastUpdated(
                  formatCairoDayMonthTime(state.fetchedAt, locale: locale),
                ),
                style: flowText(
                  context,
                  base: Theme.of(context).textTheme.bodySmall,
                  size: 12,
                  weight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      if (!online) const FlowOfflineBanner(icon: AppIcons.wifiOff),
      FlowFadeUp(child: _Header(details: details)),
      FlowFadeUp(
        delayMs: 40,
        child: FlowNoticeCard(
          icon: _noticeIcon(details.status),
          tone: bookingFlowTone(details.status),
          message: bookingStatusMessage(details, l10n),
        ),
      ),
      if (ackStepsFor(details, l10n) case final ack?)
        FlowFadeUp(
          delayMs: 80,
          child: _AckCard(title: ack.title, steps: ack.steps, note: ack.note),
        ),
      if (details.replacementOffer case final offer?)
        KeyedSubtree(
          key: offerKey,
          child: OfferCard(
            offer: offer,
            onAnswered: () => unawaited(
              context.read<BookingDetailsCubit>().refresh(),
            ),
          ),
        ),
      FlowSectionTitle(l10n.bookingStayTitle),
      FlowRowsCard(
        children: [
          FlowDataRow(
            label: l10n.bookingArrival,
            value: DateOnlyFormatter.dayMonth(
              details.stay.checkIn,
              locale: locale,
            ),
          ),
          FlowDataRow(
            label: l10n.bookingDeparture,
            value: DateOnlyFormatter.dayMonth(
              details.stay.checkOut,
              locale: locale,
            ),
          ),
          FlowDataRow(label: l10n.bookingNights, value: '${details.nights}'),
          FlowDataRow(
            label: l10n.searchGuestsLabel,
            value: '${details.guests}',
          ),
          if (details.property.checkInTime != null)
            FlowDataRow(
              label: l10n.bookingCheckInTime,
              value: details.property.checkInTime!,
            ),
          if (details.property.checkOutTime != null)
            FlowDataRow(
              label: l10n.bookingCheckOutTime,
              value: details.property.checkOutTime!,
            ),
        ],
      ),
      KeyedSubtree(
        key: paymentsKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FlowSectionTitle(l10n.bookingPaymentsTitle),
            const SizedBox(height: Dimens.space12),
            FlowRowsCard(
              children: [
                FlowDataRow(
                  label: l10n.bookingTotal,
                  value: money.format(details.total),
                  emphasized: true,
                ),
                FlowDataRow(
                  label: l10n.bookingPaid,
                  value: money.format(details.paid),
                ),
                if (details.remaining.amountMinor > 0) ...[
                  FlowDataRow(
                    label: l10n.bookingRemaining,
                    value: money.format(details.remaining),
                    emphasized: true,
                  ),
                  if (details.remainingDueAt != null)
                    FlowDataRow(
                      label: l10n.bookingRemaining,
                      value: l10n.bookingRemainingDue(
                        DateOnlyFormatter.dayMonth(
                          // The due instant is UTC; its calendar day is
                          // Cairo's, like the remaining-payment screen.
                          DateOnly.fromDateTime(
                            CairoTime.inCairo(details.remainingDueAt!),
                          ),
                          locale: locale,
                        ),
                      ),
                    ),
                ],
                if (canPayRemaining)
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: Dimens.space4,
                    ),
                    child: FlowBanner(
                      icon: AppIcons.infoOutline,
                      message: l10n.remainingNote,
                      tone: FlowBannerTone.info,
                    ),
                  ),
                if (details.payments.isNotEmpty) ...[
                  const FlowRowDivider(),
                  for (final line in details.payments)
                    _PaymentLineTile(bookingId: details.id, line: line),
                ],
              ],
            ),
          ],
        ),
      ),
      // Section 5: the refund's own progress (US4).
      if (details.refund != null) RefundSection(refund: details.refund!),
      // Section 6: the damage claims (US5).
      if (details.damageClaims.isNotEmpty)
        KeyedSubtree(
          key: claimsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FlowSectionTitle(l10n.claimsSectionTitle),
              const SizedBox(height: Dimens.space12),
              for (final claim in details.damageClaims) ...[
                if (claim != details.damageClaims.first)
                  const SizedBox(height: Dimens.space8),
                _ClaimTile(
                  amount: money.format(claim.amount),
                  status: claimStatusLabel(claim.status, l10n),
                  tone: flowToneOf(claimStatusTone(claim.status)),
                  onTap: () => onOpenClaim(claim.id),
                ),
              ],
            ],
          ),
        ),
      if (details.property.addressText != null || instructions != null) ...[
        FlowSectionTitle(l10n.bookingAddressTitle),
        _AddressCard(
          address: details.property.addressText,
          instructions: instructions,
        ),
      ],
      if (details.termsSnapshot != null) ...[
        FlowSectionTitle(l10n.bookingSavedTermsTitle),
        FlowBulletCard(
          lines: [
            for (final line in policyLines(details.termsSnapshot!))
              policyLineText(line, l10n),
          ],
        ),
      ],
      if (details.events.isNotEmpty) ...[
        FlowSectionTitle(l10n.bookingTimelineTitle),
        FlowCard(
          child: _Timeline(
            entries: [
              for (final event in details.events)
                (
                  title: event.toStatus != null
                      ? bookingStatusLabel(event.toStatus!, l10n)
                      : l10n.bookingEventGeneric,
                  time: formatCairoDayMonthTime(
                    event.createdAt,
                    locale: locale,
                  ),
                ),
            ],
          ),
        ),
      ],
      if (secondary.isNotEmpty || hasSupport || hasCancel)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: Dimens.space8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final action in secondary) ...[
                FlowButton(
                  key: ValueKey('action-${action.value}'),
                  label: bookingActionLabel(action, l10n),
                  kind: FlowButtonKind.outlined,
                  onPressed: online ? () => onRun(action) : null,
                ),
                const SizedBox(height: Dimens.space8),
              ],
              if (hasSupport) ...[
                FlowButton(
                  key: const ValueKey('action-contact_support'),
                  label: l10n.bookingContactSupport,
                  kind: FlowButtonKind.outlined,
                  onPressed: online
                      ? () => context.push(
                          '${AppRoutes.supportNew}?booking=${details.id}',
                        )
                      : null,
                ),
                const SizedBox(height: Dimens.space8),
              ],
              if (hasCancel)
                FlowButton(
                  key: const ValueKey('action-request_cancellation'),
                  label: l10n.actionCancelBooking,
                  kind: FlowButtonKind.destructive,
                  onPressed: online
                      ? () => onRun(BookingActionCode.requestCancellation)
                      : null,
                ),
            ],
          ),
        ),
    ];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            Dimens.screenSide,
            Dimens.space4,
            Dimens.screenSide,
            Dimens.space24,
          ),
          // Built at once, not lazily: a deep link focuses the offer, claims
          // or payments section, which must exist to be scrolled to.
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: Dimens.space12),
                  sections[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.details});

  final BookingDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final palette = FlowPalette.of(context);
    final base = Theme.of(context).textTheme.bodyMedium!;
    return FlowCard(
      padding: const EdgeInsetsDirectional.all(Dimens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlowPropertyHeader(
            variants: details.property.coverImage?.variants ?? const [],
            title: details.property.title,
            subtitle: l10n.placeAreaCity(
              details.property.areaName,
              details.property.cityName,
            ),
          ),
          const SizedBox(height: Dimens.space12),
          Container(height: 1, color: palette.border2),
          const SizedBox(height: Dimens.space4),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: Dimens.space4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${l10n.bookingCode}:',
                      style: flowText(
                        context,
                        base: base,
                        size: 14,
                        weight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    // The code reads left to right inside Arabic text.
                    Text(
                      details.code,
                      textDirection: TextDirection.ltr,
                      style: flowText(
                        context,
                        base: base,
                        size: 14,
                        weight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.bookingCopyCode,
                color: palette.accent,
                icon: const Icon(AppIcons.copy, size: 20),
                onPressed: () {
                  unawaited(
                    Clipboard.setData(ClipboardData(text: details.code)),
                  );
                  showFlowSnack(context, l10n.bookingCodeCopied);
                },
              ),
            ],
          ),
          const SizedBox(height: Dimens.space4),
          // The refund chip sits next to the status chip only when the
          // server reported a refund (US4).
          Wrap(
            spacing: Dimens.space8,
            runSpacing: Dimens.space8,
            children: [
              FlowChip(
                label: bookingStatusLabel(details.status, l10n),
                tone: bookingFlowTone(details.status),
              ),
              if (details.refund != null)
                FlowChip(
                  label: refundStageLabel(details.refund!.stage, l10n),
                  tone: switch (details.refund!.stage) {
                    RefundStage.verified => FlowTone.success,
                    RefundStage.failed ||
                    RefundStage.cancelled ||
                    RefundStage.unknown => FlowTone.rejected,
                    _ => FlowTone.info,
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Check-in / check-out confirmation: you and the owner side by side, joined
/// by a line; a key note when the key was left in the safe.
final class _AckCard extends StatelessWidget {
  const _AckCard({required this.title, required this.steps, this.note});

  final String title;
  final List<AckStep> steps;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = FlowPalette.of(context);
    final base = Theme.of(context).textTheme.bodyMedium!;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: Dimens.space12),
          Expanded(
            child: Column(
              children: [
                FlowToneCircle(
                  icon: steps[i].done ? AppIcons.check : AppIcons.hourglass,
                  tone: steps[i].done ? FlowTone.success : FlowTone.cancelled,
                  size: 32,
                  iconSize: 18,
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  style: flowText(
                    context,
                    base: base,
                    size: 14,
                    weight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  steps[i].statusText,
                  textAlign: TextAlign.center,
                  style: flowText(
                    context,
                    base: base,
                    size: 13,
                    weight: FontWeight.w500,
                    height: 1.5,
                    color: steps[i].done
                        ? colors['success']
                        : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
    return MergeSemantics(
      child: FlowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: flowText(
                context,
                base: base,
                size: 16,
                weight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            if (steps.length == 2)
              Stack(
                children: [
                  PositionedDirectional(
                    top: 15,
                    start: 0,
                    end: 0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // From just past the first circle to just before
                        // the second.
                        final inset = constraints.maxWidth * 0.25 + 20;
                        return Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: inset,
                          ),
                          child: Container(height: 2, color: palette.border2),
                        );
                      },
                    ),
                  ),
                  row,
                ],
              )
            else
              row,
            if (note != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: Dimens.space12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: palette.highlight,
                  borderRadius: BorderRadius.circular(Dimens.radiusField),
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.keyOutline, size: 20, color: palette.badge),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note!,
                        style: flowText(
                          context,
                          base: base,
                          size: 14,
                          weight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One payment: method circle, method and time, amount and status. A cash
/// line with a receipt is one button that opens the receipt.
final class _PaymentLineTile extends StatelessWidget {
  const _PaymentLineTile({required this.bookingId, required this.line});

  final String bookingId;
  final PaymentLine line;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final palette = FlowPalette.of(context);
    final base = Theme.of(context).textTheme.bodyMedium!;
    final cash = line.method == 'cash';
    final hasReceipt = cash && line.receipt != null;
    final method = cash ? l10n.paymentMethodCash : l10n.paymentMethodCard;
    final (status, tone) = switch (line.status) {
      'succeeded' => (l10n.paymentLineSucceeded, FlowTone.success),
      'failed' ||
      'cancelled' ||
      'expired' => (l10n.paymentLineFailed, FlowTone.rejected),
      _ => (l10n.paymentLinePending, FlowTone.info),
    };
    final time = line.paidAt == null
        ? null
        : formatCairoDayMonthTime(line.paidAt!, locale: l10n.localeName);
    final amount = MoneyFormatter().format(line.amount);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final separator = l10n.localeName == 'ar' ? '، ' : ', ';
    return Semantics(
      button: hasReceipt,
      excludeSemantics: true,
      label: [
        method,
        amount,
        status,
        ?time,
        if (hasReceipt) l10n.receiptShow,
      ].join(separator),
      child: Material(
        color: colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimens.radiusField),
          onTap: hasReceipt
              ? () => context.push(AppRoutes.receipt(bookingId, line.id))
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: Dimens.space8,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors['cancelledBackground'],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cash ? AppIcons.cash : AppIcons.creditcard,
                      size: 20,
                      color: colors['cancelledText'],
                    ),
                  ),
                  const SizedBox(width: Dimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method,
                          style: flowText(
                            context,
                            base: base,
                            size: 14,
                            weight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (time != null)
                          Text(
                            time,
                            style: flowText(
                              context,
                              base: base,
                              size: 12,
                              weight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                        if (hasReceipt)
                          Text(
                            l10n.receiptShow,
                            style: flowText(
                              context,
                              base: base,
                              size: 13,
                              weight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimens.space8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        maxLines: 1,
                        style: flowText(
                          context,
                          base: base,
                          size: 14,
                          weight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: Dimens.space4),
                      FlowChip(label: status, tone: tone, dense: true),
                    ],
                  ),
                  if (hasReceipt)
                    Icon(
                      rtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
                      size: 22,
                      color: colors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ClaimTile extends StatelessWidget {
  const _ClaimTile({
    required this.amount,
    required this.status,
    required this.tone,
    required this.onTap,
  });

  final String amount;
  final String status;
  final FlowTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${l10n.claimTitle}: $amount، $status',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
          side: BorderSide(color: FlowPalette.of(context).border2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: Dimens.space16,
                vertical: Dimens.space12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: Dimens.space12,
                      runSpacing: Dimens.space8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          amount,
                          style: flowText(
                            context,
                            base: Theme.of(context).textTheme.bodyMedium,
                            size: 16,
                            weight: FontWeight.w800,
                            color: colors.textPrimary,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        FlowChip(label: status, tone: tone),
                      ],
                    ),
                  ),
                  Icon(
                    rtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
                    size: 22,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.instructions});

  final String? address;
  final String? instructions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final base = Theme.of(context).textTheme.bodyMedium!;
    return FlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (address != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    AppIcons.mapPin,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    address!,
                    style: flowText(
                      context,
                      base: base,
                      size: 14,
                      weight: FontWeight.w600,
                      height: 1.6,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          if (instructions != null) ...[
            if (address != null) ...[
              const SizedBox(height: Dimens.space12),
              Container(height: 1, color: FlowPalette.of(context).border2),
              const SizedBox(height: Dimens.space12),
            ],
            Text(
              l10n.bookingArrivalInstructions,
              style: flowText(
                context,
                base: base,
                size: 13,
                weight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: Dimens.space4),
            SelectableText(
              instructions!,
              style: flowText(
                context,
                base: base,
                size: 14,
                weight: FontWeight.w500,
                height: 1.7,
                color: colors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The booking's history, oldest first: the latest entry is the bold one
/// with the primary dot.
final class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries});

  final List<({String title, String time})> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = FlowPalette.of(context);
    final base = Theme.of(context).textTheme.bodyMedium!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      if (i == entries.length - 1)
                        const _LatestDot()
                      else
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: palette.border,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (i < entries.length - 1)
                        Expanded(
                          child: Container(width: 2, color: palette.border2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimens.space12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: i == entries.length - 1 ? 0 : 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].title,
                          style: flowText(
                            context,
                            base: base,
                            size: 14,
                            weight: i == entries.length - 1
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          entries[i].time,
                          style: flowText(
                            context,
                            base: base,
                            size: 12,
                            weight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The latest timeline dot: primary, with a halo that pulses three times
/// and then rests (never with reduced motion).
final class _LatestDot extends StatefulWidget {
  const _LatestDot();

  @override
  State<_LatestDot> createState() => _LatestDotState();
}

final class _LatestDotState extends State<_LatestDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    unawaited(_pulse());
  }

  Future<void> _pulse() async {
    for (var i = 0; i < 3 && mounted; i++) {
      await _controller.forward(from: 0).orCancel.catchError((_) {});
    }
    if (mounted) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.45 * (1 - t)),
                spreadRadius: 8 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The ready page's shape: header card, notice, a section title and rows.
final class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget fraction(double factor, double height) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: factor,
        child: FlowSkeletonBlock(height: height),
      ),
    );
    return FlowSkeletonScope(
      child: ListView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: Dimens.screenSide,
          vertical: Dimens.space8,
        ),
        children: [
          FlowCard(
            padding: const EdgeInsetsDirectional.all(Dimens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FlowSkeletonBlock(
                      width: 96,
                      height: 72,
                      radius: Dimens.radiusField,
                    ),
                    const SizedBox(width: Dimens.space12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(top: 6),
                        child: Column(
                          children: [
                            fraction(0.8, 16),
                            const SizedBox(height: Dimens.space8),
                            fraction(0.5, 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                fraction(0.6, 14),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    FlowSkeletonBlock(width: 96, height: 28),
                    SizedBox(width: Dimens.space8),
                    FlowSkeletonBlock(width: 72, height: 28),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimens.space12),
          const FlowSkeletonBlock(height: 72, radius: Dimens.radiusCard),
          const SizedBox(height: Dimens.space24),
          fraction(0.3, 18),
          const SizedBox(height: Dimens.space12),
          FlowCard(
            child: Column(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: fraction(0.6, 12)),
                      const SizedBox(width: Dimens.space24),
                      const Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FractionallySizedBox(
                            widthFactor: 0.56,
                            child: FlowSkeletonBlock(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
