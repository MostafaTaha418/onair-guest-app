import 'package:flutter/material.dart';
import 'package:on_air/design_system/components/status_chip.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/design_system/tokens/on_air_colors.dart';

/// A full-width information banner using the same token pairs as
/// [StatusChip], with an optional text button at the end.
final class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.info_outline,
    super.key,
  });

  final String message;
  final StatusTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  (Color, Color) _pair(OnAirColors colors) => switch (tone) {
    StatusTone.warning => (
      colors['warningContainer'],
      colors['onWarningContainer'],
    ),
    StatusTone.info => (colors['infoContainer'], colors['onInfoContainer']),
    StatusTone.pending => (colors['pendingBackground'], colors['pendingText']),
    StatusTone.success => (
      colors['successContainer'],
      colors['onSuccessContainer'],
    ),
    StatusTone.badge => (colors['badgeNavActive'], colors.primary),
    StatusTone.completed => (
      colors['completedBackground'],
      colors['completedText'],
    ),
    StatusTone.rejected => (
      colors['rejectedBackground'],
      colors['rejectedText'],
    ),
    StatusTone.cancelled => (
      colors['cancelledBackground'],
      colors['cancelledText'],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = _pair(colors);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.space12),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: Dimens.space8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foreground,
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
