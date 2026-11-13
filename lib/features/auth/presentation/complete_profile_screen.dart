import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Temporary placeholder for the old completion step. The server now owns
/// account completeness (`profiles.status`), and US3 (S005) replaces the
/// route builder with «أكّد رقمك» (`ConfirmPhoneScreen`).
final class CompleteProfileScreen extends StatelessWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Dimens.screenSide),
          children: [
            const SizedBox(height: Dimens.space32),
            Text(
              l10n.authCompleteProfileTitle,
              key: const ValueKey('complete-profile-title'),
              style: context.textStyles.authTitle,
            ),
            const SizedBox(height: Dimens.space24),
            Text(l10n.authProfileIncomplete),
          ],
        ),
      ),
    );
  }
}
