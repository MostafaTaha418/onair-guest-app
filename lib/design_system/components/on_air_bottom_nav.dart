import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

final class OnAirBottomNav extends StatelessWidget {
  const OnAirBottomNav({
    required this.currentIndex,
    required this.labels,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final List<String> labels;
  final ValueChanged<int> onTap;

  static const List<String> _names = [
    'home',
    'search',
    'bookings',
    'favorites',
    'account',
  ];
  static const List<IconData> _icons = [
    Icons.home_outlined,
    Icons.search,
    Icons.calendar_month_outlined,
    Icons.favorite_border,
    Icons.person_outline,
  ];
  static const List<IconData> _activeIcons = [
    Icons.home,
    Icons.search,
    Icons.calendar_month,
    Icons.favorite,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    assert(labels.length == _names.length, 'Exactly five labels required');
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors['navBorder'])),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_names.length, (index) {
            final selected = currentIndex == index;
            return Expanded(
              child: Semantics(
                key: ValueKey('nav-${_names[index]}'),
                label: labels[index],
                button: true,
                selected: selected,
                child: InkWell(
                  onTap: () => onTap(index),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: Dimens.minTouchTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimens.space8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: selected ? colors['badgeNavActive'] : null,
                              borderRadius: BorderRadius.circular(
                                Dimens.radiusChip,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimens.space16,
                                vertical: Dimens.space4,
                              ),
                              child: Icon(
                                selected ? _activeIcons[index] : _icons[index],
                                color: selected
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.navLabel.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
