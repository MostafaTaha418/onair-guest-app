import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

/// A countdown that rebuilds only its own text (Constitution VIII): the
/// `StreamBuilder` sits inside a `RepaintBoundary`, so the screen never
/// rebuilds on a tick.
final class CountdownText extends StatelessWidget {
  const CountdownText({
    required this.remaining,
    required this.format,
    this.style,
    super.key,
  });

  final Stream<Duration> remaining;
  final String Function(Duration) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: StreamBuilder<Duration>(
      stream: remaining,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return Text(
          format(snapshot.data!),
          style:
              style ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
        );
      },
    ),
  );
}
