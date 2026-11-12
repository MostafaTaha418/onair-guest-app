import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/core/time/date_only_formatter.dart';
import 'package:on_air/design_system/components/booking_flow_kit.dart';
import 'package:on_air/design_system/components/on_air_confirm_dialog.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
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
        final colors = context.colors;
        final locale = l10n.localeName;
        final base = Theme.of(context).textTheme.bodyMedium!;
        Widget line(IconData icon, String text, TextStyle style) => Row(
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 18, color: colors.textSecondary),
            ),
            const SizedBox(width: Dimens.space8),
            Expanded(child: Text(text, style: style)),
          ],
        );
        return FlowCard(
          borderColor: colors.primary,
          padding: const EdgeInsetsDirectional.all(Dimens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FlowChip(label: l10n.offerTitle, tone: FlowTone.badge),
              ),
              const SizedBox(height: Dimens.space12),
              FlowPropertyHeader(
                variants: offer.coverImage?.variants ?? const [],
                title: offer.propertyTitle,
                subtitle: offer.areaName,
              ),
              const SizedBox(height: Dimens.space12),
              line(
                AppIcons.dateRange,
                '${l10n.offerDates}: '
                '${DateOnlyFormatter.dayMonth(offer.stay.checkIn, locale: locale)} – '
                '${DateOnlyFormatter.dayMonth(offer.stay.checkOut, locale: locale)}',
                base.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              line(
                AppIcons.cash,
                offerDifferenceText(offer, l10n),
                base.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              if (pending && offer.expiresAt != null) ...[
                const SizedBox(height: 6),
                line(
                  AppIcons.schedule,
                  l10n.offerExpires(
                    formatCairoDayMonthTime(offer.expiresAt!, locale: locale),
                  ),
                  base.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: Dimens.space12),
              if (pending)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FlowButton(
                        key: const ValueKey('offer-decline'),
                        label: l10n.offerDecline,
                        kind: FlowButtonKind.outlined,
                        loading: busy && !state.accept,
                        onPressed: busy ? null : () => _decline(context),
                      ),
                    ),
                    const SizedBox(width: Dimens.space8),
                    Expanded(
                      child: FlowButton(
                        key: const ValueKey('offer-accept'),
                        label: l10n.offerAccept,
                        loading: busy && state.accept,
                        onPressed: busy ? null : () => _accept(context),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FlowChip(
                    label: switch (offer.status) {
                      OfferStatus.accepted => l10n.offerStatusAccepted,
                      OfferStatus.declined => l10n.offerStatusDeclined,
                      _ => l10n.offerStatusExpired,
                    },
                    tone: offer.status == OfferStatus.accepted
                        ? FlowTone.success
                        : FlowTone.cancelled,
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
                        color: colors.errorText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
