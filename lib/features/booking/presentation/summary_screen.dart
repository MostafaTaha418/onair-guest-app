import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/date_only.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/booking/domain/booking_quote.dart';
import 'package:on_air/features/booking/domain/quote_change.dart';
import 'package:on_air/features/booking/presentation/booking_flow_cubit.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/property/domain/policy_text.dart';
import 'package:on_air/features/property/presentation/widgets/policy_line_text.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The booking summary: every figure comes from the server quote; the guest
/// confirms it and goes to the Kashier page.
final class SummaryScreen extends StatelessWidget {
  const SummaryScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final attemptCubit = context.read<PaymentAttemptCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookingSummaryTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          // AC-003: the server refused the start because the apartment is
          // gone. The fact lives in this booking's own flow cubit, so it
          // never leaks into another apartment's summary.
          if (state.load == FlowLoad.notAvailable) {
            return EmptyView(
              icon: Icons.home_outlined,
              message: l10n.propertyNotAvailable,
              action: OnAirPrimaryButton(
                label: l10n.bookingsFindApartment,
                onPressed: () => context.go(AppRoutes.search),
              ),
            );
          }
          final quote = state.quote;
          final property = state.property;
          if (quote == null || property == null) {
            // The draft is gone (restart, expired branch): start from the
            // page.
            return ErrorView(
              message: l10n.bookingQuoteExpired,
              onRetry: () => context.pop(),
            );
          }
          return _SummaryBody(flow: state);
        },
      ),
      bottomNavigationBar: _PayBar(
        propertyId: propertyId,
        attemptCubit: attemptCubit,
        flowCubit: context.read<BookingFlowCubit>(),
      ),
    );
  }
}

final class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.flow});

  final BookingFlowState flow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final quote = flow.quote!;
    final property = flow.property!;
    final change = flow.pendingChange;
    String? previousValue(QuoteField field) {
      if (change == null || !change.changedFields.contains(field)) return null;
      return switch (field) {
        QuoteField.nightly => MoneyFormatter().format(change.previous.nightly),
        QuoteField.total => MoneyFormatter().format(change.previous.total),
        QuoteField.payNow => MoneyFormatter().format(change.previous.payNow),
        QuoteField.remaining => MoneyFormatter().format(
          change.previous.remaining,
        ),
        QuoteField.remainingDueAt => l10n.bookingRemainingDue(
          DateOnlyFormatter.dayMonth(
            DateOnly.fromDateTime(change.previous.remainingDueAt!),
          ),
        ),
        // The hash itself has no row; it only blocks payment until accepted.
        QuoteField.termsHash => null,
      };
    }

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: colors.textPrimary,
    );
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        if (change != null) ...[
          InfoBanner(
            message: l10n.quoteChangedNotice,
            tone: StatusTone.warning,
          ),
          const SizedBox(height: Dimens.space12),
        ],
        if (flow.termsChanged) ...[
          NoticeCard(
            icon: Icons.history_edu,
            message: l10n.termsChangedNotice,
          ),
          const SizedBox(height: Dimens.space12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.radiusCard),
              child: SizedBox(
                width: 96,
                height: 72,
                child: OnAirNetworkImage(
                  variants: property.images.isEmpty
                      ? const []
                      : property.images.first.variants,
                ),
              ),
            ),
            const SizedBox(width: Dimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property.title, style: titleStyle),
                  Text(
                    '${property.areaName}، ${property.cityName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimens.space16),
        AmountRow(
          label: l10n.searchDatesLabel,
          value:
              '${DateOnlyFormatter.dayMonth(quote.stay.checkIn)} – '
              '${DateOnlyFormatter.dayMonth(quote.stay.checkOut)}',
        ),
        AmountRow(
          label: l10n.bookingNights,
          value: l10n.bookingNightsCount('${quote.nights}'),
        ),
        AmountRow(
          label: l10n.searchGuestsLabel,
          value: '${quote.guests}',
        ),
        AmountRow(
          label: l10n.bookingNightlyPrice,
          value: MoneyFormatter().format(quote.nightly),
          previousValue: previousValue(QuoteField.nightly),
          highlighted:
              change?.changedFields.contains(QuoteField.nightly) ?? false,
        ),
        AmountRow(
          label: l10n.bookingTotal,
          value: MoneyFormatter().format(quote.total),
          previousValue: previousValue(QuoteField.total),
          highlighted:
              change?.changedFields.contains(QuoteField.total) ?? false,
          emphasized: true,
        ),
        AmountRow(
          label: l10n.bookingPayNow,
          value: MoneyFormatter().format(quote.payNow),
          previousValue: previousValue(QuoteField.payNow),
          highlighted:
              change?.changedFields.contains(QuoteField.payNow) ?? false,
          emphasized: true,
        ),
        if (!quote.isFullPayment) ...[
          AmountRow(
            label: l10n.bookingRemaining,
            value: MoneyFormatter().format(quote.remaining),
            previousValue: previousValue(QuoteField.remaining),
            highlighted:
                change?.changedFields.contains(QuoteField.remaining) ?? false,
          ),
          if (quote.remainingDueAt != null)
            AmountRow(
              label: l10n.bookingRemaining,
              value: l10n.bookingRemainingDue(
                DateOnlyFormatter.dayMonth(
                  DateOnly.fromDateTime(quote.remainingDueAt!),
                ),
              ),
              previousValue: previousValue(QuoteField.remainingDueAt),
              highlighted:
                  change?.changedFields.contains(QuoteField.remainingDueAt) ??
                  false,
            ),
        ],
        const SizedBox(height: Dimens.space16),
        Text(l10n.bookingPolicyTitle, style: titleStyle),
        const SizedBox(height: Dimens.space8),
        // Changed terms show the reloaded property's lines — the quote may
        // still carry the old snapshot.
        for (final line in policyLines(
          flow.termsChanged
              ? property.policy
              : (quote.policySummary ?? property.policy),
        ))
          Text(policyLineText(line, l10n)),
        if (flow.termsChanged) ...[
          const SizedBox(height: Dimens.space12),
          OnAirPrimaryButton(
            key: const ValueKey('terms-accept-new'),
            label: l10n.termsAcceptNew,
            onPressed: () => context.read<BookingFlowCubit>().acceptNewTerms(),
          ),
        ],
        const SizedBox(height: Dimens.space16),
        InfoBanner(
          message: l10n.bookingSummaryOwnerNotice,
          tone: StatusTone.info,
        ),
      ],
    );
  }
}

final class _PayBar extends StatefulWidget {
  const _PayBar({
    required this.propertyId,
    required this.attemptCubit,
    required this.flowCubit,
  });

  final String propertyId;
  final PaymentAttemptCubit attemptCubit;
  final BookingFlowCubit flowCubit;

  @override
  State<_PayBar> createState() => _PayBarState();
}

final class _PayBarState extends State<_PayBar> {
  /// The server answered RATE_LIMITED with a retry-after: the pay button
  /// stays disabled until it passes (AC-003).
  Timer? _rateLimitTimer;
  var _rateLimited = false;

  @override
  void dispose() {
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  void _armRateLimit(Duration retryAfter) {
    _rateLimitTimer?.cancel();
    setState(() => _rateLimited = true);
    _rateLimitTimer = Timer(retryAfter, () {
      if (mounted) setState(() => _rateLimited = false);
    });
  }

  Future<void> _verifyThenPay(BookingQuote? quote) async {
    final context = this.context;
    final ok = await context.push<bool>(
      AppRoutes.bookingVerify(widget.propertyId, returnTo: 'summary'),
    );
    if (ok == true && context.mounted && quote != null) {
      await widget.attemptCubit.pay(quote);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<BookingFlowCubit, BookingFlowState>(
      builder: (context, flow) {
        final quote = flow.quote;
        // AC-003: no pay button under the not-available view.
        if (flow.load == FlowLoad.notAvailable) {
          return const SizedBox.shrink();
        }
        return BlocListener<PaymentAttemptCubit, PaymentAttemptState>(
          listener: (context, state) {
            if (state is! AttemptFailed) return;
            final code = state.error.code;
            if (code == ErrorCode.phoneNotVerified ||
                code == ErrorCode.emailNotVerified) {
              // US2: the server stopped the payment — verify on top of the
              // summary, then retry with the same attempt key.
              unawaited(_verifyThenPay(quote));
            } else if (code == ErrorCode.quoteExpired ||
                code == ErrorCode.termsChanged ||
                code == ErrorCode.propertyNotAvailable) {
              // US6 / AC-003: the flow cubit reacts silently — a fresh
              // quote, the new terms, or the not-available view appear on
              // the summary itself.
              unawaited(widget.flowCubit.onPaymentError(state.error));
            } else {
              if (code == ErrorCode.rateLimited &&
                  state.error.retryAfter != null) {
                _armRateLimit(state.error.retryAfter!);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(apiErrorMessage(state.error, l10n)),
                ),
              );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocBuilder<PaymentAttemptCubit, PaymentAttemptState>(
                builder: (context, attempt) {
                  final online = context
                      .read<ConnectivityCubit>()
                      .state
                      .isOnline;
                  final opened =
                      attempt is AttemptOpened &&
                      quote != null &&
                      attempt.attempt.quoteId == quote.quoteId;
                  return Column(
                    children: [
                      if (opened)
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: Dimens.screenSide,
                          ),
                          child: InfoBanner(
                            message: l10n.paymentReturnHint,
                            tone: StatusTone.info,
                            actionLabel: l10n.paymentCheckStatus,
                            onAction: () => context.go(
                              AppRoutes.paymentReturn(
                                bookingId: attempt.attempt.bookingId,
                              ),
                            ),
                          ),
                        ),
                      BottomActionBar(
                        leading: const SizedBox.shrink(),
                        action: flow.pendingChange != null
                            ? OnAirPrimaryButton(
                                key: const ValueKey('quote-confirm-new'),
                                label: l10n.quoteConfirmNew,
                                onPressed: widget.flowCubit.acceptChange,
                              )
                            : OnAirPrimaryButton(
                                key: const ValueKey('summary-pay'),
                                label: l10n.bookingGoToPayment,
                                isLoading: attempt is AttemptStarting,
                                onPressed:
                                    online &&
                                        attempt is! AttemptStarting &&
                                        flow.canPay &&
                                        quote != null &&
                                        !_rateLimited
                                    ? () => widget.attemptCubit.pay(quote)
                                    : null,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
