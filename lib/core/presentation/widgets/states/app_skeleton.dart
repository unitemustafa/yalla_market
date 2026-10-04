import 'package:flutter/material.dart';

import '../../../localization/app_translations.dart';
import '../layouts/grid_layout.dart';

/// One shared shimmer animation for a group of placeholders, not one ticker
/// per card. Static shapes are retained between animation frames.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, required this.child});

  final Widget child;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF293342) : const Color(0xFFE8ECF1);
    final highlight = dark ? const Color(0xFF384557) : Colors.white;
    return Semantics(
      label: context.tr('Loading...'),
      container: true,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              child: widget.child,
              builder: (context, child) => ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  final position = _controller.value * 3 - 1.5;
                  return LinearGradient(
                    colors: [base, highlight, base],
                    stops: const [0.25, 0.5, 0.75],
                    begin: Alignment(position - 1, -0.15),
                    end: Alignment(position + 1, 0.15),
                  ).createShader(bounds);
                },
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Reserves the complete image slot until the first decoded frame arrives.
class AppImageSkeleton extends StatelessWidget {
  const AppImageSkeleton({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final slotWidth = width?.isFinite == true
          ? width!
          : constraints.hasBoundedWidth
          ? constraints.maxWidth
          : 96.0;
      final slotHeight = height?.isFinite == true
          ? height!
          : constraints.hasBoundedHeight
          ? constraints.maxHeight
          : 96.0;
      return SizedBox(
        width: slotWidth,
        height: slotHeight,
        child: const AppSkeleton(
          child: SizedBox.expand(child: ColoredBox(color: Colors.white)),
        ),
      );
    },
  );
}

/// Compact pending feedback for buttons and already visible content.
class AppLoadingPlaceholder extends StatelessWidget {
  const AppLoadingPlaceholder({super.key, this.width = 48, this.height = 8});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: AppSkeleton(
      child: SkeletonBox(width: width, height: height, radius: 4),
    ),
  );
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.rows = 3, this.rowHeight = 112});

  final int rows;
  final double rowHeight;

  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        rows,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == rows - 1 ? 0 : 12),
          child: SkeletonBox(height: rowHeight, width: double.infinity),
        ),
      ),
    ),
  );
}

class AppProductSkeletonGrid extends StatelessWidget {
  const AppProductSkeletonGrid({
    super.key,
    this.maxCrossAxisCount = 6,
    this.mainAxisExtent = 188,
  });

  final int maxCrossAxisCount;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: GridLayout(
      itemCount: 6,
      maxCrossAxisCount: maxCrossAxisCount,
      mainAxisExtent: mainAxisExtent,
      itemBuilder: (_, _) => const SkeletonBox(height: 188),
    ),
  );
}

class AppCategorySkeletonGrid extends StatelessWidget {
  const AppCategorySkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: GridLayout(
      itemCount: 8,
      mainAxisExtent: 106,
      minimumCardWidth: 72,
      minCrossAxisCount: 4,
      maxCrossAxisCount: 4,
      itemBuilder: (_, _) => const SkeletonBox(height: 106),
    ),
  );
}

class AppProductSkeletonRail extends StatelessWidget {
  const AppProductSkeletonRail({super.key});

  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: SizedBox(
      height: 188,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = ((constraints.maxWidth - 16) / 3).clamp(88.0, 112.0);
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, _) => SkeletonBox(height: 188, width: width),
          );
        },
      ),
    ),
  );
}

/// Reveals a newly mounted data section without remounting it on refresh.
class AppContentReveal extends StatelessWidget {
  const AppContentReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200),
    curve: Curves.easeOut,
    child: child,
    builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
  );
}

class AppProductDetailsSkeleton extends StatelessWidget {
  const AppProductDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: AppSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AspectRatio(aspectRatio: 1, child: SkeletonBox(height: 300)),
          SizedBox(height: 20),
          SkeletonBox(height: 22, width: 200, radius: 6),
          SizedBox(height: 12),
          SkeletonBox(height: 14, width: 120, radius: 6),
          SizedBox(height: 24),
          SkeletonBox(height: 112, width: double.infinity),
          SizedBox(height: 24),
          SkeletonBox(height: 48, width: double.infinity),
        ],
      ),
    ),
  );
}

/// Keeps the loaded subtree's identity on ordinary refreshes. Only a genuine
/// initial loading transition switches children.
class AppLoadingTransition extends StatelessWidget {
  const AppLoadingTransition({
    super.key,
    required this.isLoading,
    required this.loading,
    required this.child,
  });

  final bool isLoading;
  final Widget loading;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    layoutBuilder: (current, previous) => Stack(
      alignment: AlignmentDirectional.topStart,
      children: [
        ...previous.map(
          (child) =>
              PositionedDirectional(top: 0, start: 0, end: 0, child: child),
        ),
        ?current,
      ],
    ),
    child: KeyedSubtree(
      key: ValueKey(isLoading),
      child: isLoading ? loading : child,
    ),
  );
}
