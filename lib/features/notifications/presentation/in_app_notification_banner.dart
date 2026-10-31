import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_air/core/push/push_messages.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/features/notifications/presentation/notification_texts.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// The foreground push banner (US5): the type's title at the top of the
/// screen, auto-hidden after 4 seconds, tap opens the router location,
/// and the close button dismisses it.
final class InAppNotificationBanner extends StatefulWidget {
  const InAppNotificationBanner({
    required this.message,
    required this.onOpen,
    required this.onDismiss,
    super.key,
  });

  final PushMessage message;
  final ValueChanged<PushMessage> onOpen;
  final VoidCallback onDismiss;

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

final class _InAppNotificationBannerState
    extends State<InAppNotificationBanner> {
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _hideTimer = Timer(const Duration(seconds: 4), widget.onDismiss);
  }

  @override
  void didUpdateWidget(InAppNotificationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != oldWidget.message) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 4), widget.onDismiss);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = notificationText(widget.message.type, l10n);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.space8),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(Dimens.radiusCard),
          color: context.colors['detailCard'],
          child: InkWell(
            onTap: () => widget.onOpen(widget.message),
            borderRadius: BorderRadius.circular(Dimens.radiusCard),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Dimens.space12,
                Dimens.space8,
                Dimens.space4,
                Dimens.space8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: Dimens.space8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: context.colors.textPrimary),
                        ),
                        Text(
                          text.body,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    icon: const Icon(Icons.close),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
