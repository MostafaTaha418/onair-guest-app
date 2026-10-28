import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

final class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.onSeeAll, super.key});
  final String title;
  final VoidCallback? onSeeAll;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: context.textStyles.sectionTitle.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ),
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          child: Text(
            AppLocalizations.of(context).seeAll,
            style: context.textStyles.seeAll.copyWith(
              color: context.colors['textAccent'],
            ),
          ),
        ),
    ],
  );
}
