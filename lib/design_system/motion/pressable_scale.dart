import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:on_air/design_system/motion/app_motion.dart';

/// Gently scales its child down while a finger is pressing it, giving taps a
/// tactile "push" response. It listens to raw pointer events, so it never
/// competes with an `InkWell` or `GestureDetector` inside the child for the
/// tap itself — it only reflects the press. Under reduced motion it is inert.
final class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.pressedScale = 0.97,
    super.key,
  });

  final Widget child;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

final class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    value: 1,
  );

  void _press() {
    if (AppMotion.reduced(context)) return;
    unawaited(
      _controller.animateTo(
        0,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
      ),
    );
  }

  void _release() {
    unawaited(
      _controller.animateTo(
        1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - (1 - widget.pressedScale) * (1 - _controller.value);
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
