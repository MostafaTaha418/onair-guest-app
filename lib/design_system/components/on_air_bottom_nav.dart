import 'package:flutter/material.dart';
import 'package:on_air/design_system/icons/app_icons.dart';
import 'package:on_air/design_system/motion/app_motion.dart';
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
    'bookings',
    'notifications',
    'account',
  ];
  static const List<IconData> _icons = [
    AppIcons.homeOutlined,
    AppIcons.calendarMonthOutlined,
    AppIcons.notificationsOutlined,
    AppIcons.personOutline,
  ];
  static const List<IconData> _activeIcons = [
    AppIcons.home,
    AppIcons.calendarMonth,
    AppIcons.notificationsActiveOutlined,
    AppIcons.person,
  ];

  @override
  Widget build(BuildContext context) {
    assert(labels.length == _names.length, 'Exactly four labels required');
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / _names.length;
              return Stack(
                children: [
                  // One pill that slides to the selected tab instead of each
                  // tab snapping its own background on and off.
                  AnimatedPositionedDirectional(
                    duration: AppMotion.resolve(context, AppMotion.medium),
                    curve: AppMotion.curve,
                    start: cellWidth * currentIndex + Dimens.space4,
                    top: Dimens.space4,
                    bottom: Dimens.space4,
                    width: cellWidth - Dimens.space8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors['badgeNavActive'],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(_names.length, (index) {
                      final selected = currentIndex == index;
                      final foreground = selected
                          ? colors.primary
                          : colors.textSecondary;
                      return Expanded(
                        child: Semantics(
                          key: ValueKey('nav-${_names[index]}'),
                          label: labels[index],
                          button: true,
                          selected: selected,
                          child: InkWell(
                            onTap: () => onTap(index),
                            customBorder: const StadiumBorder(),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 56),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Dimens.space8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Badge(
                                      isLabelVisible:
                                          index == 2 && unreadCount > 0,
                                      label: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : '$unreadCount',
                                      ),
                                      child: AnimatedScale(
                                        duration: AppMotion.resolve(
                                          context,
                                          AppMotion.fast,
                                        ),
                                        curve: AppMotion.curve,
                                        scale: selected ? 1.1 : 1,
                                        child: Icon(
                                          selected
                                              ? _activeIcons[index]
                                              : _icons[index],
                                          size: 20,
                                          color: foreground,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedDefaultTextStyle(
                                      duration: AppMotion.resolve(
                                        context,
                                        AppMotion.fast,
                                      ),
                                      style: context.textStyles.navLabel
                                          .copyWith(
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: foreground,
                                          ),
                                      child: Text(
                                        labels[index],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
