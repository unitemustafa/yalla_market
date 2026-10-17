import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// A snapping, circular card row with a smaller preview on either side.
class CenteredCardCarousel extends StatelessWidget {
  const CenteredCardCarousel({
    super.key,
    required this.itemCount,
    required this.itemHeight,
    required this.itemBuilder,
    this.sliderKey,
  }) : assert(itemCount >= 0);

  final int itemCount;
  final double itemHeight;
  final IndexedWidgetBuilder itemBuilder;
  final Key? sliderKey;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    // Changing the collection size starts a fresh, correctly aligned cycle.
    return _CarouselPages(key: ValueKey(itemCount), carousel: this);
  }
}

class _CarouselPages extends StatefulWidget {
  const _CarouselPages({super.key, required this.carousel});

  final CenteredCardCarousel carousel;

  @override
  State<_CarouselPages> createState() => _CarouselPagesState();
}

class _CarouselPagesState extends State<_CarouselPages> {
  late final PageController _controller;
  late int _currentPage;

  CenteredCardCarousel get _carousel => widget.carousel;

  @override
  void initState() {
    super.initState();
    // Start on the first item with plenty of pages available in both directions.
    _currentPage = _carousel.itemCount > 1 ? _carousel.itemCount * 10000 : 0;
    _controller = PageController(
      initialPage: _currentPage,
      viewportFraction: _carousel.itemCount > 1 ? 0.80 : 1,
      keepPage: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectItem(int index) {
    final target = _currentPage + index - _currentPage % _carousel.itemCount;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _carousel.itemCount;
    final activeIndex = _currentPage % count;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.darkAction : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _carousel.itemHeight + 16,
          child: PageView.builder(
            key: _carousel.sliderKey,
            controller: _controller,
            itemCount: count == 1 ? 1 : null,
            physics: count == 1
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, pageIndex) {
              return AnimatedBuilder(
                animation: _controller,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: count > 1 ? 6 : 0,
                    vertical: 8,
                  ),
                  child: _carousel.itemBuilder(context, pageIndex % count),
                ),
                builder: (context, child) {
                  final page =
                      _controller.hasClients &&
                          _controller.position.hasContentDimensions
                      ? _controller.page ?? _currentPage.toDouble()
                      : _currentPage.toDouble();
                  final distance = (page - pageIndex).abs().clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, distance * 6),
                    child: Transform.scale(
                      scale: 1 - distance * 0.10,
                      child: child,
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (count > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (index) {
              final selected = index == activeIndex;
              return Semantics(
                label: '${index + 1} / $count',
                selected: selected,
                child: InkResponse(
                  onTap: () => _selectItem(index),
                  radius: 20,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        width: selected ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: selected
                              ? activeColor
                              : activeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}
