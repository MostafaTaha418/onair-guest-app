import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/core/money/money.dart';
import 'package:on_air/design_system/components/amount_row.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_confirm_dialog.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/on_air_text_field.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/stay/domain/damage_claim.dart';
import 'package:on_air/features/stay/presentation/claims/claim_texts.dart';
import 'package:on_air/features/stay/presentation/claims/damage_claim_cubit.dart';
import 'package:on_air/features/stay/presentation/claims/evidence_url_cache.dart';
import 'package:on_air/features/stay/presentation/claims/evidence_viewer.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class DamageClaimScreen extends StatefulWidget {
  const DamageClaimScreen({
    required this.bookingId,
    required this.claimId,
    super.key,
  });

  final String bookingId;
  final String claimId;

  @override
  State<DamageClaimScreen> createState() => _DamageClaimScreenState();
}

final class _DamageClaimScreenState extends State<DamageClaimScreen> {
  late final EvidenceUrlCache _urls = EvidenceUrlCache(
    context.read(),
  );
  final TextEditingController _note = TextEditingController();

  /// Set once the server accepted the guest's answer. Going back then pops
  /// `true`, so booking details fetches the claim's new status and drops
  /// the «respond» action instead of showing a stale «waiting for you».
  var _answered = false;
  var _submitted = false;

  @override
  void dispose() {
    // Evidence URLs are memory-only and die with the screen.
    _urls.clear();
    _note.dispose();
    super.dispose();
  }

  void _agree() {
    final cubit = context.read<DamageClaimCubit>();
    final ready = cubit.state;
    if (ready is! ClaimReady) return;
    unawaited(() async {
      final l10n = AppLocalizations.of(context);
      final agreed = await OnAirConfirmDialog.ask(
        context,
        title: l10n.claimAgreeDialogTitle,
        body: l10n.claimAgreeDialogBody(
          MoneyFormatter().format(ready.claim.amount),
        ),
        confirmLabel: l10n.dialogConfirm,
        cancelLabel: l10n.dialogBack,
      );
      if (!agreed) return;
      unawaited(cubit.agree());
    }());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<DamageClaimCubit, ClaimState>(
      // After a submit the cubit reloads (submitting → loading → ready), so
      // the answer is detected on the first ready state that follows a
      // submit, not on a direct submitting → ready step.
      listener: (context, state) {
        if (state is ClaimSubmitting) {
          _submitted = true;
        } else if (_submitted &&
            state is ClaimReady &&
            state.claim.response != null &&
            !_answered) {
          setState(() => _answered = true);
        }
      },
      builder: (context, state) {
        final ready = state is ClaimReady
            ? state
            : state is ClaimSubmitting
            ? state.from
            : null;
        final submitting = state is ClaimSubmitting;
        return PopScope<Object?>(
          canPop: !_answered,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _answered) Navigator.of(context).pop(true);
          },
          child: Scaffold(
            appBar: AppBar(title: Text(l10n.claimTitle)),
            bottomNavigationBar: ready == null || !ready.canRespond
                ? null
                : ready.disputeOpen
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(Dimens.space12),
                      child: OutlinedButton(
                        key: const ValueKey('claim-send-dispute'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.errorText,
                          side: BorderSide(color: context.colors.errorText),
                          minimumSize: const Size.fromHeight(
                            Dimens.minTouchTarget,
                          ),
                        ),
                        onPressed: submitting
                            ? null
                            : () => context.read<DamageClaimCubit>().dispute(
                                _note.text,
                              ),
                        child: Text(l10n.claimDisputeSend),
                      ),
                    ),
                  )
                : BottomActionBar(
                    leading: OutlinedButton(
                      key: const ValueKey('claim-dispute'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.errorText,
                        side: BorderSide(color: context.colors.errorText),
                        minimumSize: const Size.fromHeight(
                          Dimens.minTouchTarget,
                        ),
                      ),
                      onPressed: submitting
                          ? null
                          : () =>
                                context.read<DamageClaimCubit>().openDispute(),
                      child: Text(l10n.claimDispute),
                    ),
                    action: OnAirPrimaryButton(
                      key: const ValueKey('claim-agree'),
                      label: l10n.claimAgree,
                      isLoading: submitting,
                      onPressed: submitting ? null : _agree,
                    ),
                  ),
            body: switch (state) {
              ClaimReady() || ClaimSubmitting() => _ReadyBody(
                state: ready!,
                urls: _urls,
                noteController: _note,
              ),
              ClaimFailed() => ErrorView(
                message: apiErrorMessage(state.error, l10n),
                onRetry: context.read<DamageClaimCubit>().load,
                referenceNumber: state.error.requestId,
              ),
              ClaimOffline() => ErrorView(
                message: l10n.stayNeedsConnection,
                onRetry: context.read<DamageClaimCubit>().load,
              ),
              ClaimNotAvailable() => EmptyView(
                icon: AppIcons.infoOutline,
                message: l10n.notAvailable,
              ),
              // Loading: the shared skeleton, never a blank page.
              _ => const LoadingView(),
            },
          ),
        );
      },
    );
  }
}

final class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.state,
    required this.urls,
    required this.noteController,
  });

  final ClaimReady state;
  final EvidenceUrlCache urls;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final claim = state.claim;
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The protection notice is always first (contracts §8).
                InfoBanner(
                  message: l10n.claimProtection,
                  tone: StatusTone.cancelled,
                ),
                const SizedBox(height: Dimens.space16),
                Card(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(Dimens.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(
                          label: claimStatusLabel(claim.status, l10n),
                          tone: claimStatusTone(claim.status),
                        ),
                        const SizedBox(height: Dimens.space8),
                        Text(
                          claim.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.colors.textPrimary),
                        ),
                        const SizedBox(height: Dimens.space8),
                        AmountRow(
                          label: l10n.claimAmount,
                          value: MoneyFormatter().format(claim.amount),
                          emphasized: true,
                        ),
                      ],
                    ),
                  ),
                ),
                if (claim.evidence.isNotEmpty) ...[
                  const SizedBox(height: Dimens.space16),
                  Text(
                    l10n.claimEvidence,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Dimens.space8),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: claim.evidence.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: Dimens.space8),
                      itemBuilder: (context, index) => _Thumb(
                        evidence: claim.evidence,
                        index: index,
                        urls: urls,
                      ),
                    ),
                  ),
                ],
                if (claim.response != null) ...[
                  const SizedBox(height: Dimens.space16),
                  NoticeCard(
                    icon: AppIcons.checkCircleOutline,
                    message:
                        '${l10n.claimYourAnswer}: '
                        '${claimStatusLabel(claim.status, l10n)}',
                  ),
                  if (claim.supportCaseNumber != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: Dimens.space8,
                      ),
                      child: SelectableText(
                        l10n.claimCaseNumber(claim.supportCaseNumber!),
                      ),
                    ),
                ],
                if (claim.resolution != null) ...[
                  const SizedBox(height: Dimens.space16),
                  NoticeCard(
                    icon: AppIcons.infoOutline,
                    message: claimOutcomeText(claim.resolution!, l10n),
                  ),
                ],
                if (state.disputeOpen) ...[
                  const SizedBox(height: Dimens.space16),
                  OnAirTextField(
                    controller: noteController,
                    label: l10n.claimDisputeReason,
                    hint: l10n.claimDisputeReasonHint,
                    errorText: state.noteError
                        ? l10n.claimDisputeTooShort
                        : null,
                    maxLength: ClaimLimits.disputeMax,
                    maxLines: 5,
                  ),
                ],
                if (state.error != null)
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
}

final class _Thumb extends StatefulWidget {
  const _Thumb({
    required this.evidence,
    required this.index,
    required this.urls,
  });

  final List<EvidenceRef> evidence;
  final int index;
  final EvidenceUrlCache urls;

  @override
  State<_Thumb> createState() => _ThumbState();
}

final class _ThumbState extends State<_Thumb> {
  EvidenceRef get _ref => widget.evidence[widget.index];

  late Future<Uri> _future = widget.urls.urlFor(_ref.attachmentId);

  void _retry() {
    widget.urls.invalidate(_ref.attachmentId);
    setState(() {
      _future = widget.urls.urlFor(_ref.attachmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 96,
      height: 96,
      child: Semantics(
        button: true,
        label: l10n.claimEvidencePhoto(
          '${widget.index + 1}',
          '${widget.evidence.length}',
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => EvidenceViewer(
                evidence: widget.evidence,
                initialIndex: widget.index,
                cache: widget.urls,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimens.radiusField),
            child: FutureBuilder<Uri>(
              future: _future,
              builder: (context, snapshot) {
                final uri = snapshot.data;
                if (uri == null) {
                  if (snapshot.hasError) {
                    return _ThumbError(onRetry: _retry);
                  }
                  return ColoredBox(
                    color: context.colors['detailCard'],
                    child: const SizedBox.expand(),
                  );
                }
                return Image.network(
                  uri.toString(),
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  cacheWidth: (96 * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  errorBuilder: (_, _, _) => _ThumbError(onRetry: _retry),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _ThumbError extends StatelessWidget {
  const _ThumbError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors['detailCard'],
    child: SizedBox.expand(
      child: Tooltip(
        message: AppLocalizations.of(context).claimPhotoFailed,
        child: IconButton(
          tooltip: AppLocalizations.of(context).claimPhotoFailed,
          onPressed: onRetry,
          icon: const Icon(AppIcons.imageNotSupportedOutlined),
        ),
      ),
    ),
  );
}
