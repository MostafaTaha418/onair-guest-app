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
import 'package:on_air/design_system/components/booking_flow_kit.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
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
      backgroundColor: context.colors.background,
      appBar: flowAppBar(
        context,
        title: l10n.bookingSummaryTitle,
        onBack: () => context.pop(),
      ),
      body: BlocBuilder<BookingFlowCubit, BookingFlowState>(
        builder: (context, state) {
          // AC-003: the server refused the start because the apartment is
          // gone. The fact lives in this booking's own flow cubit, so it
          // never leaks into another apartment's summary.
          if (state.load == FlowLoad.notAvailable) {
            return FlowStateView(
              icon: AppIcons.apartment,
              message: l10n.propertyNotAvailable,
              action: FlowButton(
                label: l10n.bookingsFindApartment,
                icon: AppIcons.search,
                expand: false,
                onPressed: () => context.go(AppRoutes.search),
              ),
            );
          }
          if (state.quote == null || state.property == null) {
            // The draft is gone (restart, expired branch): start from the
            // page.
            return FlowStateView(
              icon: AppIcons.history,
              message: l10n.bookingQuoteExpired,
              action: FlowButton(
                label: l10n.dialogBack,
                icon: AppIcons.arrowBackRounded,
                kind: FlowButtonKind.outlined,
                expand: false,
                onPressed: () => context.pop(),
              ),
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
    final locale = l10n.localeName;
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    final quote = flow.quote!;
    final property = flow.property!;
    final change = flow.pendingChange;
    final money = MoneyFormatter();
    bool changed(QuoteField field) =>
        change?.changedFields.contains(field) ?? false;
    String dueText(DateTime dueAt) => l10n.bookingRemainingDue(
      DateOnlyFormatter.dayMonth(DateOnly.fromDateTime(dueAt), locale: locale),
    );

    /// A money row; a changed one shows the old amount and counts up to the
    /// new one (both are server values — nothing is computed).
    FlowDataRow moneyRow(
      String label,
      QuoteField field,
      Money Function(BookingQuote quote) pick, {
      bool emphasized = false,
    }) {
      final now = pick(quote);
      final before = change == null ? null : pick(change.previous);
      return FlowDataRow(
        label: label,
        value: money.format(now),
        emphasized: emphasized,
        changed: changed(field),
        previous: before == null ? null : money.format(before),
        countUp: before == null
            ? null
            : FlowCountUp(
                from: before.amountMinor,
                to: now.amountMinor,
                format: (minor) => money.format(Money(minor)),
              ),
      );
    }

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Dimens.screenSide,
        Dimens.space8,
        Dimens.screenSide,
        Dimens.space24,
      ),
      children: _gap([
        if (!online) const FlowOfflineBanner(icon: AppIcons.wifiOff),
        if (change != null)
          FlowFadeUp(
            child: FlowBanner(
              icon: AppIcons.warningOutline,
              message: l10n.quoteChangedNotice,
              tone: FlowBannerTone.warning,
              liveRegion: true,
            ),
          ),
        if (flow.termsChanged)
          FlowFadeUp(
            delayMs: 40,
            child: FlowNoticeCard(
              icon: AppIcons.gavel,
              tone: FlowTone.warning,
              message: l10n.termsChangedNotice,
              action: _AgreeTermsButton(enabled: online),
            ),
          ),
        FlowFadeUp(
          delayMs: 80,
          child: FlowCard(
            padding: const EdgeInsetsDirectional.all(Dimens.space12),
            child: FlowPropertyHeader(
              variants: property.images.isEmpty
                  ? const []
                  : property.images.first.variants,
              title: property.title,
              subtitle: l10n.placeAreaCity(
                property.areaName,
                property.cityName,
              ),
            ),
          ),
        ),
        FlowFadeUp(
          delayMs: 120,
          child: FlowRowsCard(
            children: [
              FlowDataRow(
                label: l10n.searchDatesLabel,
                value:
                    '${DateOnlyFormatter.dayMonth(quote.stay.checkIn, locale: locale)} – '
                    '${DateOnlyFormatter.dayMonth(quote.stay.checkOut, locale: locale)}',
              ),
              FlowDataRow(label: l10n.bookingNights, value: '${quote.nights}'),
              FlowDataRow(
                label: l10n.searchGuestsLabel,
                value: '${quote.guests}',
              ),
              moneyRow(
                l10n.bookingNightlyPrice,
                QuoteField.nightly,
                (q) => q.nightly,
              ),
              const FlowRowDivider(),
              moneyRow(
                l10n.bookingTotal,
                QuoteField.total,
                (q) => q.total,
                emphasized: true,
              ),
              moneyRow(
                l10n.bookingPayNow,
                QuoteField.payNow,
                (q) => q.payNow,
                emphasized: true,
              ),
              if (!quote.isFullPayment) ...[
                moneyRow(
                  l10n.bookingRemaining,
                  QuoteField.remaining,
                  (q) => q.remaining,
                ),
                if (quote.remainingDueAt != null)
                  FlowDataRow(
                    label: l10n.bookingRemaining,
                    value: dueText(quote.remainingDueAt!),
                    changed: changed(QuoteField.remainingDueAt),
                    previous: change?.previous.remainingDueAt == null
                        ? null
                        : dueText(change!.previous.remainingDueAt!),
                  ),
              ],
            ],
          ),
        ),
        FlowFadeUp(
          delayMs: 160,
          child: FlowSectionTitle(l10n.bookingPolicyTitle),
        ),
        FlowFadeUp(
          delayMs: 200,
          // Changed terms show the reloaded property's lines — the quote may
          // still carry the old snapshot.
          child: FlowBulletCard(
            lines: [
              for (final line in policyLines(
                flow.termsChanged
                    ? property.policy
                    : (quote.policySummary ?? property.policy),
              ))
                policyLineText(line, l10n),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: Dimens.space4),
          child: FlowFadeUp(
            delayMs: 240,
            child: FlowBanner(
              icon: AppIcons.infoOutline,
              message: l10n.bookingSummaryOwnerNotice,
              tone: FlowBannerTone.info,
            ),
          ),
        ),
        BlocBuilder<PaymentAttemptCubit, PaymentAttemptState>(
          builder: (context, attempt) {
            final opened =
                attempt is AttemptOpened &&
                attempt.attempt.quoteId == quote.quoteId;
            if (!opened) return const SizedBox.shrink();
            return FlowFadeUp(
              child: FlowBanner(
                icon: AppIcons.creditcard,
                message: l10n.paymentReturnHint,
                tone: FlowBannerTone.info,
                action: FlowButton(
                  label: l10n.paymentCheckStatus,
                  kind: FlowButtonKind.outlined,
                  expand: false,
                  fontSize: 14,
                  onPressed: online
                      ? () => context.go(
                          AppRoutes.paymentReturn(
                            bookingId: attempt.attempt.bookingId,
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  /// 12dp between sections.
  List<Widget> _gap(List<Widget> children) => [
    for (var i = 0; i < children.length; i++) ...[
      if (i > 0) const SizedBox(height: Dimens.space12),
      children[i],
    ],
  ];
}

/// "Accept the new terms": spins while the fresh quote under the new terms
/// arrives; a second tap meanwhile is ignored.
final class _AgreeTermsButton extends StatefulWidget {
  const _AgreeTermsButton({required this.enabled});

  final bool enabled;

  @override
  State<_AgreeTermsButton> createState() => _AgreeTermsButtonState();
}

final class _AgreeTermsButtonState extends State<_AgreeTermsButton> {
  var _busy = false;

  Future<void> _agree() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<BookingFlowCubit>().acceptNewTerms();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FlowButton(
    key: const ValueKey('terms-accept-new'),
    label: AppLocalizations.of(context).termsAcceptNew,
    loading: _busy,
    onPressed: widget.enabled ? _agree : null,
  );
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
  /// stays disabled until it passes (AC-003), with the seconds left beside
  /// its label.
  Timer? _rateLimitTimer;
  var _cooldownSeconds = 0;

  @override
  void dispose() {
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  void _armRateLimit(Duration retryAfter) {
    _rateLimitTimer?.cancel();
    setState(
      () => _cooldownSeconds = (retryAfter.inMilliseconds / 1000).ceil(),
    );
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      }
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
        // AC-003: no pay button under the not-available view; none either
        // under the "start again" view.
        if (flow.load == FlowLoad.notAvailable ||
            quote == null ||
            flow.property == null) {
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
              showFlowSnack(context, apiErrorMessage(state.error, l10n));
            }
          },
          child: BlocBuilder<PaymentAttemptCubit, PaymentAttemptState>(
            builder: (context, attempt) {
              final online = context.watch<ConnectivityCubit>().state.isOnline;
              final cooldown = _cooldownSeconds;
              final base = Theme.of(context).textTheme.bodyMedium!;
              return FlowActionBar(
                child: flow.pendingChange != null
                    ? FlowButton(
                        key: const ValueKey('quote-confirm-new'),
                        label: l10n.quoteConfirmNew,
                        minHeight: 52,
                        fontSize: 16,
                        onPressed: online
                            ? widget.flowCubit.acceptChange
                            : null,
                      )
                    : FlowButton(
                        key: const ValueKey('summary-pay'),
                        label: l10n.bookingGoToPayment,
                        minHeight: 52,
                        fontSize: 16,
                        loading: attempt is AttemptStarting,
                        trailing: cooldown > 0
                            ? Text(
                                '· \u20660:${'$cooldown'.padLeft(2, '0')}\u2069',
                                style: base.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: FlowPalette.of(
                                    context,
                                  ).disabledForeground,
                                ),
                              )
                            : null,
                        onPressed:
                            online &&
                                attempt is! AttemptStarting &&
                                flow.canPay &&
                                cooldown == 0
                            ? () => widget.attemptCubit.pay(quote)
                            : null,
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
