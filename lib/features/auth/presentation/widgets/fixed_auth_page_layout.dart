import 'package:flutter/material.dart';

/// Keeps compact authentication flows fixed until the keyboard appears, then
/// enables scrolling so every field and action remains reachable.
class FixedAuthPageLayout extends StatelessWidget {
  const FixedAuthPageLayout({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 20),
    this.maxWidth = 430,
    required this.isKeyboardVisible,
    required this.nonScrollingMinHeight,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;
  final bool isKeyboardVisible;
  final double nonScrollingMinHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - padding.horizontal;
        final contentWidth = availableWidth.clamp(1.0, maxWidth);
        final availableHeight = (constraints.maxHeight - padding.vertical)
            .clamp(1.0, double.infinity);
        final shouldScroll =
            isKeyboardVisible || constraints.maxHeight < nonScrollingMinHeight;
        return SingleChildScrollView(
          key: const ValueKey('fixed_auth_page_scroll'),
          physics: shouldScroll
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: availableHeight,
                maxWidth: contentWidth,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
