import 'package:flutter/material.dart';

/// Long text (descriptions, house rules) collapsed to [collapsedLines] with a
/// toggle that is rendered only when the text actually overflows.
final class ExpandableText extends StatefulWidget {
  const ExpandableText({
    required this.text,
    required this.moreLabel,
    required this.lessLabel,
    this.collapsedLines = 4,
    super.key,
  });

  final String text;
  final String moreLabel;
  final String lessLabel;
  final int collapsedLines;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

final class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  bool _overflows(BoxConstraints constraints, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: widget.collapsedLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: constraints.maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final overflows = _overflows(
        constraints,
        DefaultTextStyle.of(context).style,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            maxLines: _expanded ? null : widget.collapsedLines,
            overflow: _expanded ? null : TextOverflow.ellipsis,
          ),
          if (overflows)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? widget.lessLabel : widget.moreLabel),
            ),
        ],
      );
    },
  );
}
