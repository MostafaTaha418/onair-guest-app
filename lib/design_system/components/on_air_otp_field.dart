import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_air/design_system/theme/on_air_theme.dart';

final class OnAirOtpField extends StatefulWidget {
  const OnAirOtpField({
    required this.onCompleted,
    this.controller,
    this.enabled = true,
    this.onChanged,
    super.key,
  });
  final ValueChanged<String> onCompleted;
  final TextEditingController? controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;

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
      child: SizedBox(
        height: 56,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final diameter = ((constraints.maxWidth - 40) / 6).clamp(
              0.0,
              56.0,
            );
            return Stack(
              children: [
                Row(
                  children: List.generate(11, (index) {
                    if (index.isOdd) return const SizedBox(width: 8);
                    final digitIndex = index ~/ 2;
                    final digit = digitIndex < _controller.text.length
                        ? _controller.text[digitIndex]
                        : '';
                    return Expanded(
                      child: Container(
                        height: diameter,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors['inputFill'],
                          borderRadius: BorderRadius.circular(diameter / 2),
                          border: Border.all(color: colors['inputBorder']),
                        ),
                        child: Text(
                          digit,
                          style: context.textStyles.input.copyWith(
                            color: colors.textPrimary,
                          ),
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
                        widget.onChanged?.call(value);
                        if (value.length == 6) widget.onCompleted(value);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
