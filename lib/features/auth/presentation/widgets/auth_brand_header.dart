import 'package:flutter/material.dart';
import 'package:on_air/design_system/brand/on_air_logo.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

/// The splash mark and localized wordmark, sized for account screens.
final class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onPrimary;
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Center(
      child: Column(
        key: const ValueKey('auth-brand-header'),
        children: [
          OnAirLogo.mark(height: compact ? 44 : 56, color: color),
          SizedBox(height: compact ? Dimens.space8 : Dimens.space16),
          ExcludeSemantics(
            child: OnAirLogo.wordmark(size: compact ? 23 : 28, color: color),
          ),
        ],
      ),
    );
  }
}
