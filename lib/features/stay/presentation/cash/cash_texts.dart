/// Small text helpers for the cash confirmation flow.
///
/// The wait text copies `_waitText` in `error_message.dart` (`m:ss`,
/// 90 s → «1:30») so the resend countdown reads exactly like the rate-limit
/// wait everywhere else in the app.
String formatWait(Duration d) {
  final totalSeconds = d.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
