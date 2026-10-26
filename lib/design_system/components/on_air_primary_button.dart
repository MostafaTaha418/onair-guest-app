import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

final class OnAirPrimaryButton extends StatelessWidget {
  const OnAirPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.gradient = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient ? null : colors['button'],
        gradient: gradient ? colors.gradient('authButton') : null,
        borderRadius: BorderRadius.circular(Dimens.radiusButton),
        boxShadow: gradient
            ? [
                BoxShadow(
                  color: colors['authShadow'],
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        height: Dimens.minTouchTarget,
        width: double.infinity,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors['buttonText'],
            disabledForegroundColor: colors['buttonText'],
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors['buttonText'],
                  ),
                )
              : Text(
                  label,
                  style: context.textStyles.authButton.copyWith(
                    color: colors['buttonText'],
                  ),
                ),
        ),
      ),
    );
  }
}
