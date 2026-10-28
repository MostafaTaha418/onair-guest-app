import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

final class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: context.colors.gradient('splash')),
      child: Center(
        child: Text(
          'OnAir',
          style: context.textStyles.splashTitle.copyWith(
            color: context.colors.onPrimary,
          ),
        ),
      ),
    ),
  );
}
