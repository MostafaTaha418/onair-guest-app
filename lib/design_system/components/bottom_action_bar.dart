import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// A pinned bottom bar: [leading] (price and caption) stretched at the
/// start, [action] (the primary button) at the end.
final class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    required this.leading,
    required this.action,
    super.key,
  });

  final Widget leading;
  final Widget action;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border(
        top: BorderSide(color: context.colors['navBorder']),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Dimens.space12),
        child: Row(
          children: [
            Expanded(child: leading),
            const SizedBox(width: Dimens.space12),
            // OnAirPrimaryButton stretches to the incoming width; size it to
            // its content here.
            IntrinsicWidth(child: action),
          ],
        ),
      ),
    ),
  );
}
