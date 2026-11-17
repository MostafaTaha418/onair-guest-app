import 'package:flutter/material.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

enum MessageAuthor { guest, onAir }

enum MessageSendState { sent, sending, failed }

final class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.author,
    required this.body,
    required this.time,
    this.attachments = const [],
    this.sendState = MessageSendState.sent,
    this.onRetry,
    super.key,
  });

  final MessageAuthor author;
  final String body;
  final DateTime time;
  final List<Widget> attachments;
  final MessageSendState sendState;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isGuest = author == MessageAuthor.guest;
    final authorLabel = isGuest ? l10n.ackYou : l10n.supportOnAir;
    final timeLabel = formatCairoTime(time);
    final foreground = isGuest ? colors.onPrimary : colors.textPrimary;
    return Semantics(
      container: true,
      label: '$authorLabel، $timeLabel: $body',
      child: Align(
        alignment: isGuest
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            margin: const EdgeInsetsDirectional.only(bottom: Dimens.space8),
            padding: const EdgeInsetsDirectional.all(Dimens.space12),
            decoration: BoxDecoration(
              color: isGuest ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(Dimens.radiusCard),
              border: isGuest ? null : Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isGuest)
                  Text(
                    l10n.supportOnAir,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (!isGuest) const SizedBox(height: Dimens.space4),
                Text(
                  body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: Dimens.space8),
                  Wrap(
                    spacing: Dimens.space8,
                    runSpacing: Dimens.space8,
                    children: attachments,
                  ),
                ],
                const SizedBox(height: Dimens.space4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isGuest
                            ? colors.onPrimary.withValues(alpha: .78)
                            : colors.textSecondary,
                      ),
                    ),
                    if (sendState == MessageSendState.sending) ...[
                      const SizedBox(width: Dimens.space4),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      ),
                    ],
                    if (sendState == MessageSendState.failed) ...[
                      const SizedBox(width: Dimens.space4),
                      Semantics(
                        button: true,
                        label: l10n.supportAttachRetry,
                        child: InkWell(
                          onTap: onRetry,
                          child: Icon(
                            Icons.refresh,
                            size: 18,
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
