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

/// How a [StatusChip] is drawn: the original filled pill, or the compact
/// list chip with a leading tone dot (My Bookings redesign, 2026-11).
enum StatusChipStyle { pill, dot }

/// A pill-shaped status chip (Guest Plan §4.6). The color is never the only
/// signal: the label carries the meaning and an optional icon supports it.
final class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon,
    this.style = StatusChipStyle.pill,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final StatusChipStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == StatusChipStyle.dot) return _DotChip(label: label, tone: tone);
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

/// The list chip: 8dp corners, a 6dp tone dot, 12/w700 label. "Pending" and
/// "completed" are outlined so they never read as "in progress" or
/// "confirmed". Warning and info labels use the primary text color (AA
/// contrast); the dot keeps the tone color.
final class _DotChip extends StatelessWidget {
  const _DotChip({required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? colors['textAccent'] : colors.primary;
    final clear = colors.transparent;
    // (text, dot, background, border)
    final (fg, dot, bg, border) = switch (tone) {
      StatusTone.success => (
        colors['success'],
        colors['success'],
        colors['completedBackground'],
        clear,
      ),
      StatusTone.warning => (
        colors.textPrimary,
        colors['warning'],
        colors['warningContainer'],
        clear,
      ),
      StatusTone.info => (
        colors.textPrimary,
        colors['info'],
        colors['infoContainer'],
        clear,
      ),
      StatusTone.pending => (ink, ink, clear, ink),
      StatusTone.badge => (ink, ink, colors['badgeNavActive'], clear),
      StatusTone.completed => (
        colors['success'],
        colors['success'],
        clear,
        colors.border,
      ),
      StatusTone.rejected => (
        colors['rejectedText'],
        colors['rejectedText'],
        colors['rejectedBackground'],
        clear,
      ),
      StatusTone.cancelled => (
        colors['cancelledText'],
        colors['cancelledText'],
        colors['cancelledBackground'],
        clear,
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: Dimens.space8,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(Dimens.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
