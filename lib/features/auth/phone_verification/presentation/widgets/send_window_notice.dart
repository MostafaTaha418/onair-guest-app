import 'package:on_air/l10n/generated/app_localizations.dart';

/// Renders the server's wait as `mm:ss` under an hour (`00:30`, `04:59`)
/// and as «{hours} ساعة و{minutes} دقيقة» from an hour up (`1h 0m`,
/// `23h 10m`) — the display half of the ladder (R8, T063). The blocked
/// state's notice joins this file in US5 (T064).
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
