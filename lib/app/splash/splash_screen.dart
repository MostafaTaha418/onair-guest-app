import 'package:flutter/material.dart';
import 'package:on_air/design_system/brand/on_air_logo.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

final class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Same size as the native launch screen mark, so the hand-off from the
  /// system splash to Flutter does not jump.
  static const markHeight = 88.0;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onPrimary;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.colors.gradient('splash')),
        child: Center(
          // The stack is the size of the mark, so the mark stays exactly
          // centred like the native splash; the name hangs below it.
          child: Stack(
            key: const ValueKey('splash-logo'),
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              OnAirLogo.mark(height: markHeight, color: color),
              Positioned(
                top: markHeight + Dimens.space24,
                child: ExcludeSemantics(
                  child: OnAirLogo.wordmark(size: 34, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
