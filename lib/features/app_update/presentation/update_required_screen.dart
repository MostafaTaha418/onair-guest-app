import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/on_air_primary_button.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Blocking screen shown when the server reports the installed build is below
/// the minimum supported build. System back is disabled; the only way out is
/// updating through the store (server is the authority, Constitution II).
final class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({this.onOpenStore, super.key});

  /// Opens the store listing for the current platform. Null while the store
  /// listing is still provisional (iOS App Store id, research R14); the button
  /// then renders disabled instead of failing on tap.
  final VoidCallback? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: Dimens.screenSide,
              vertical: Dimens.space40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.system_update_alt,
                  size: 64,
                  color: colors['primary'],
                ),
                const SizedBox(height: Dimens.space24),
                Text(
                  l10n.updateRequiredTitle,
                  textAlign: TextAlign.center,
                  style: context.textStyles.sectionTitle.copyWith(
                    color: colors['textPrimary'],
                  ),
                ),
                const SizedBox(height: Dimens.space8),
                Text(
                  l10n.appUpdateRequired,
                  textAlign: TextAlign.center,
                  style: context.textStyles.authDescription.copyWith(
                    color: colors['textSecondary'],
                  ),
                ),
                const SizedBox(height: Dimens.space32),
                OnAirPrimaryButton(
                  label: l10n.updateRequiredStoreButton,
                  onPressed: onOpenStore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
