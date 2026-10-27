import 'package:flutter/material.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

final class OnAirTextField extends StatelessWidget {
  const OnAirTextField({
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.enabled = true,
    this.textInputAction,
    this.obscureText = false,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool enabled;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimens.radiusField),
      borderSide: BorderSide(color: color),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autofillHints: autofillHints,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: context.textStyles.input.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: context.textStyles.placeholder.copyWith(
              color: colors['placeholder'],
            ),
            filled: true,
            fillColor: colors['inputFill'],
            border: border(colors['inputBorder']),
            enabledBorder: border(colors['inputBorder']),
            focusedBorder: border(colors['inputFocus']),
            errorBorder: border(colors['inputError']),
            focusedErrorBorder: border(colors['inputErrorFocus']),
            errorText: errorText,
            errorStyle: TextStyle(color: colors.errorText),
          ),
        ),
        if (errorText != null)
          Semantics(
            liveRegion: true,
            label: errorText,
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }
}
