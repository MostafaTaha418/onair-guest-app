import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/on_air_confirm_dialog.dart';
import 'package:on_air/design_system/components/on_air_network_image.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/bookings/domain/booking_stay_parts.dart';
import 'package:on_air/features/stay/presentation/offer/replacement_offer_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The difference sentence in plain language (contracts §9).
String offerDifferenceText(ReplacementOffer offer, AppLocalizations l10n) =>
    switch (offer.direction) {
      OfferDirection.guestPays => l10n.offerPayMore(
        MoneyFormatter().format(offer.difference),
      ),
      OfferDirection.guestRefunded => l10n.offerRefundDiff(
        MoneyFormatter().format(offer.difference),
      ),
      OfferDirection.none => l10n.offerNoDiff,
    };

final class OfferCard extends StatelessWidget {
  const OfferCard({
    required this.offer,
    required this.onAnswered,
    super.key,
  });

  final ReplacementOffer offer;
  final VoidCallback onAnswered;

  @override
  Widget build(BuildContext context) => BlocProvider<ReplacementOfferCubit>(
    create: (context) => ReplacementOfferCubit(
      stay: context.read(),
      attempts: context.read(),
      logger: context.read(),
      offerId: offer.id,
    ),
    child: _OfferCardBody(offer: offer, onAnswered: onAnswered),
  );
}

final class _OfferCardBody extends StatelessWidget {
  const _OfferCardBody({required this.offer, required this.onAnswered});

  final ReplacementOffer offer;
  final VoidCallback onAnswered;

  Future<void> _accept(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await OnAirConfirmDialog.ask(
      context,
      title: l10n.offerAcceptDialogTitle,
      body: offerDifferenceText(offer, l10n),
      confirmLabel: l10n.dialogConfirm,
      cancelLabel: l10n.dialogBack,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(context.read<ReplacementOfferCubit>().accept());
  }

  Future<void> _decline(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await OnAirConfirmDialog.ask(
      context,
      title: l10n.offerDeclineDialogTitle,
      body: l10n.offerDeclineDialogBody,
      confirmLabel: l10n.dialogConfirm,
      cancelLabel: l10n.dialogBack,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(context.read<ReplacementOfferCubit>().decline());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<ReplacementOfferCubit, ReplacementOfferState>(
      listener: (context, state) {
        if (state is OfferAnswered) {
          onAnswered();
        } else if (state is OfferGone) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.offerNotAvailable)),
          );
          onAnswered();
        }
      },
      builder: (context, state) {
        final pending = offer.status == OfferStatus.pending;
        final busy = state is OfferSubmitting;
        return Card(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Dimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.offerTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Dimens.space12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimens.radiusChip),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: OnAirNetworkImage(
                          variants: offer.coverImage?.variants ?? const [],
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.propertyTitle,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: context.colors.textPrimary,
                                ),
                          ),
                          Text(
                            offer.areaName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.space12),
                AmountRow(
                  label: l10n.offerDates,
                  value:
                      '${DateOnlyFormatter.dayMonth(offer.stay.checkIn, locale: AppLocalizations.of(context).localeName)} – '
                      '${DateOnlyFormatter.dayMonth(offer.stay.checkOut, locale: AppLocalizations.of(context).localeName)}',
                ),
                const SizedBox(height: Dimens.space8),
                InfoBanner(
                  message: offerDifferenceText(offer, l10n),
                  tone: switch (offer.direction) {
                    OfferDirection.guestRefunded => StatusTone.info,
                    OfferDirection.guestPays => StatusTone.warning,
                    OfferDirection.none => StatusTone.cancelled,
                  },
                ),
                if (pending) ...[
                  if (offer.expiresAt != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: Dimens.space8,
                      ),
                      child: Text(
                        l10n.offerExpires(
                          formatCairoDayMonthTime(
                            offer.expiresAt!,
                            locale: AppLocalizations.of(context).localeName,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: Dimens.space12),
                  OnAirPrimaryButton(
                    key: const ValueKey('offer-accept'),
                    label: l10n.offerAccept,
                    isLoading: busy && state.accept,
                    onPressed: busy ? null : () => _accept(context),
                  ),
                  const SizedBox(height: Dimens.space8),
                  OutlinedButton(
                    key: const ValueKey('offer-decline'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(Dimens.minTouchTarget),
                    ),
                    onPressed: busy ? null : () => _decline(context),
                    child: Text(l10n.offerDecline),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: Dimens.space8,
                    ),
                    child: StatusChip(
                      label: switch (offer.status) {
                        OfferStatus.accepted => l10n.offerStatusAccepted,
                        OfferStatus.declined => l10n.offerStatusDeclined,
                        _ => l10n.offerStatusExpired,
                      },
                      tone: offer.status == OfferStatus.accepted
                          ? StatusTone.completed
                          : StatusTone.cancelled,
                    ),
                  ),
                if (state is OfferIdle && state.error != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: Dimens.space8,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        apiErrorMessage(state.error!, l10n),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.errorText,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
