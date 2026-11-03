import 'package:flutter/material.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
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
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: Dimens.space16,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors['subtleBorder']),
          ),
          child: Row(
            children: [
              Icon(AppIcons.search, size: 20, color: colors.textSecondary),
              const SizedBox(width: Dimens.space8),
              Expanded(
                child: Text(
                  l10n.homeSearchHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
