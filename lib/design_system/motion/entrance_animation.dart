import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:on_air/design_system/motion/app_motion.dart';

/// Plays a one-shot "rise and fade in" when the widget is first mounted: the
/// child slides up from [offset] logical pixels while fading in. In a lazy list
/// (`ListView.builder` / `SliverList.builder`) each item mounts as it scrolls
/// into view, so wrapping the item reveals it on scroll for free; in an eager
/// column, pass an increasing [delay] to stagger the entrance.
///
/// It never replays (scrolling back to a built item shows it at rest), and it
/// collapses to an instant, static child when the viewer prefers reduced
/// motion — so it clarifies arrival without ever delaying the content.
final class EntranceAnimation extends StatefulWidget {
  const EntranceAnimation({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
    this.duration = AppMotion.medium,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

final class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.entrance,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      unawaited(_controller.forward());
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) unawaited(_controller.forward());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
