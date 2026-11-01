import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// The tone of a status chip or banner; each maps to one background/text
/// token pair from Guest Plan §4.6 (light and dark come from the theme).
enum StatusTone {
  warning,
  info,
  pending,
  success,
  badge,
  completed,
  rejected,
  cancelled,
}

/// A pill-shaped status chip (Guest Plan §4.6). The color is never the only
/// signal: the label carries the meaning and an optional icon supports it.
final class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      StatusTone.warning => (
        colors['warningContainer'],
        colors['onWarningContainer'],
      ),
      StatusTone.info => (colors['infoContainer'], colors['onInfoContainer']),
      StatusTone.pending => (
        colors['pendingBackground'],
        colors['pendingText'],
      ),
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
    return Semantics(
      label: label,
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: Dimens.space8,
            vertical: Dimens.space4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
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
