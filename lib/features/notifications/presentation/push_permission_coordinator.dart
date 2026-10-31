import 'package:flutter/material.dart';
import 'package:on_air/core/push/notification_permission.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/account_gate/application/device_registration_service.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// US5: the push-permission sheet appears once, right after the first
/// successful payment (T093). «Later» also counts as asked — the sheet
/// never nags a second time.
final class PushPermissionCoordinator {
  PushPermissionCoordinator({
    required this._permission,
    required this._devices,
    Future<SharedPreferences> Function()? prefs,
  }) : _prefs = prefs ?? SharedPreferences.getInstance;

  static const askedKey = 'push_permission_asked';

  final NotificationPermission _permission;
  final DeviceRegistrationService? _devices;
  final Future<SharedPreferences> Function() _prefs;

  Future<void> maybeAskAfterFirstSuccess(BuildContext context) async {
    final prefs = await _prefs();
    if (prefs.getBool(askedKey) ?? false) return;
    final status = await _permission.status();
    if (status != PushPermission.notDetermined) return;
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final enable = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Dimens.screenSide),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.pushPermissionTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: Dimens.space8),
                NoticeCard(
                  icon: Icons.notifications_active_outlined,
                  message: l10n.pushPermissionBody,
                ),
                const SizedBox(height: Dimens.space16),
                OnAirPrimaryButton(
                  key: const ValueKey('push-enable'),
                  label: l10n.pushPermissionEnable,
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                ),
                const SizedBox(height: Dimens.space8),
                TextButton(
                  key: const ValueKey('push-later'),
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: Text(l10n.pushPermissionLater),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await prefs.setBool(askedKey, true);
    if (enable != true) return;
    final result = await _permission.request();
    if (result == PushPermission.granted) {
      await _devices?.registerAfterSignIn();
    }
  }

  /// FR-030: the persistent «Notifications are off» notice in the center.
  /// A `notDetermined` status counts once the sheet was shown (and «Later»
  /// was chosen) — on iOS there is no settings switch before the first ask.
  Future<bool> shouldShowOffNotice() async {
    final status = await _permission.status();
    if (status == PushPermission.denied) return true;
    if (status != PushPermission.notDetermined) return false;
    final prefs = await _prefs();
    return prefs.getBool(askedKey) ?? false;
  }

  /// The off-notice action: an unasked permission is requested now; a
  /// denied one needs the OS settings page.
  Future<void> enableFromNotice() async {
    final status = await _permission.status();
    if (status != PushPermission.notDetermined) {
      await _permission.openSettings();
      return;
    }
    final result = await _permission.request();
    if (result == PushPermission.granted) {
      await _devices?.registerAfterSignIn();
    }
  }
}
