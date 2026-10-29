import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// A Home section heading.
final class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: Dimens.space12),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: context.colors.textPrimary,
      ),
    ),
  );
}

/// One Home section: the header plus its content, a skeleton while the
/// section loads, and a compact inline error with retry when the section
/// alone failed (FR-004).
final class HomeSection extends StatelessWidget {
  const HomeSection({
    required this.title,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.skeleton,
    required this.child,
    super.key,
  });

  final String title;
  final bool isLoading;

  /// The section error message, or null when the section is ready.
  final String? error;
  final VoidCallback onRetry;

  /// The loading placeholder, shaped like the section's content.
  final Widget skeleton;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        if (isLoading)
          skeleton
        else if (error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(Dimens.space12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(Dimens.radiusCard),
              border: Border.all(color: colors['subtleBorder']),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: colors.errorText,
                ),
                const SizedBox(width: Dimens.space8),
                Expanded(
                  child: Text(
                    l10n.errorUnexpectedNoRef,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          )
        else
          child,
      ],
    );
  }
}
