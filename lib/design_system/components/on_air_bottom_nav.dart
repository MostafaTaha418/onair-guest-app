import 'package:flutter/material.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

final class OnAirBottomNav extends StatelessWidget {
  const OnAirBottomNav({
    required this.currentIndex,
    required this.labels,
    required this.onTap,
    this.unreadCount = 0,
    super.key,
  });

  final int currentIndex;
  final List<String> labels;
  final ValueChanged<int> onTap;
  final int unreadCount;

  static const List<String> _names = [
    'home',
    'search',
    'bookings',
    'notifications',
    'account',
  ];
  static const List<IconData> _icons = [
    AppIcons.homeOutlined,
    AppIcons.search,
    AppIcons.calendarMonthOutlined,
    AppIcons.notificationsOutlined,
    AppIcons.personOutline,
  ];
  static const List<IconData> _activeIcons = [
    AppIcons.home,
    AppIcons.search,
    AppIcons.calendarMonth,
    AppIcons.notificationsActiveOutlined,
    AppIcons.person,
  ];

  @override
  Widget build(BuildContext context) {
    assert(labels.length == _names.length, 'Exactly five labels required');
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Dimens.screenSide,
          Dimens.space4,
          Dimens.screenSide,
          Dimens.space4,
        ),
        child: Material(
          color: colors.surface,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
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
                        minHeight: 56,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Dimens.space4),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selected ? colors['badgeNavActive'] : null,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimens.space4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Badge(
                                  isLabelVisible: index == 3 && unreadCount > 0,
                                  label: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                  ),
                                  child: Icon(
                                    selected
                                        ? _activeIcons[index]
                                        : _icons[index],
                                    size: 20,
                                    color: selected
                                        ? colors.primary
                                        : colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
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
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
