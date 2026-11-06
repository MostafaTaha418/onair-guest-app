import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/skeletons.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/booking/presentation/payment_attempt_cubit.dart';
import 'package:on_air/features/bookings/domain/booking_details.dart';
import 'package:on_air/features/stay/presentation/remaining_payment/remaining_payment_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class RemainingPaymentScreen extends StatefulWidget {
  const RemainingPaymentScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  State<RemainingPaymentScreen> createState() => _RemainingPaymentScreenState();
}

final class _RemainingPaymentScreenState extends State<RemainingPaymentScreen> {
  bool _cash = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<PaymentAttemptCubit, PaymentAttemptState>(
          listener: (context, state) {
            if (state is! AttemptFailed) return;
            if (state.error.code == ErrorCode.conflict) {
              context.go(
                AppRoutes.paymentReturn(bookingId: widget.bookingId),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(apiErrorMessage(state.error, l10n))),
            );
          },
        ),
        BlocListener<RemainingPaymentCubit, RemainingPaymentState>(
          listener: (context, state) {
            if (state is RemainingGoVerify) {
              context.go(
                AppRoutes.paymentReturn(bookingId: state.bookingId),
              );
            } else if (state is RemainingNotAllowed) {
              context.go(AppRoutes.bookingDetails(widget.bookingId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.stayStepNotAvailable)),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<RemainingPaymentCubit, RemainingPaymentState>(
        builder: (context, state) {
          final ready = state is RemainingReady ? state : null;
          final attemptState = context.watch<PaymentAttemptCubit>().state;
          return Scaffold(
            appBar: AppBar(title: Text(l10n.remainingTitle)),
            bottomNavigationBar: ready == null
                ? null
                : BottomActionBar(
                    leading: const SizedBox.shrink(),
                    action: _cash
                        ? OnAirPrimaryButton(
                            key: const ValueKey('remaining-cash'),
                            label: l10n.remainingCashButton,
                            onPressed: () => context.push(
                              AppRoutes.cashConfirm(ready.details.id),
                            ),
                          )
                        : OnAirPrimaryButton(
                            key: const ValueKey('remaining-pay'),
                            label: l10n.remainingPayButton(
                              MoneyFormatter().format(
                                ready.details.remaining,
                              ),
                            ),
                            isLoading: attemptState is AttemptStarting,
                            onPressed: attemptState is AttemptStarting
                                ? null
                                : () => context
                                      .read<PaymentAttemptCubit>()
                                      .payRemaining(ready.details.id),
                          ),
                  ),
            body: switch (state) {
              RemainingReady() => _ReadyBody(
                details: state.details,
                cashAllowed: state.cashAllowed,
                cashSelected: _cash,
                onCashChanged: (value) => setState(() => _cash = value),
              ),
              RemainingFailed() => ErrorView(
                message: apiErrorMessage(state.error, l10n),
                onRetry: context.read<RemainingPaymentCubit>().load,
                referenceNumber: state.error.requestId,
              ),
              RemainingOffline() => ErrorView(
                message: l10n.stayNeedsConnection,
                onRetry: context.read<RemainingPaymentCubit>().load,
              ),
              RemainingNotAvailable() => EmptyView(
                icon: AppIcons.infoOutline,
                message: l10n.notAvailable,
              ),
              _ => const _RemainingSkeleton(),
            },
          );
        },
      ),
    );
  }
}

final class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.details,
    required this.cashAllowed,
    required this.cashSelected,
    required this.onCashChanged,
  });

  final BookingDetails details;
  final bool cashAllowed;
  final bool cashSelected;
  final ValueChanged<bool> onCashChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PropertyRow(details: details),
                const SizedBox(height: Dimens.space16),
                Card(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(Dimens.space16),
                    child: Column(
                      children: [
                        AmountRow(
                          label: l10n.bookingTotal,
                          value: MoneyFormatter().format(details.total),
                        ),
                        AmountRow(
                          label: l10n.bookingPaid,
                          value: MoneyFormatter().format(details.paid),
                        ),
                        AmountRow(
                          label: l10n.bookingRemaining,
                          value: MoneyFormatter().format(details.remaining),
                          emphasized: true,
                        ),
                        if (details.remainingDueAt != null)
                          AmountRow(
                            label: l10n.remainingDueLabel,
                            value: formatCairoDayMonthTime(
                              details.remainingDueAt!,
                              locale: AppLocalizations.of(context).localeName,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.space16),
                InfoBanner(
                  message: l10n.remainingNote,
                  tone: StatusTone.info,
                ),
                if (cashAllowed) ...[
                  const SizedBox(height: Dimens.space16),
                  Text(
                    l10n.remainingChooseMethod,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Dimens.space8),
                  _OptionCard(
                    label: l10n.remainingOptionOnline,
                    selected: !cashSelected,
                    onTap: () => onCashChanged(false),
                  ),
                  const SizedBox(height: Dimens.space8),
                  _OptionCard(
                    label: l10n.remainingOptionCash,
                    selected: cashSelected,
                    onTap: () => onCashChanged(true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.details});

  final BookingDetails details;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        child: SizedBox(
          width: 64,
          height: 64,
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
              AppLocalizations.of(context).placeAreaCity(
                details.property.areaName,
                details.property.cityName,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: Card(
      color: selected
          ? context.colors['badgeNavActive']
          : context.colors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimens.radiusCard),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Dimens.minTouchTarget),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Dimens.space12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Icon(
                  selected
                      ? AppIcons.radioChecked
                      : AppIcons.radioButtonUnchecked,
                  color: selected
                      ? context.colors.primary
                      : context.colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class _RemainingSkeleton extends StatelessWidget {
  const _RemainingSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.all(Dimens.screenSide),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 64),
        SizedBox(height: Dimens.space16),
        SkeletonBox(height: 184),
        SizedBox(height: Dimens.space16),
        SkeletonBox(height: 72),
        SizedBox(height: Dimens.space16),
        SkeletonBox(height: 128),
      ],
    ),
  );
}
