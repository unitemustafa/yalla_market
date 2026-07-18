part of 'promo_slider.dart';

class _PromoOfferSheet extends StatelessWidget {
  const _PromoOfferSheet({required this.offer});

  final _PromoOfferData offer;

  String? get _shareLink {
    final id = offer.validOfferId;
    return id == null ? null : SharedContentLinks.offer(id);
  }

  String _shareText(BuildContext context) {
    final link = _shareLink!;
    if (context.isArabicLanguage) {
      return 'شوف ${offer.title(context)} على يلا ماركت\n'
          '${offer.subtitle(context)}\n$link';
    }
    return 'Check out ${offer.title(context)} on Yalla Market\n'
        '${offer.subtitle(context)}\n$link';
  }

  void _showShareSheet(BuildContext context) {
    final link = _shareLink;
    if (link == null) return;
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ContentShareSheet(
          heading: 'Share offer',
          description: 'Send this offer or copy its link.',
          image: offer.image,
          imagePlaceholderType: AppImagePlaceholderType.offer,
          title: offer.title(pageContext),
          subtitle: offer.subtitle(pageContext),
          detail: offer.value(pageContext),
          onCopyLink: () async {
            Navigator.pop(sheetContext);
            await Clipboard.setData(ClipboardData(text: link));
            if (!pageContext.mounted) return;
            CustomSnackBar.showSuccess(
              context: pageContext,
              title: 'Offer link copied',
              message: 'You can share it with anyone.',
            );
          },
          onShare: (sourceContext) async {
            final box = sourceContext.findRenderObject() as RenderBox?;
            final origin = box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : Rect.fromCenter(
                    center: MediaQuery.sizeOf(pageContext).center(Offset.zero),
                    width: 1,
                    height: 1,
                  );
            Navigator.pop(sheetContext);
            try {
              await SharePlus.instance.share(
                ShareParams(
                  text: _shareText(pageContext),
                  title: offer.title(pageContext),
                  sharePositionOrigin: origin,
                ),
              );
            } catch (_) {
              if (!pageContext.mounted) return;
              CustomSnackBar.showError(
                context: pageContext,
                title: 'Could not share offer',
                message: 'Please try again.',
              );
            }
          },
        );
      },
    );
  }

  Future<void> _checkoutOffer(BuildContext context) async {
    final cartCubit = context.read<CartCubit>();
    final offerId = offer.validOfferId;
    if (offerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This offer cannot be added to cart right now.'),
        ),
      );
      return;
    }

    await cartCubit.addItem(offer.toCartItem(context, offerId), 1);

    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.pushNamed(AppRoutes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF222326) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.64)
        : Colors.black.withValues(alpha: 0.58);

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.94,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: mutedColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _OfferSheetHeader(
              offer: offer,
              textColor: textColor,
              mutedColor: mutedColor,
              isDark: isDark,
              onShare: _shareLink == null
                  ? null
                  : () => _showShareSheet(context),
            ),
            const SizedBox(height: 14),
            if (offer.endsAt != null) ...[
              _OfferCountdownPanel(
                offer: offer,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              const SizedBox(height: 14),
            ],
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _OfferStatusPanel(
                    offer: offer,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _OfferProductsPanel(
                    offer: offer,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _OfferSummaryPanel(
                    offer: offer,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _OfferPaymentPanel(
                    textColor: textColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            _OfferCheckoutBar(
              offer: offer,
              textColor: textColor,
              mutedColor: mutedColor,
              isDark: isDark,
              onCheckout: () => _checkoutOffer(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferSheetHeader extends StatelessWidget {
  const _OfferSheetHeader({
    required this.offer,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
    this.onShare,
  });

  final _PromoOfferData offer;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final discountRate = offer.discountRate(context);

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: offer.color.withValues(alpha: isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(offer.icon, color: offer.color, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      offer.badge(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (discountRate != null) ...[
                    const SizedBox(width: 8),
                    _MiniBadge(
                      text: discountRate,
                      color: offer.color,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
              if (discountRate == null)
                const SizedBox(height: 3)
              else
                const SizedBox(height: 6),
              Text(
                offer.title(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontSize: AppFontSizes.title,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (onShare != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: context.tr('Share offer'),
            child: Material(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF3F5FA),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onShare,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(AppIcons.send_1, size: 20),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OfferCountdownPanel extends StatefulWidget {
  const _OfferCountdownPanel({
    required this.offer,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  final _PromoOfferData offer;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  @override
  State<_OfferCountdownPanel> createState() => _OfferCountdownPanelState();
}

class _OfferCountdownPanelState extends State<_OfferCountdownPanel> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endsAt = widget.offer.endsAt;
    if (endsAt == null) return const SizedBox.shrink();

    final remaining = endsAt.difference(_now);
    final duration = remaining.isNegative ? Duration.zero : remaining;
    final title = remaining.isNegative
        ? (context.isArabicLanguage ? 'انتهى العرض' : 'Offer ended')
        : (context.isArabicLanguage ? 'ينتهي العرض خلال' : 'Offer ends in');

    return _OfferPanel(
      isDark: widget.isDark,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.offer.color.withValues(
                alpha: widget.isDark ? 0.18 : 0.10,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.offer.icon, color: widget.offer.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: widget.mutedColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: _CountdownUnits(
                duration: duration,
                color: widget.offer.color,
                numberColor: widget.textColor,
                isCompact: true,
                isSingleLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferStatusPanel extends StatelessWidget {
  const _OfferStatusPanel({
    required this.offer,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  final _PromoOfferData offer;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: offer.color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.info_circle, color: offer.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.status(context),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.detail(context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferProductsPanel extends StatelessWidget {
  const _OfferProductsPanel({
    required this.offer,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  final _PromoOfferData offer;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _OfferPanel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: AppIcons.shopping_bag,
            title: context.isArabicLanguage
                ? 'العناصر داخل العرض'
                : 'Offer items',
            textColor: textColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < offer.products.length; index++) ...[
            _OfferProductRow(
              offer: offer,
              product: offer.products[index],
              textColor: textColor,
              mutedColor: mutedColor,
              isDark: isDark,
            ),
            if (index != offer.products.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _OfferProductRow extends StatelessWidget {
  const _OfferProductRow({
    required this.offer,
    required this.product,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  final _PromoOfferData offer;
  final _OfferProduct product;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  void _openProductDetails(BuildContext context) {
    final productId = product.productId?.trim();
    if (productId == null || productId.isEmpty) return;
    final productBadge = product.badge(context);
    final discount = _looksLikeDiscountLabel(productBadge)
        ? productBadge
        : offer.discountRate(context);
    final navigator = Navigator.of(context);

    navigator.pop();
    navigator.pushNamed(
      AppRoutes.productDetail,
      arguments: ProductDetailRouteArgs(
        productId: productId,
        initialVariantId: product.variantId,
        image: product.image,
        title: product.title(context),
        brand: product.brand(context),
        price: product.price,
        oldPrice: product.oldPrice,
        discount: discount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageFill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF1F3F8);

    return Semantics(
      button: true,
      label: product.title(context),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openProductDetails(context),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: imageFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppImage(
                source: product.image,
                fallbackType: AppImagePlaceholderType.product,
                fit: BoxFit.contain,
                cacheWidth: 88,
                cacheHeight: 88,
                filterQuality: FilterQuality.low,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: textColor,
                                height: 1.18,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (product.meta(context).trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.meta(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: GreenCurrencyPrice(
                      price: product.price,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (product.oldPrice != null &&
                      product.oldPrice != product.price) ...[
                    const SizedBox(height: 2),
                    AppCurrencyText(
                      text: product.oldPrice!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: mutedColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _looksLikeDiscountLabel(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.contains('%') ||
      normalized.contains('off') ||
      normalized.contains('خصم');
}

bool _useArabicCopy(BuildContext context) {
  return context.isArabicLanguage ||
      Directionality.of(context) == TextDirection.rtl;
}
