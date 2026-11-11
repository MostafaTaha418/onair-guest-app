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
    this.builder,
    super.key,
  });

  final Stream<Duration> remaining;
  final String Function(Duration) format;
  final TextStyle? style;

  /// Draws each tick itself instead of one [Text] from [format], for a
  /// countdown that styles the time apart from the words around it.
  final Widget Function(BuildContext context, Duration remaining)? builder;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: StreamBuilder<Duration>(
      stream: remaining,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final custom = builder;
        if (custom != null) return custom(context, snapshot.data!);
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
