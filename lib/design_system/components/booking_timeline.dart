import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// One row of [BookingTimeline].
@immutable
final class TimelineEntry {
  const TimelineEntry({required this.title, required this.time});

  final String title;
  final String time;
}

/// A vertical dot-line timeline (data-model §9). Entries are few, so a plain
/// `Column` is enough; RTL-safe via directional padding.
final class BookingTimeline extends StatelessWidget {
  const BookingTimeline({required this.entries, super.key});

  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < entries.length; index++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: Dimens.space12,
                      height: Dimens.space12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == 0
                            ? colors.primary
                            : colors['badgeNavActive'],
                      ),
                    ),
                    if (index != entries.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: colors['borderDetail'],
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: Dimens.space8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: Dimens.space12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[index].title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.textPrimary),
                        ),
                        Text(
                          entries[index].time,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
