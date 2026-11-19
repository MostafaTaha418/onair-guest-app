import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/bottom_action_bar.dart';
import 'package:on_air/design_system/components/countdown_text.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_confirm_sheet.dart';
import 'package:on_air/design_system/components/on_air_otp_field.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/account/domain/deletion.dart';
import 'package:on_air/features/account/presentation/delete/account_deleted_notice.dart';
import 'package:on_air/features/account/presentation/delete/delete_account_cubit.dart';
import 'package:on_air/features/auth/phone_verification/domain/phone_verification_repository.dart';
import 'package:on_air/features/auth/phone_verification/presentation/widgets/send_window_notice.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// «حذف الحساب» (US4, contracts/ui-screens.md): explanation → blocked
/// reasons → email code → immediate deletion → visitor home.
final class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

final class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _sheetOpen = false;
  StreamController<Duration>? _countdown;
  Timer? _ticker;
  SendWindow? _countedWindow;

  void _retune(SendWindow window) {
    final counted = _countedWindow;
    if (counted != null &&
        window.nextSendAt == counted.nextSendAt &&
        window.blockedUntil == counted.blockedUntil) {
      return;
    }
    _countedWindow = window;
    _ticker?.cancel();
    unawaited(_countdown?.close());
    final controller = StreamController<Duration>.broadcast();
    // The window freezes the server↔device offset at arrival (R8), so the
    // tick just re-asks it.
    void tick() => controller.add(window.remainingUntilSend(DateTime.now()));
    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _countdown = controller;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_countdown?.close());
    super.dispose();
  }

  void _onStateChanged(BuildContext context, DeletionState state) {
    if (state is DeletionCodeStep) _retune(state.window);
    if (state is DeletionDeleted) {
      // One-shot: the extra exists only on this navigation (T070).
      context.go(AppRoutes.home, extra: const AccountDeletedNotice());
    }
  }

  Future<void> _confirmStart() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final l10n = AppLocalizations.of(context);
    final accepted = await OnAirConfirmSheet.show<bool>(
      context,
      builder: (sheetContext) => OnAirConfirmSheet(
        title: l10n.deleteCta,
        body: l10n.deleteFinal,
        confirmLabel: l10n.deleteUnderstand,
        cancelLabel: l10n.supportKeepEditing,
        onConfirm: () => Navigator.of(sheetContext).pop(true),
      ),
    );
    _sheetOpen = false;
    if ((accepted ?? false) && mounted) {
      unawaited(context.read<DeleteAccountCubit>().start());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteTitle)),
      body: BlocConsumer<DeleteAccountCubit, DeletionState>(
        listener: _onStateChanged,
        builder: (context, state) => switch (state) {
          DeletionExplain() => _explain(context, state, online),
          DeletionChecking() => const LoadingView(),
          DeletionBlocked() => _blocked(context, state, online),
          DeletionCodeStep() => _codeStep(context, state, online),
          DeletionDeleted() => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _bullet(BuildContext context, String message) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(
      vertical: Dimens.space4,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          AppIcons.errorOutline,
          size: 18,
          color: context.colors.errorText,
        ),
        const SizedBox(width: Dimens.space8),
        Expanded(child: Text(message)),
      ],
    ),
  );

  Widget _explain(
    BuildContext context,
    DeletionExplain state,
    bool online,
  ) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
            children: [
              Icon(
                Icons.delete_forever_outlined,
                size: 56,
                color: colors.errorText,
              ),
              const SizedBox(height: Dimens.space16),
              Text(l10n.deleteTitle, style: context.textStyles.sectionTitle),
              const SizedBox(height: Dimens.space16),
              _bullet(context, l10n.deleteWhatGoes),
              _bullet(context, l10n.deleteWhatStays),
              _bullet(context, l10n.deleteFinal),
              const SizedBox(height: Dimens.space16),
              Semantics(
                checked: state.understood,
                label: l10n.deleteUnderstand,
                child: InkWell(
                  key: const ValueKey('delete-understand'),
                  borderRadius: BorderRadius.circular(Dimens.radiusCard),
                  onTap: () => context.read<DeleteAccountCubit>().setUnderstood(
                    value: !state.understood,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: Dimens.space8,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: state.understood,
                          onChanged: (value) => context
                              .read<DeleteAccountCubit>()
                              .setUnderstood(value: value ?? false),
                        ),
                        const SizedBox(width: Dimens.space8),
                        Expanded(child: Text(l10n.deleteUnderstand)),
                      ],
                    ),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: Dimens.space8),
                Text(
                  apiErrorMessage(state.error!, l10n),
                  style: TextStyle(color: colors.errorText),
                ),
              ],
            ],
          ),
        ),
        BottomActionBar(
          leading: const SizedBox.shrink(),
          action: OnAirPrimaryButton(
            label: l10n.deleteCta,
            onPressed: state.understood && online ? _confirmStart : null,
          ),
        ),
      ],
    );
  }

  Widget _blocked(
    BuildContext context,
    DeletionBlocked state,
    bool online,
  ) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        NoticeCard(
          icon: Icons.block_outlined,
          message: l10n.deleteBlockedTitle,
        ),
        const SizedBox(height: Dimens.space16),
        for (final blocker in state.blockers) ...[
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(_blockerLabel(l10n, blocker)),
              trailing: Icon(
                Icons.chevron_right,
                textDirection: Directionality.of(context),
              ),
              onTap: blocker.id.isEmpty
                  ? null
                  : () => unawaitedGoBooking(context, blocker.id),
            ),
          ),
          const SizedBox(height: Dimens.space12),
        ],
        const SizedBox(height: Dimens.space8),
        TextButton(
          onPressed: () => context.push(AppRoutes.support),
          child: Text(l10n.whatsappContactSupport),
        ),
      ],
    );
  }

  /// Blockers tap to the booking they belong to (data-model §6: refund and
  /// claim blockers link to their booking id).
  Future<void> unawaitedGoBooking(BuildContext context, String id) async {
    await context.push(AppRoutes.bookingDetails(id));
  }

  String _blockerLabel(AppLocalizations l10n, DeletionBlocker blocker) =>
      switch (blocker.kind) {
        DeletionBlockerKind.booking => l10n.deleteBlockerBooking(blocker.code),
        DeletionBlockerKind.refund => l10n.deleteBlockerRefund(blocker.code),
        DeletionBlockerKind.damageClaim => l10n.deleteBlockerClaim(
          blocker.code,
        ),
        DeletionBlockerKind.other => blocker.code,
      };

  Widget _codeStep(
    BuildContext context,
    DeletionCodeStep state,
    bool online,
  ) {
    final l10n = AppLocalizations.of(context);
    final countdown = _countdown;
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        Text(l10n.deleteCodeSent(state.maskedEmail)),
        const SizedBox(height: Dimens.space24),
        OnAirOtpField(
          key: const ValueKey('delete-otp-field'),
          enabled: online && !state.verifying,
          onCompleted: (_) =>
              unawaited(context.read<DeleteAccountCubit>().confirm()),
          onChanged: context.read<DeleteAccountCubit>().updateCode,
        ),
        if (state.error != null) ...[
          const SizedBox(height: Dimens.space8),
          Semantics(
            liveRegion: true,
            child: Text(
              apiErrorMessage(state.error!, l10n),
              style: TextStyle(color: context.colors.errorText),
            ),
          ),
        ],
        const SizedBox(height: Dimens.space16),
        if (countdown != null)
          // The resend wait renders from the server's window (R8), the same
          // way the WhatsApp step does — CountdownText ticks per second.
          StreamBuilder<Duration>(
            stream: countdown.stream,
            builder: (context, snapshot) {
              final remaining = snapshot.hasData
                  ? snapshot.data!
                  : state.window.remainingUntilSend(DateTime.now());
              final counting = remaining > Duration.zero;
              return Center(
                child: TextButton(
                  key: const ValueKey('delete-resend'),
                  onPressed: counting || state.resending || !online
                      ? null
                      : () => unawaited(
                          context.read<DeleteAccountCubit>().resend(),
                        ),
                  child: counting
                      ? CountdownText(
                          remaining: countdown.stream,
                          format: (remaining) => l10n.whatsappResendIn(
                            formatSendWait(remaining, l10n),
                          ),
                        )
                      : Text(l10n.whatsappResend),
                ),
              );
            },
          ),
        const SizedBox(height: Dimens.space16),
        Text(l10n.deleteConfirm, style: context.textStyles.sectionTitle),
        const SizedBox(height: Dimens.space8),
        Text(l10n.deleteFinal),
        const SizedBox(height: Dimens.space16),
        SizedBox(
          height: Dimens.minTouchTarget,
          child: FilledButton(
            key: const ValueKey('delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors['destructive'],
              foregroundColor: context.colors.onPrimary,
            ),
            onPressed: state.canConfirm && online
                ? () => unawaited(context.read<DeleteAccountCubit>().confirm())
                : null,
            child: state.verifying
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.deleteConfirm),
          ),
        ),
      ],
    );
  }
}
