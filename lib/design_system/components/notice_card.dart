import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// How a [NoticeCard] is painted: the neutral informational card, or the
/// warning tone for pauses the guest must act around (§4.3).
enum NoticeTone { neutral, warning }

/// A card for informational notices (status messages, hints) and warnings.
final class NoticeCard extends StatelessWidget {
  const NoticeCard({
    required this.icon,
    required this.message,
    this.tone = NoticeTone.neutral,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final NoticeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final warning = tone == NoticeTone.warning;
    return Material(
      color: warning ? colors['warningContainer'] : colors['detailCard'],
      borderRadius: BorderRadius.circular(Dimens.radiusCard),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.space12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: warning
                  ? colors['onWarningContainer']
                  : colors.textSecondary,
            ),
            const SizedBox(width: Dimens.space8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: warning
                      ? colors['onWarningContainer']
                      : colors.textPrimary,
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}
