import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/errors/api_error.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_confirm_dialog.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/stay/domain/cancellation_preview.dart';
import 'package:on_air/features/stay/presentation/cancellation/cancellation_cubit.dart';
import 'package:on_air/features/stay/presentation/cancellation/cancellation_texts.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class CancellationScreen extends StatelessWidget {
  const CancellationScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<CancellationCubit, CancellationState>(
      listener: (context, state) {
        if (state is CancelDone) {
          context.pop(true);
        } else if (state is CancelNotAllowed) {
          context.go(AppRoutes.bookingDetails(bookingId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.stayStepNotAvailable)),
          );
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l10n.cancelTitle)),
        bottomNavigationBar: switch (state) {
          CancelReady() => _CancelBar(preview: state.preview),
          CancelSubmitting() => _CancelBar(
            preview: state.from.preview,
            submitting: true,
          ),
          _ => null,
        },
        body: switch (state) {
          CancelReady() => _ReadyBody(state: state),
          CancelFailed() => ErrorView(
            message: apiErrorMessage(state.error, l10n),
            onRetry: context.read<CancellationCubit>().load,
            referenceNumber: state.error.requestId,
          ),
          CancelOffline() => ErrorView(
            message: l10n.stayNeedsConnection,
            onRetry: context.read<CancellationCubit>().load,
          ),
          CancelNotAvailable() => EmptyView(
            icon: AppIcons.infoOutline,
            message: l10n.notAvailable,
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

final class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state});

  final CancelReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = state.preview;
    final fmt = MoneyFormatter().format;
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.error?.code == ErrorCode.cancellationTermsChanged)
                  InfoBanner(
                    message: l10n.cancellationTermsChanged,
                    tone: StatusTone.warning,
                  ),
                const SizedBox(height: Dimens.space16),
                Card(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(Dimens.space16),
                    child: Column(
                      children: [
                        AmountRow(
                          label: l10n.cancelRefund,
                          value: fmt(preview.refund),
                          emphasized: true,
                          highlighted: state.changes.refund,
                          previousValue:
                              state.changes.refund && state.previous != null
                              ? fmt(state.previous!.refund)
                              : null,
                        ),
                        if (preview.nonRefundable.amountMinor > 0)
                          AmountRow(
                            label: l10n.cancelNonRefundable,
                            value: fmt(preview.nonRefundable),
                            highlighted: state.changes.nonRefundable,
                            previousValue:
                                state.changes.nonRefundable &&
                                    state.previous != null
                                ? fmt(state.previous!.nonRefundable)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.space16),
                NoticeCard(
                  icon: AppIcons.infoOutline,
                  message: cancellationSentence(preview, l10n),
                ),
                const SizedBox(height: Dimens.space16),
                Text(
                  l10n.cancelReasonTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Dimens.space8),
                Wrap(
                  spacing: Dimens.space8,
                  runSpacing: Dimens.space8,
                  children: [
                    for (final reason in CancellationReason.values)
                      ChoiceChip(
                        label: Text(_reasonLabel(reason, l10n)),
                        selected: state.reason == reason,
                        onSelected: (selected) => context
                            .read<CancellationCubit>()
                            .selectReason(selected ? reason : null),
                      ),
                  ],
                ),
                if (state.reason == CancellationReason.other) ...[
                  const SizedBox(height: Dimens.space8),
                  OnAirTextField(
                    hint: l10n.cancelReasonOtherHint,
                    onChanged: context.read<CancellationCubit>().setNote,
                    maxLength: CancellationReason.noteMaxLength,
                    maxLines: 3,
                  ),
                ],
                if (state.error != null &&
                    state.error!.code != ErrorCode.cancellationTermsChanged)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: Dimens.space16,
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
        ),
      ],
    );
  }

  String _reasonLabel(CancellationReason reason, AppLocalizations l10n) =>
      switch (reason) {
        CancellationReason.changeOfPlans => l10n.cancelReasonChangeOfPlans,
        CancellationReason.foundOtherPlace => l10n.cancelReasonFoundOther,
        CancellationReason.travelProblem => l10n.cancelReasonTravelProblem,
        CancellationReason.other => l10n.cancelReasonOther,
      };
}

/// The destructive action is never filled: it is the bar's only strong
/// action, outlined in the error colour instead (contracts §7).
final class _CancelBar extends StatelessWidget {
  const _CancelBar({required this.preview, this.submitting = false});

  final CancellationPreview preview;
  final bool submitting;

  Future<void> _confirm(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await OnAirConfirmDialog.ask(
      context,
      title: l10n.cancelDialogTitle,
      body: l10n.cancelDialogBody(
        MoneyFormatter().format(preview.refund),
      ),
      confirmLabel: l10n.cancelDialogConfirm,
      cancelLabel: l10n.dialogBack,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(context.read<CancellationCubit>().submit());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.space12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              key: const ValueKey('cancel-confirm'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.errorText,
                side: BorderSide(color: context.colors.errorText),
                minimumSize: const Size.fromHeight(Dimens.minTouchTarget),
              ),
              onPressed: submitting ? null : () => _confirm(context),
              child: submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.actionCancelBooking),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(64, Dimens.minTouchTarget),
              ),
              onPressed: () => context.pop(false),
              child: Text(l10n.cancelKeep),
            ),
          ],
        ),
      ),
    );
  }
}
