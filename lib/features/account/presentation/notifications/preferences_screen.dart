import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_air/core/connectivity/connectivity_cubit.dart';
import 'package:on_air/core/errors/error_message.dart';
import 'package:on_air/design_system/components/info_banner.dart';
import 'package:on_air/design_system/components/settings_row.dart';
import 'package:on_air/design_system/components/state_views.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/account/domain/notification_preference.dart';
import 'package:on_air/features/account/presentation/notifications/preferences_cubit.dart';
import 'package:on_air/features/notifications/presentation/push_permission_coordinator.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountNotifications)),
      body: BlocBuilder<PreferencesCubit, PreferencesState>(
        builder: (context, state) => switch (state) {
          PreferencesLoading() => const LoadingView(),
          PreferencesFailed(:final error) => ErrorView(
            message: apiErrorMessage(error, l10n),
            referenceNumber: error.requestId,
            onRetry: context.read<PreferencesCubit>().load,
          ),
          PreferencesReady() => _ready(context, state),
        },
      ),
    );
  }

  Widget _ready(BuildContext context, PreferencesReady state) {
    final l10n = AppLocalizations.of(context);
    if (state.preferences.isEmpty) {
      return ErrorView(
        message: l10n.prefsUnavailable,
        onRetry: context.read<PreferencesCubit>().load,
      );
    }
    final online = context.watch<ConnectivityCubit>().state.isOnline;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
          children: [
            if (state.deviceNotificationsBlocked) ...[
              InfoBanner(
                key: const ValueKey('device-notifications-blocked'),
                message: l10n.prefsDeviceBlocked,
                actionLabel: l10n.prefsOpenSettings,
                tone: StatusTone.warning,
                icon: Icons.notifications_off_outlined,
                onAction: () => unawaited(
                  context.read<PushPermissionCoordinator>().enableFromNotice(),
                ),
              ),
              const SizedBox(height: Dimens.space16),
            ],
            if (state.failure != null) ...[
              InfoBanner(
                message: l10n.prefsSaveFailed,
                actionLabel: l10n.retry,
                tone: StatusTone.rejected,
                icon: Icons.sync_problem_outlined,
                onAction: () => unawaited(
                  context.read<PreferencesCubit>().retryFailure(),
                ),
              ),
              const SizedBox(height: Dimens.space16),
            ],
            for (var index = 0; index < state.preferences.length; index++) ...[
              _PreferenceGroup(
                preference: state.preferences[index],
                state: state,
                online: online,
              ),
              if (index != state.preferences.length - 1)
                const SizedBox(height: Dimens.space16),
            ],
            const SizedBox(height: Dimens.space24),
          ],
        ),
      ),
    );
  }
}

final class _PreferenceGroup extends StatelessWidget {
  const _PreferenceGroup({
    required this.preference,
    required this.state,
    required this.online,
  });

  final NotificationPreference preference;
  final PreferencesReady state;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsGroup(
      label: _categoryLabel(l10n, preference.labelKey),
      children: [
        if (preference.isMandatory)
          Padding(
            key: ValueKey('preference-lock-${preference.key}'),
            padding: const EdgeInsetsDirectional.fromSTEB(
              Dimens.space12,
              Dimens.space12,
              Dimens.space12,
              Dimens.space4,
            ),
            child: Semantics(
              label: l10n.prefsMandatoryLabel,
              container: true,
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 18),
                    const SizedBox(width: Dimens.space8),
                    Expanded(child: Text(l10n.prefsMandatory)),
                  ],
                ),
              ),
            ),
          ),
        for (final channel in NotificationChannel.values)
          if (preference.channels.containsKey(channel))
            _channelRow(context, channel),
      ],
    );
  }

  Widget _channelRow(BuildContext context, NotificationChannel channel) {
    final l10n = AppLocalizations.of(context);
    final key = PreferenceKey(preference.key, channel);
    final saving = state.saving.contains(key);
    final enabled = online && !preference.isMandatory && !saving;
    final title = channel == NotificationChannel.push
        ? l10n.prefsPush
        : l10n.prefsEmail;
    return SettingsRow(
      icon: channel == NotificationChannel.push
          ? Icons.notifications_outlined
          : Icons.email_outlined,
      title: title,
      enabled: enabled,
      locked: preference.isMandatory,
      trailing: Switch(
        key: ValueKey(
          'preference-switch-${preference.key}-${channel.name}',
        ),
        value: preference.enabled(channel),
        onChanged: enabled
            ? (value) => unawaited(
                context.read<PreferencesCubit>().toggle(
                  preference.key,
                  channel,
                  value,
                ),
              )
            : null,
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, String key) => switch (key) {
    'notifCategoryBooking' => l10n.notifCategoryBooking,
    'notifCategoryPayment' => l10n.notifCategoryPayment,
    'notifCategorySupport' => l10n.notifCategorySupport,
    'notifCategoryReminders' => l10n.notifCategoryReminders,
    'notifCategoryReview' => l10n.notifCategoryReview,
    'notifCategoryRefund' => l10n.notifCategoryRefund,
    'notifCategoryAccount' => l10n.notifCategoryAccount,
    _ => l10n.notifCategoryUnknown,
  };
}
