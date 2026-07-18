import 'package:flutter/material.dart';

class GridLayout extends StatelessWidget {
  const GridLayout({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mainAxisExtent = 188,
    this.minimumCardWidth = 88,
    this.minCrossAxisCount = 2,
    this.maxCrossAxisCount = 6,
  }) : assert(minimumCardWidth > 0),
       assert(minCrossAxisCount > 0),
       assert(maxCrossAxisCount >= minCrossAxisCount);

  final int itemCount;
  final double mainAxisExtent;
  final double minimumCardWidth;
  final int minCrossAxisCount;
  final int maxCrossAxisCount;
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
            mainAxisSpacing: 10,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
