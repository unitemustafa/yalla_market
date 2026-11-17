part of 'product_detail_view.dart';

extension _ProductDetailCartAnimation on _ProductDetailViewState {
  void _openCart() {
    _cartFeedbackGeneration++;
    _cancelCartAnimation();
    Navigator.pushNamed(context, AppRoutes.cart);
  }

  void _removeFlyingProduct() {
    final entry = _flyingProduct;
    _flyingProduct = null;
    entry?.remove();
    entry?.dispose();
  }

  void _cancelCartAnimation() {
    _cartAnimation.stop(canceled: true);
    _cartAnimation.value = 0;
    _removeFlyingProduct();
  }

  Rect? _rectInOverlay(GlobalKey key, RenderBox overlayBox) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
  }

  Future<void> _flyProductToCart(String image) async {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final overlay = Overlay.maybeOf(context);
    final overlayBox = overlay?.context.findRenderObject();
    if (overlay == null || overlayBox is! RenderBox || !overlayBox.hasSize) {
      return;
    }
    final target = _rectInOverlay(_cartTargetKey, overlayBox);
    final button = _rectInOverlay(_addButtonKey, overlayBox);
    if (target == null || button == null) return;

    final imageRect = _rectInOverlay(_productImageKey, overlayBox);
    final imageOpacity =
        _productImageKey.currentContext
            ?.findAncestorWidgetOfExactType<Opacity>()
            ?.opacity ??
        1;
    final visibleArea = Rect.fromLTRB(
      0,
      target.bottom + 7,
      overlayBox.size.width,
      button.top - 12,
    );
    final start =
        imageRect != null &&
            !imageRect.isEmpty &&
            imageOpacity > 0 &&
            visibleArea.contains(imageRect.center)
        ? imageRect.center
        : button.center;
    final end = target.center;
    final control = Offset(
      (start.dx + (start.dx <= end.dx ? -120 : 120)).clamp(
        28.0,
        math.max(28.0, overlayBox.size.width - 28),
      ),
      start.dy + (end.dy - start.dy) * 0.8,
    );
    final color = Theme.of(context).cardColor;
    final entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: _cartAnimation,
        builder: (context, child) {
          final progress = (_cartAnimation.value * 880 / 700).clamp(0.0, 1.0);
          if (progress >= 1) return const SizedBox.shrink();
          final t = Curves.easeInOutCubic.transform(progress);
          final inverse = 1 - t;
          // Quadratic Bézier, expressed in the overlay's coordinates.
          final position =
              start * (inverse * inverse) +
              control * (2 * inverse * t) +
              end * (t * t);
          final size = 56.0 - 48 * t;
          return Positioned(
            left: position.dx - size / 2,
            top: position.dy - size / 2,
            width: size,
            height: size,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: ((1 - t) / 0.15).clamp(0.0, 1.0),
                  child: RepaintBoundary(
                    key: const ValueKey('product_detail_flying_image'),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: color,
            shape: const CircleBorder(),
            shadows: const [BoxShadow(color: Color(0x26000000), blurRadius: 8)],
          ),
          child: ClipOval(
            child: AppImage(
              source: image,
              fallbackType: AppImagePlaceholderType.product,
              fit: BoxFit.contain,
              cacheWidth: 168,
              cacheHeight: 168,
            ),
          ),
        ),
      ),
    );
    _flyingProduct = entry;
    overlay.insert(entry);
    try {
      await _cartAnimation.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Navigation, reduced motion, or disposal can end the visual feedback.
    } finally {
      _removeFlyingProduct();
    }
  }
}
