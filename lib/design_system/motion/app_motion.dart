import 'package:flutter/widgets.dart';

/// Shared motion tokens for the app's animations. Keeping durations and curves
/// in one place makes the whole app move with one rhythm, and [resolve] makes
/// every animation honour the platform "reduce motion" setting by collapsing
/// to no duration — the DESIGN.md rule that motion must never delay a task.
abstract final class AppMotion {
  /// Quick feedback: presses, small state flips.
  static const Duration fast = Duration(milliseconds: 180);

  /// The default for most transitions: the nav indicator, entrances.
  static const Duration medium = Duration(milliseconds: 320);

  /// Larger, more deliberate moves (hero-scale page changes).
  static const Duration slow = Duration(milliseconds: 460);

  /// The house easing — a soft decelerate that reads as "settling into place".
  static const Curve curve = Curves.easeOutCubic;

  /// The entrance easing — slightly springy without overshoot.
  static const Curve entrance = Curves.easeOutCubic;

  /// Per-item delay in a staggered list entrance.
  static const Duration stagger = Duration(milliseconds: 55);

  /// Whether the viewer asked the platform to reduce motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or [Duration.zero] when the viewer prefers reduced motion, so an
  /// animated widget settles instantly instead of being disabled entirely.
  static Duration resolve(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
