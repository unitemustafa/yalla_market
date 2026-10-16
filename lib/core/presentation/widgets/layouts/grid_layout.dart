import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering;

class GridLayout extends StatelessWidget {
  const GridLayout({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mainAxisExtent = 188,
    this.minimumCardWidth = 88,
    this.minCrossAxisCount = 2,
    this.maxCrossAxisCount = 6,
    this.mainAxisSpacing = 10,
  }) : assert(minimumCardWidth > 0),
       assert(minCrossAxisCount > 0),
       assert(maxCrossAxisCount >= minCrossAxisCount);

  final int itemCount;
  final double mainAxisExtent;
  final double minimumCardWidth;
  final int minCrossAxisCount;
  final int maxCrossAxisCount;
  final double mainAxisSpacing;
  final Widget? Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisSpacing = 8.0;
        final crossAxisCount =
            ((constraints.maxWidth + crossAxisSpacing) /
                    (minimumCardWidth + crossAxisSpacing))
                .floor()
                .clamp(minCrossAxisCount, maxCrossAxisCount);

        return GridView.builder(
          itemCount: itemCount,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}

/// A grid whose items are laid out only near the viewport. Use directly inside
/// CustomScrollView; a shrink-wrapped grid cannot virtualize a long catalog.
class SliverGridLayout extends StatelessWidget {
  const SliverGridLayout({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mainAxisExtent = 188,
    this.minimumCardWidth = 88,
    this.minCrossAxisCount = 2,
    this.maxCrossAxisCount = 6,
    this.mainAxisSpacing = 10,
    this.findChildIndexCallback,
  }) : assert(minimumCardWidth > 0),
       assert(minCrossAxisCount > 0),
       assert(maxCrossAxisCount >= minCrossAxisCount);

  final int itemCount;
  final double mainAxisExtent;
  final double minimumCardWidth;
  final int minCrossAxisCount;
  final int maxCrossAxisCount;
  final double mainAxisSpacing;
  final Widget? Function(BuildContext, int) itemBuilder;
  final int? Function(Key)? findChildIndexCallback;

  @override
  Widget build(BuildContext context) => SliverGrid(
    gridDelegate: _ResponsiveGridDelegate(
      minimumCardWidth: minimumCardWidth,
      minCrossAxisCount: minCrossAxisCount,
      maxCrossAxisCount: maxCrossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      mainAxisExtent: mainAxisExtent,
    ),
    delegate: SliverChildBuilderDelegate(
      itemBuilder,
      childCount: itemCount,
      findChildIndexCallback: findChildIndexCallback,
    ),
  );
}

// SliverLayoutBuilder also observes scrollOffset. Building a fresh child
// delegate there rebuilt every visible card on every scroll frame. Responsive
// columns belong to render layout, which leaves existing elements untouched.
class _ResponsiveGridDelegate extends SliverGridDelegate {
  const _ResponsiveGridDelegate({
    required this.minimumCardWidth,
    required this.minCrossAxisCount,
    required this.maxCrossAxisCount,
    required this.mainAxisSpacing,
    required this.mainAxisExtent,
  });

  final double minimumCardWidth;
  final int minCrossAxisCount;
  final int maxCrossAxisCount;
  final double mainAxisSpacing;
  final double mainAxisExtent;

  @override
  rendering.SliverGridLayout getLayout(
    rendering.SliverConstraints constraints,
  ) {
    const spacing = 8.0;
    final columns =
        ((constraints.crossAxisExtent + spacing) / (minimumCardWidth + spacing))
            .floor()
            .clamp(minCrossAxisCount, maxCrossAxisCount);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: mainAxisSpacing,
      mainAxisExtent: mainAxisExtent,
    ).getLayout(constraints);
  }

  @override
  bool shouldRelayout(_ResponsiveGridDelegate oldDelegate) =>
      minimumCardWidth != oldDelegate.minimumCardWidth ||
      minCrossAxisCount != oldDelegate.minCrossAxisCount ||
      maxCrossAxisCount != oldDelegate.maxCrossAxisCount ||
      mainAxisSpacing != oldDelegate.mainAxisSpacing ||
      mainAxisExtent != oldDelegate.mainAxisExtent;
}
