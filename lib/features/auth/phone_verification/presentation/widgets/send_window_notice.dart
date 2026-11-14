import 'package:flutter/material.dart';
import 'package:on_air/core/time/cairo_date_time_formatter.dart';
import 'package:on_air/design_system/components/notice_card.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';
import 'package:on_air/l10n/generated/app_localizations.dart';

/// Renders the server's wait as `mm:ss` under an hour (`00:30`, `04:59`)
/// and as «{hours} ساعة و{minutes} دقيقة» from an hour up (`1h 0m`,
/// `23h 10m`) — the display half of the ladder (R8, T063).
String formatSendWait(Duration remaining, AppLocalizations l10n) {
  final clamped = remaining.isNegative ? Duration.zero : remaining;
  if (clamped < const Duration(hours: 1)) {
    final minutes = clamped.inMinutes;
    final seconds = clamped.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  final hours = clamped.inHours;
  final minutes = clamped.inMinutes % 60;
  return l10n.durationHoursMinutes('$hours', '$minutes');
}

/// The blocked state (contracts/ui-screens.md §4.3, T064): a warning-tone
/// notice with the Cairo lift date, «كلّم الدعم» and — for `register` —
/// the sign-out text. The step behind it renders with every send and
/// confirm control disabled.
final class BlockedNotice extends StatelessWidget {
  const BlockedNotice({
    required this.blockedUntil,
    required this.onSupport,
    this.onSignOut,
    super.key,
  });

  /// The server's `blocked_until` — the app renders it verbatim, it never
  /// computes the block (Constitution II).
  final DateTime blockedUntil;
  final VoidCallback onSupport;

  /// Register only: leaving never keeps the half-made account (FR-014).
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The block replaces the whole step: announce it when it appears.
    return Semantics(
      liveRegion: true,
      child: Column(
        key: const ValueKey('pv-blocked-notice'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoticeCard(
            icon: AppIcons.blocked,
            tone: NoticeTone.warning,
            message: l10n.otpBlockedUntil(
              formatCairoDayMonthTime(blockedUntil, locale: l10n.localeName),
            ),
            actionLabel: l10n.whatsappContactSupport,
            onAction: onSupport,
          ),
          if (onSignOut != null) ...[
            const SizedBox(height: Dimens.space8),
            TextButton(
              key: const ValueKey('pv-blocked-sign-out'),
              onPressed: onSignOut,
              style: TextButton.styleFrom(
                foregroundColor: context.colors['textAccent'],
              ),
              child: Text(l10n.signOut),
            ),
          ],
        ],
      ),
    );
  }
}
