import 'package:flutter/material.dart';

/// A readable two-line label with the full name available on long press/hover.
class CategoryLabel extends StatelessWidget {
  const CategoryLabel({super.key, required this.label, this.style});

  static const lineHeight = 1.3;

  /// Reserve both lines, including when the system enlarges text.
  static double heightFor(BuildContext context, double fontSize) =>
      MediaQuery.textScalerOf(context).scale(fontSize) * lineHeight * 2 + 4;

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    excludeFromSemantics: true,
    child: Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: (style ?? DefaultTextStyle.of(context).style).copyWith(
        height: lineHeight,
      ),
    ),
  );
}
