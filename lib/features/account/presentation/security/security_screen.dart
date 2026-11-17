import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:on_air/app/router/routes.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/on_air_confirm_sheet.dart';
import 'package:on_air/design_system/components/settings_row.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/account/domain/active_session.dart';
import 'package:on_air/features/account/presentation/security/security_cubit.dart';
import 'package:on_air/features/auth/domain/auth_state.dart';
import 'package:on_air/features/auth/presentation/auth_cubit.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

final class _SecurityScreenState extends State<SecurityScreen> {
  bool _confirmingAll = false;

  Future<void> _confirmEndOthers() async {
    if (_confirmingAll) return;
    _confirmingAll = true;
    final l10n = AppLocalizations.of(context);
    final accepted = await OnAirConfirmSheet.show<bool>(
      context,
      builder: (sheetContext) => OnAirConfirmSheet(
        title: l10n.accountEndOthers,
        body: l10n.accountEndOthersConfirm,
        confirmLabel: l10n.accountEndOthers,
        cancelLabel: l10n.supportKeepEditing,
        onConfirm: () => Navigator.of(sheetContext).pop(true),
      ),
    );
    _confirmingAll = false;
    if ((accepted ?? false) && mounted) {
      unawaited(context.read<SecurityCubit>().endOtherSessions());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    final auth = context.watch<AuthCubit>().state;
    final hasPassword = auth is SignedIn && auth.account.hasPassword;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSecurityRow)),
      body: BlocBuilder<SecurityCubit, SecurityState>(
        builder: (context, state) => switch (state) {
          SecurityLoading() => const LoadingView(),
          SecurityFailed(:final error) => ErrorView(
            message: apiErrorMessage(error, l10n),
            referenceNumber: error.requestId,
            onRetry: () => context.read<SecurityCubit>().load(),
          ),
          SecurityReady() => _ready(context, state, online, hasPassword),
        },
      ),
    );
  }

  Widget _ready(
    BuildContext context,
    SecurityReady state,
    bool online,
    bool hasPassword,
  ) {
    final l10n = AppLocalizations.of(context);
    final others = state.sessions.where((session) => !session.isCurrent);
    return ListView(
      padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
      children: [
        if (hasPassword) ...[
          SettingsGroup(
            children: [
              SettingsRow(
                key: const ValueKey('change-password-row'),
                icon: Icons.password_outlined,
                tone: SettingsIconTone.neutral,
                title: l10n.accountChangePassword,
                showChevron: true,
                enabled: online,
                onTap: () => context.push(AppRoutes.accountPassword),
              ),
            ],
          ),
          const SizedBox(height: Dimens.space24),
        ],
        Text(l10n.accountDevices, style: context.textStyles.sectionTitle),
        const SizedBox(height: Dimens.space8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < state.sessions.length; index++) ...[
                _SessionRow(
                  session: state.sessions[index],
                  ending: state.ending.contains(state.sessions[index].id),
                  enabled: online && !state.endingAll,
                  onEnd: () => unawaited(
                    context.read<SecurityCubit>().endSession(
                      state.sessions[index].id,
                    ),
                  ),
                ),
                if (index != state.sessions.length - 1)
                  const Divider(height: 1, indent: 64),
              ],
            ],
          ),
        ),
        if (state.error case final error?) ...[
          const SizedBox(height: Dimens.space12),
          Text(
            apiErrorMessage(error, l10n),
            key: const ValueKey('security-inline-error'),
            style: TextStyle(color: context.colors.errorText),
          ),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: Dimens.space24),
          OutlinedButton.icon(
            key: const ValueKey('end-other-sessions'),
            onPressed: online && !state.endingAll && state.ending.isEmpty
                ? _confirmEndOthers
                : null,
            icon: state.endingAll
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_outlined),
            label: Text(l10n.accountEndOthers),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.errorText,
              minimumSize: const Size.fromHeight(Dimens.minTouchTarget),
            ),
          ),
        ],
        const SizedBox(height: Dimens.space24),
      ],
    );
  }
}

final class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.ending,
    required this.enabled,
    required this.onEnd,
  });

  final ActiveSession session;
  final bool ending;
  final bool enabled;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = session.usesUnknownDeviceLabel
        ? l10n.accountUnknownDevice
        : session.deviceLabel;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.space12),
        child: Row(
          children: [
            Icon(_icon, size: 28, color: context.colors.textSecondary),
            const SizedBox(width: Dimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: Dimens.space8,
                    runSpacing: Dimens.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (session.isCurrent)
                        StatusChip(
                          key: const ValueKey('current-device-chip'),
                          label: l10n.accountThisDevice,
                          tone: StatusTone.info,
                        ),
                    ],
                  ),
                  const SizedBox(height: Dimens.space4),
                  Text(
                    l10n.accountLastActive(_relative(l10n)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!session.isCurrent)
              ending
                  ? const Padding(
                      padding: EdgeInsets.all(Dimens.space12),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      key: ValueKey('end-session-${session.id}'),
                      onPressed: enabled ? onEnd : null,
                      child: Text(l10n.accountEndSession),
                    ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (session.platform) {
    SessionPlatform.android => Icons.android_outlined,
    SessionPlatform.ios => Icons.phone_iphone_outlined,
    SessionPlatform.web => Icons.language_outlined,
    SessionPlatform.unknown => Icons.devices_other_outlined,
  };

  String _relative(AppLocalizations l10n) {
    final difference = DateTime.now().toUtc().difference(session.lastActiveAt);
    if (difference.inDays >= 7) {
      return l10n.notificationsWeeksAgo(difference.inDays ~/ 7);
    }
    if (difference.inDays >= 1) {
      return l10n.notificationsDaysAgo(difference.inDays);
    }
    if (difference.inHours >= 1) {
      return l10n.notificationsHoursAgo(difference.inHours);
    }
    return l10n.notificationsMinutesAgo(difference.inMinutes.clamp(0, 59));
  }
}
