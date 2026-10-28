import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// G4 entry point until support ships (research R10).
final class SupportEntryPlaceholderScreen extends StatelessWidget {
  const SupportEntryPlaceholderScreen({this.propertyId, super.key});

  final String? propertyId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportEntryTitle)),
      body: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.space16),
        child: Text(
          l10n.supportEntryComingSoon,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
