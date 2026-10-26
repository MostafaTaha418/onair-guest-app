import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';
import 'package:on_air/design_system/tokens/dimens.dart';

final class OnAirOtpField extends StatefulWidget {
  const OnAirOtpField({
    required this.onCompleted,
    this.controller,
    this.enabled = true,
    super.key,
  });
  final ValueChanged<String> onCompleted;
  final TextEditingController? controller;
  final bool enabled;

  @override
  State<OnAirOtpField> createState() => _OnAirOtpFieldState();
}

final class _OnAirOtpFieldState extends State<OnAirOtpField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final digit = index < _controller.text.length
                  ? _controller.text[index]
                  : '';
              return Container(
                width: 44,
                height: Dimens.minTouchTarget,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors['inputFill'],
                  borderRadius: BorderRadius.circular(Dimens.radiusChip),
                  border: Border.all(color: colors['inputBorder']),
                ),
                child: Text(
                  digit,
                  style: context.textStyles.input.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.01,
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (value) {
                  setState(() {});
                  if (value.length == 6) widget.onCompleted(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
