part of 'promo_slider.dart';

class _PromoOfferData {
  const _PromoOfferData({
    this.offerId,
    required this.icon,
    required this.color,
    required this.image,
    this.endsAtIso,
    required this.badgeEn,
    required this.badgeAr,
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
    required this.valueEn,
    required this.valueAr,
    required this.statusEn,
    required this.statusAr,
    required this.detailEn,
    required this.detailAr,
    required this.subtotal,
    required this.discount,
    required this.discountRateEn,
    required this.discountRateAr,
    required this.afterDiscount,
    required this.deliveryFee,
    required this.total,
    required this.actionEn,
    required this.actionAr,
    required this.products,
    this.visibilityMode = 'general',
    this.showInGeneral = true,
    this.regionSlugs = const [],
    this.regionNames = const [],
    this.linkUrl,
    this.linkLabelEn,
    this.linkLabelAr,
    this.displaySeconds = 5,
  });

  final String? offerId;
  final IconData icon;
  final Color color;
  final String image;
  final String? endsAtIso;
  final String badgeEn;
  final String badgeAr;
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
  final String valueEn;
  final String valueAr;
  final String statusEn;
  final String statusAr;
  final String detailEn;
  final String detailAr;
  final String subtotal;
  final String discount;
  final String discountRateEn;
  final String discountRateAr;
  final String afterDiscount;
  final String deliveryFee;
  final String total;
  final String actionEn;
  final String actionAr;
  final List<_OfferProduct> products;
  final String visibilityMode;
  final bool showInGeneral;
  final List<String> regionSlugs;
  final List<String> regionNames;
  final String? linkUrl;
  final String? linkLabelEn;
  final String? linkLabelAr;
  final int displaySeconds;

  bool get isGeneralVisibility =>
      visibilityMode.trim().toLowerCase() == 'general' && regionSlugs.isEmpty;

  String? get validOfferId {
    final value = offerId?.trim();
    if (value == null || value.isEmpty) return null;
    final id = int.tryParse(value);
    if (id == null || id <= 0) return null;
    return id.toString();
  }

  DateTime? get endsAt {
    final value = endsAtIso;
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String badge(BuildContext context) =>
      _useArabicCopy(context) ? badgeAr : badgeEn;

  String title(BuildContext context) =>
      _useArabicCopy(context) ? titleAr : titleEn;

  String subtitle(BuildContext context) =>
      _useArabicCopy(context) ? subtitleAr : subtitleEn;

  String outsideDescription(BuildContext context) {
    final productNames = products
        .map((product) => product.title(context))
        .where((title) => title.trim().isNotEmpty)
        .join(' - ');
    final description = subtitle(context);

    if (productNames.isEmpty) return description;
    return '$description - $productNames';
  }

  String value(BuildContext context) =>
      _useArabicCopy(context) ? valueAr : valueEn;

  String status(BuildContext context) =>
      _useArabicCopy(context) ? statusAr : statusEn;

  String detail(BuildContext context) =>
      _useArabicCopy(context) ? detailAr : detailEn;

  String? discountRate(BuildContext context) {
    final value = _useArabicCopy(context) ? discountRateAr : discountRateEn;
    return value.trim().isEmpty ? null : value;
  }

  String? linkLabel(BuildContext context) {
    final value = _useArabicCopy(context) ? linkLabelAr : linkLabelEn;
    final fallback = linkUrl;
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }

  String action(BuildContext context) =>
      _useArabicCopy(context) ? actionAr : actionEn;

  bool get hasExternalLink => linkUrl?.trim().isNotEmpty ?? false;

  CartItemData toCartItem(BuildContext context, String validOfferId) {
    final fallbackProduct = products.isEmpty ? null : products.first;
    return CartItemData(
      id: validOfferId,
      productId: validOfferId,
      image: image.trim().isNotEmpty ? image : (fallbackProduct?.image ?? ''),
      brand: context.tr('Package offer'),
      title: title(context),
      price: _moneyValue(total),
      quantity: 1,
      itemType: 'offer',
      visibilityMode: visibilityMode,
      regionSlugs: regionSlugs,
      regionNames: regionNames,
      offerProducts: products
          .map(
            (product) => CartOfferProductData(
              productId: product.productId,
              variantId: product.variantId,
              image: product.image,
              brand: product.brand(context),
              title: product.title(context),
              price: _moneyValue(product.price),
              quantity: product.quantity,
              attributes: product.meta(context).trim().isEmpty
                  ? const []
                  : [
                      CartItemAttribute(
                        label: context.tr('Variant'),
                        value: product.meta(context),
                      ),
                    ],
            ),
          )
          .toList(growable: false),
    );
  }
}

class _OfferProduct {
  const _OfferProduct({
    this.productId,
    this.variantId,
    required this.image,
    required this.titleEn,
    required this.titleAr,
    required this.brandEn,
    required this.brandAr,
    required this.price,
    required this.badgeEn,
    required this.badgeAr,
    this.oldPrice,
    this.metaEn = '',
    this.metaAr = '',
    this.quantity = 1,
  });

  final String image;
  final String? productId;
  final String? variantId;
  final String titleEn;
  final String titleAr;
  final String brandEn;
  final String brandAr;
  final String price;
  final String? oldPrice;
  final String badgeEn;
  final String badgeAr;
  final String metaEn;
  final String metaAr;
  final int quantity;

  String title(BuildContext context) =>
      _useArabicCopy(context) ? titleAr : titleEn;

  String brand(BuildContext context) =>
      _useArabicCopy(context) ? brandAr : brandEn;

  String badge(BuildContext context) =>
      _useArabicCopy(context) ? badgeAr : badgeEn;

  String meta(BuildContext context) =>
      _useArabicCopy(context) ? metaAr : metaEn;
}

double _moneyValue(String value) {
  return double.tryParse(
        value.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', ''),
      ) ??
      0;
}

Future<void> _launchOfferLink(
  BuildContext context,
  _PromoOfferData offer,
) async {
  final rawUrl = offer.linkUrl?.trim();
  final url = rawUrl == null ? null : Uri.tryParse(rawUrl);
  final messenger = ScaffoldMessenger.of(context);
  final isArabic = context.isArabicLanguage;

  if (url == null || !url.hasScheme) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(isArabic ? 'رابط الإعلان غير صالح' : 'Invalid ad link'),
      ),
    );
    return;
  }

  final didLaunch = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (didLaunch || !context.mounted) return;

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        isArabic ? 'تعذر فتح رابط الإعلان' : 'Could not open ad link',
      ),
    ),
  );
}
