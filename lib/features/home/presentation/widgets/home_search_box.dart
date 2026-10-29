import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// A tappable search-field look-alike; it jumps to the Search tab.
final class HomeSearchBox extends StatelessWidget {
  const HomeSearchBox({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Semantics(
      label: l10n.homeSearchHint,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.radiusField),
        child: Container(
          padding: const EdgeInsetsDirectional.all(Dimens.space12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Dimens.radiusField),
            border: Border.all(color: colors['subtleBorder']),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: colors.textSecondary),
              const SizedBox(width: Dimens.space8),
              Expanded(
                child: Text(
                  l10n.homeSearchHint,
                  style: context.textStyles.homeSearch.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
