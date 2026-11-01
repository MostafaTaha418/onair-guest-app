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
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/booking_timeline.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_action.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/bookings/domain/booking_parts.dart';
import 'package:on_air/features/bookings/presentation/booking_details_cubit.dart';
import 'package:on_air/features/bookings/presentation/booking_status_ui.dart';
import 'package:on_air/features/bookings/presentation/widgets/refund_section.dart';
import 'package:on_air/features/property/domain/policy_text.dart';
import 'package:on_air/features/property/presentation/widgets/policy_line_text.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// One booking's full view (US3): status message, payments, saved terms,
/// timeline, arrival instructions, and only the server-allowed actions.
final class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingDetailsCubit>();
    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<BookingDetailsCubit, BookingDetailsState>(
        builder: (context, state) => switch (state) {
          DetailsLoading() => const _DetailsSkeleton(),
          DetailsNotAvailable() => EmptyView(
            icon: Icons.info_outline,
            message: AppLocalizations.of(context).notAvailable,
          ),
          DetailsFailed() => ErrorView(
            message: apiErrorMessage(state.error, AppLocalizations.of(context)),
            onRetry: cubit.load,
            referenceNumber: state.error.requestId,
          ),
          DetailsOffline() => ErrorView(
            message: AppLocalizations.of(context).offline,
            onRetry: cubit.load,
          ),
          DetailsReady() => RefreshIndicator(
            onRefresh: cubit.refresh,
            child: _DetailsList(state: state),
          ),
        },
      ),
    );
  }
}

final class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.state});

  final DetailsReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    final details = state.details;
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
                icon: Icons.info_outline,
                message: bookingStatusMessage(details, l10n),
              ),
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
              for (final line in details.payments) ...[
                const SizedBox(height: Dimens.space4),
                AmountRow(
                  label: _methodLabel(line, l10n),
                  value: _lineValue(line, l10n),
                ),
              ],
              // Section 5: the refund's own progress (US4).
              if (details.refund != null) ...[
                const SizedBox(height: Dimens.space16),
                RefundSection(refund: details.refund!),
              ],
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
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: Dimens.space8,
                  ),
                  child: OutlinedButton(
                    key: ValueKey('action-${action.value}'),
                    onPressed: online
                        ? () => context.push(
                            '${AppRoutes.supportNew}?booking=${details.id}',
                          )
                        : null,
                    child: Text(l10n.bookingContactSupport),
                  ),
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
                icon: const Icon(Icons.copy),
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
