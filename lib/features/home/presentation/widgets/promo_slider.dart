import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/formatters/app_currency.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/sheets/content_share_sheet.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../../../core/presentation/widgets/texts/green_currency_price.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/shared_content_links.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/entities/home_data.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import '../../../store/domain/entities/product_data.dart';

part 'promo_slider_card_part.dart';
part 'promo_slider_sheet_part.dart';
part 'promo_slider_panels_part.dart';
part 'promo_slider_models_part.dart';

class PromoSlider extends StatefulWidget {
  const PromoSlider({super.key, this.offers, this.focusOfferId});

  final List<HomeOfferData>? offers;
  final String? focusOfferId;

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  bool _handledFocusedOffer = false;
  Timer? _autoAdvanceTimer;
  Timer? _expiryTimer;
  String? _scheduledOfferKey;
  DateTime? _scheduledExpiry;
  static const _offers = [
    _PromoOfferData(
      icon: AppIcons.box,
      color: AppColors.primary,
      image: AppAssets.temporaryMarketPlaceholder,
      endsAtIso: '2026-06-30T23:59:00+03:00',
      badgeEn: 'Package',
      badgeAr: 'باكج',
      titleEn: 'Weekly Package',
      titleAr: 'باكج الأسبوع',
      subtitleEn: 'Three essentials together with one bundle discount.',
      subtitleAr: 'ثلاث منتجات أساسية مع خصم باكج واحد.',
      valueEn: 'Save EGP 86',
      valueAr: 'وفر EGP 86',
      statusEn: '3 products together',
      statusAr: '3 منتجات مع بعض',
      detailEn:
          'The package price applies only when all items are ordered in the same basket.',
      detailAr: 'سعر الباكج بيتطبق لما كل المنتجات تتطلب في نفس السلة.',
      subtotal: 'EGP 355',
      discount: 'EGP 86',
      discountRateEn: '24% off',
      discountRateAr: 'خصم 24%',
      afterDiscount: 'EGP 269',
      deliveryFee: 'غير محدد',
      total: 'EGP 269',
      actionEn: 'Add package to cart',
      visibilityMode: 'general',
      actionAr: 'ضيف الباكج للسلة',
      products: [
        _OfferProduct(
          image: AppAssets.temporaryMarketPlaceholder,
          titleEn: 'Fresh vegetable basket',
          titleAr: 'سلة خضار طازجة',
          brandEn: 'Vegetables',
          brandAr: 'خضار',
          price: 'EGP 120',
          badgeEn: 'Bundle',
          badgeAr: 'باكج',
        ),
        _OfferProduct(
          image: AppAssets.temporaryMarketPlaceholder,
          titleEn: 'Morning bakery box',
          titleAr: 'مخبوزات صباحية',
          brandEn: 'Bakery',
          brandAr: 'مخبوزات',
          price: 'EGP 89',
          badgeEn: 'Bundle',
          badgeAr: 'باكج',
        ),
        _OfferProduct(
          image: AppAssets.temporaryMarketPlaceholder,
          titleEn: 'Daily supermarket pack',
          titleAr: 'باقة سوبر ماركت يومية',
          brandEn: 'Supermarket',
          brandAr: 'سوبر ماركت',
          price: 'EGP 60',
          badgeEn: 'Bundle',
          badgeAr: 'باكج',
        ),
      ],
    ),
    _PromoOfferData(
      icon: AppIcons.flash_1,
      color: AppColors.warning,
      image: AppAssets.temporaryMarketPlaceholder,
      endsAtIso: '2026-06-20T23:59:00+03:00',
      badgeEn: 'Flash',
      badgeAr: 'فلاش',
      titleEn: 'Flash Sale',
      titleAr: 'فلاش سيل',
      subtitleEn: 'One fast offer on a selected item for a short time.',
      subtitleAr: 'عرض سريع على منتج محدد لمدة قليلة.',
      valueEn: 'Live timer',
      valueAr: 'تايمر مباشر',
      statusEn: 'Limited stock',
      statusAr: 'كمية محدودة',
      detailEn:
          'This flash price is held only during the timer and while stock lasts.',
      detailAr: 'سعر الفلاش ثابت خلال مدة العرض فقط ومع توفر الكمية.',
      subtotal: 'EGP 220',
      discount: 'EGP 60',
      discountRateEn: '33% off',
      discountRateAr: 'خصم 33%',
      afterDiscount: 'EGP 160',
      deliveryFee: 'غير محدد',
      total: 'EGP 160',
      actionEn: 'Add flash offer',
      visibilityMode: 'regions',
      regionSlugs: ['sharm-el-sheikh'],
      regionNames: ['Sharm El Sheikh'],
      actionAr: 'ضيف عرض الفلاش',
      products: [
        _OfferProduct(
          image: AppAssets.temporaryMarketPlaceholder,
          titleEn: 'Family meal box',
          titleAr: 'وجبة عائلية جاهزة',
          brandEn: 'Restaurants',
          brandAr: 'مطاعم',
          price: 'EGP 160',
          oldPrice: 'EGP 220',
          badgeEn: '33% off',
          badgeAr: 'خصم 33%',
          metaEn: '8 left',
          metaAr: 'باقي 8',
        ),
      ],
    ),
    _PromoOfferData(
      icon: AppIcons.truck_fast,
      color: AppColors.info,
      image: AppAssets.temporaryMarketPlaceholder,
      endsAtIso: '2026-06-28T23:59:00+03:00',
      badgeEn: 'Delivery',
      badgeAr: 'توصيل',
      titleEn: 'Free Delivery',
      titleAr: 'توصيل مجاني',
      subtitleEn: 'Free delivery is unlocked for this selected product.',
      subtitleAr: 'التوصيل المجاني متاح على المنتج ده.',
      valueEn: 'Delivery EGP 0',
      valueAr: 'التوصيل EGP 0',
      statusEn: 'Free delivery item',
      statusAr: 'منتج بتوصيل مجاني',
      detailEn:
          'The delivery fee is removed automatically when this item is in your basket.',
      detailAr: 'رسوم التوصيل بتتشال تلقائيا لما المنتج ده يكون في السلة.',
      subtotal: 'EGP 150',
      discount: 'EGP 0',
      discountRateEn: 'Free delivery',
      discountRateAr: 'توصيل مجاني',
      afterDiscount: 'EGP 150',
      deliveryFee: 'غير محدد',
      total: 'EGP 150',
      actionEn: 'Add free delivery item',
      visibilityMode: 'general',
      actionAr: 'ضيف منتج التوصيل المجاني',
      products: [
        _OfferProduct(
          image: AppAssets.temporaryMarketPlaceholder,
          titleEn: 'Fresh country chicken',
          titleAr: 'دجاج طازج بلدي',
          brandEn: 'Poultry',
          brandAr: 'طيور',
          price: 'EGP 150',
          oldPrice: 'EGP 150',
          badgeEn: 'Free delivery',
          badgeAr: 'توصيل مجاني',
          metaEn: 'Delivery saved',
          metaAr: 'وفرت التوصيل',
        ),
      ],
    ),
    _PromoOfferData(
      icon: AppIcons.notification,
      color: AppColors.success,
      image: AppAssets.temporaryMarketPlaceholder,
      endsAtIso: '2026-07-03T23:59:00+03:00',
      badgeEn: 'Ad',
      badgeAr: 'إعلان',
      titleEn: 'Sponsored Market Pick',
      titleAr: 'عرض إعلاني مختار',
      subtitleEn: 'A promoted deal shown with the same offer layout.',
      subtitleAr: 'عرض ممول ظاهر مع نفس شكل العروض.',
      valueEn: 'Sponsored',
      valueAr: 'إعلان',
      statusEn: 'Sponsored placement',
      statusAr: 'عرض إعلاني',
      detailEn:
          'This promoted offer keeps the same checkout flow and timer behavior.',
      detailAr: 'العرض الإعلاني بيظهر بنفس تجربة الشراء والتايمر.',
      subtotal: 'EGP 300',
      discount: 'EGP 30',
      discountRateEn: '10% off',
      discountRateAr: 'خصم 10%',
      afterDiscount: 'EGP 270',
      deliveryFee: 'غير محدد',
      total: 'EGP 270',
      actionEn: 'Add sponsored offer',
      visibilityMode: 'general',
      actionAr: 'ضيف العرض الإعلاني',
      products: [
        _OfferProduct(
          image: AppAssets.temporaryMarketPlaceholder,
          titleEn: 'Sponsored grocery selection',
          titleAr: 'اختيارات بقالة ممولة',
          brandEn: 'Yalla Ads',
          brandAr: 'إعلانات يلا',
          price: 'EGP 270',
          oldPrice: 'EGP 300',
          badgeEn: 'Ad deal',
          badgeAr: 'عرض إعلان',
          metaEn: 'Featured today',
          metaAr: 'مميز اليوم',
        ),
      ],
    ),
    _PromoOfferData(
      icon: AppIcons.global,
      color: AppColors.info,
      image: AppAssets.temporaryMarketPlaceholder,
      endsAtIso: '2026-07-04T23:59:00+03:00',
      badgeEn: 'Ad link',
      badgeAr: 'إعلان برابط',
      titleEn: 'Partner Link Deal',
      titleAr: 'إعلان برابط شريك',
      subtitleEn: 'Tap the offer link to view the partner campaign.',
      subtitleAr: 'اضغط على رابط العرض وشوف حملة الشريك.',
      valueEn: 'Link offer',
      valueAr: 'رابط عرض',
      statusEn: 'Sponsored link',
      statusAr: 'إعلان برابط',
      detailEn: 'This ad includes a visible campaign link inside the offer.',
      detailAr: 'الإعلان ده فيه رابط حملة واضح داخل العرض.',
      subtotal: 'EGP 420',
      discount: 'EGP 70',
      discountRateEn: '17% off',
      discountRateAr: 'خصم 17%',
      afterDiscount: 'EGP 350',
      deliveryFee: 'غير محدد',
      total: 'EGP 350',
      actionEn: 'Add linked ad offer',
      visibilityMode: 'general',
      actionAr: 'ضيف عرض الإعلان بالرابط',
      linkUrl: 'https://yalla.market/offers/partner-link',
      linkLabelEn: 'yalla.market/offers/partner-link',
      linkLabelAr: 'yalla.market/offers/partner-link',
      products: [
        _OfferProduct(
          image: AppAssets.temporaryMarketPlaceholder,
          titleEn: 'Partner campaign grocery bundle',
          titleAr: 'باكج بقالة حملة الشريك',
          brandEn: 'Partner Ad',
          brandAr: 'إعلان شريك',
          price: 'EGP 350',
          oldPrice: 'EGP 420',
          badgeEn: 'Linked ad',
          badgeAr: 'إعلان برابط',
          metaEn: 'Campaign link',
          metaAr: 'رابط حملة',
        ),
      ],
    ),
    _PromoOfferData(
      icon: AppIcons.receipt_text,
      color: AppColors.error,
      image: AppAssets.samsungS9Mobile,
      endsAtIso: '2026-07-05T23:59:00+03:00',
      badgeEn: 'Discount',
      badgeAr: 'خصم',
      titleEn: 'Extra Discount',
      titleAr: 'خصم إضافي',
      subtitleEn: 'A direct discount on one selected product.',
      subtitleAr: 'خصم مباشر على منتج محدد.',
      valueEn: '15% off',
      valueAr: 'خصم 15%',
      statusEn: 'Discount active',
      statusAr: 'خصم نشط',
      detailEn:
          'The discount is included in the price below and confirmed in the order summary.',
      detailAr: 'الخصم متحسب في السعر تحت وبيتأكد في ملخص الطلب.',
      subtotal: 'EGP 480',
      discount: 'EGP 100',
      discountRateEn: '21% off',
      discountRateAr: 'خصم 21%',
      afterDiscount: 'EGP 380',
      deliveryFee: 'غير محدد',
      total: 'EGP 380',
      actionEn: 'Add discounted item',
      visibilityMode: 'regions',
      regionSlugs: ['sharm-el-sheikh'],
      regionNames: ['Sharm El Sheikh'],
      actionAr: 'ضيف المنتج المخفض',
      products: [
        _OfferProduct(
          image: AppAssets.samsungS9Mobile,
          titleEn: 'Smart phone with warranty',
          titleAr: 'موبايل ذكي بضمان',
          brandEn: 'Electronics',
          brandAr: 'أجهزة إلكترونية',
          price: 'EGP 380',
          oldPrice: 'EGP 480',
          badgeEn: '21% off',
          badgeAr: 'خصم 21%',
          metaEn: 'Selected deal',
          metaAr: 'عرض مختار',
        ),
      ],
    ),
  ];

  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _expiryTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleExpiryRefresh(List<_PromoOfferData> offers) {
    final now = DateTime.now();
    DateTime? nextExpiry;
    for (final offer in offers) {
      final endsAt = offer.endsAt;
      if (endsAt == null || !endsAt.isAfter(now)) continue;
      if (nextExpiry == null || endsAt.isBefore(nextExpiry)) {
        nextExpiry = endsAt;
      }
    }

    if (nextExpiry == _scheduledExpiry) return;
    _expiryTimer?.cancel();
    _scheduledExpiry = nextExpiry;
    if (nextExpiry == null) return;

    _expiryTimer = Timer(
      nextExpiry.difference(now) + const Duration(milliseconds: 50),
      () {
        if (!mounted) return;
        setState(() {
          _currentIndex = 0;
          _scheduledOfferKey = null;
        });
      },
    );
  }

  void _scheduleAutoAdvance(List<_PromoOfferData> offers) {
    if (offers.length < 2) return;
    final currentOffer = offers[_currentIndex];
    final seconds = currentOffer.displaySeconds.clamp(1, 120);
    final key = '${currentOffer.offerId ?? _currentIndex}:$seconds';
    if (key == _scheduledOfferKey) return;

    _scheduledOfferKey = key;
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || !_pageController.hasClients) return;
      final nextIndex = (_currentIndex + 1) % offers.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _showOfferSheet(BuildContext context, _PromoOfferData offer) {
    if (offer.hasExternalLink) {
      unawaited(_launchOfferLink(context, offer));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PromoOfferSheet(offer: offer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final regionKey = context.select<LocationCubit, String>((cubit) {
      final city = cubit.state.selectedCity;
      if (city == null || city.isGeneral) return 'general';
      return city.serviceCityId?.toString() ?? city.slug;
    });
    final offers = _visibleOffers(regionKey, widget.offers);
    if (_currentIndex >= offers.length && offers.isNotEmpty) {
      _currentIndex = 0;
    }
    _scheduleExpiryRefresh(offers);
    if (offers.isEmpty) return const SizedBox.shrink();
    _scheduleAutoAdvance(offers);
    final focusOfferId = widget.focusOfferId;
    if (!_handledFocusedOffer &&
        focusOfferId != null &&
        focusOfferId.isNotEmpty) {
      final focusedIndex = offers.indexWhere(
        (offer) => offer.offerId == focusOfferId,
      );
      if (focusedIndex >= 0) {
        _handledFocusedOffer = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _pageController.jumpToPage(focusedIndex);
          _showOfferSheet(context, offers[focusedIndex]);
        });
      }
    }

    return Column(
      children: [
        RepaintBoundary(
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount: offers.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _scheduledOfferKey = null;
                });
                _scheduleAutoAdvance(offers);
              },
              itemBuilder: (context, index) {
                final offer = offers[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: _PromoOfferCard(
                    offer: offer,
                    onTap: () => _showOfferSheet(context, offer),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(offers.length, (index) {
            final isSelected = _currentIndex == index;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: isSelected ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }

  List<_PromoOfferData> _visibleOffers(
    String regionSlug,
    List<HomeOfferData>? apiOffers,
  ) {
    final normalized = regionSlug.trim().toLowerCase();
    final hasRemoteOffers = apiOffers != null;
    final source = hasRemoteOffers
        ? apiOffers.map(_offerFromApi).toList(growable: false)
        : AppEnvironment.useDemoRepositories
        ? _offers
        : const <_PromoOfferData>[];

    return source
        .where((offer) {
          final endsAt = offer.endsAt;
          if (endsAt != null && !endsAt.isAfter(DateTime.now())) return false;
          // The server already applies the authenticated customer's selected
          // market region, offer status, schedule, and usage limits. Repeating
          // that filter in the app can hide a valid freshly delivered offer.
          if (hasRemoteOffers) return true;
          if (normalized.isEmpty || normalized == 'general') {
            return offer.showInGeneral || offer.isGeneralVisibility;
          }
          if (offer.regionSlugs.isEmpty) return false;
          return offer.regionSlugs.contains(normalized);
        })
        .toList(growable: false);
  }

  _PromoOfferData _offerFromApi(HomeOfferData offer) {
    final type = offer.type.trim().toLowerCase();
    final products = offer.products.map(_offerProductFromApi).toList();
    final subtotalValue = offer.products.fold<double>(
      0,
      (sum, product) =>
          sum + (product.offerUnitPriceValue * product.offerQuantity),
    );
    final discountValue = double.tryParse(offer.discount) ?? 0;
    final totalValue = subtotalValue <= 0
        ? 0
        : subtotalValue * (1 - (discountValue / 100));
    final discountAmount = (subtotalValue - totalValue).clamp(0, subtotalValue);
    final discountLabel = offer.discountLabel;
    final isAnnouncement = type == 'announcement';
    final title = offer.title.trim().isEmpty ? 'Offer' : offer.title.trim();
    final marketLabel = offer.isMultiMarket
        ? 'متعدد المحلات'
        : offer.marketName;
    final description = offer.description.trim().isEmpty
        ? title
        : offer.description.trim();

    return _PromoOfferData(
      offerId: offer.id,
      icon: _iconForApiOffer(type),
      color: _colorForApiOffer(type),
      image: offer.image,
      endsAtIso: offer.endsAt?.toIso8601String(),
      badgeEn: _badgeForApiOffer(type),
      badgeAr: _badgeForApiOffer(type, arabic: true),
      titleEn: title,
      titleAr: title,
      subtitleEn: description,
      subtitleAr: description,
      valueEn: isAnnouncement
          ? 'Advertisement'
          : (discountLabel.isEmpty ? marketLabel : discountLabel),
      valueAr: isAnnouncement
          ? 'إعلان'
          : (discountLabel.isEmpty ? marketLabel : discountLabel),
      statusEn: isAnnouncement
          ? 'External campaign'
          : (marketLabel.isEmpty ? 'Active offer' : marketLabel),
      statusAr: isAnnouncement
          ? 'حملة خارجية'
          : (offer.marketName.isEmpty ? 'عرض نشط' : offer.marketName),
      detailEn: description,
      detailAr: description,
      subtotal: AppCurrency.format(subtotalValue, fractionDigits: 0),
      discount: AppCurrency.format(discountAmount, fractionDigits: 0),
      discountRateEn: discountLabel,
      discountRateAr: _arabicDiscountLabel(discountLabel),
      afterDiscount: AppCurrency.format(totalValue, fractionDigits: 0),
      deliveryFee: 'غير محدد',
      total: AppCurrency.format(totalValue, fractionDigits: 0),
      actionEn: isAnnouncement && offer.announcementCtaLabel.isNotEmpty
          ? offer.announcementCtaLabel
          : 'Open campaign',
      actionAr: isAnnouncement && offer.announcementCtaLabel.isNotEmpty
          ? offer.announcementCtaLabel
          : 'فتح الإعلان',
      products: products.isEmpty
          ? [
              _OfferProduct(
                image: offer.image,
                titleEn: title,
                titleAr: title,
                brandEn: marketLabel,
                brandAr: marketLabel,
                price: AppCurrency.format(totalValue, fractionDigits: 0),
                badgeEn: discountLabel,
                badgeAr: _arabicDiscountLabel(discountLabel),
              ),
            ]
          : products,
      visibilityMode: offer.serviceCityIds.isEmpty ? 'general' : 'regions',
      showInGeneral: offer.showInGeneral,
      regionSlugs: offer.serviceCityIds
          .map((id) => id.toString())
          .toList(growable: false),
      regionNames: offer.serviceCityNames,
      linkUrl: isAnnouncement ? offer.announcementUrl : null,
      linkLabelEn: isAnnouncement ? offer.announcementCtaLabel : null,
      linkLabelAr: isAnnouncement ? offer.announcementCtaLabel : null,
      displaySeconds: isAnnouncement ? offer.announcementDisplaySeconds : 5,
    );
  }

  _OfferProduct _offerProductFromApi(ProductData product) {
    final discount = product.applyProductDiscount
        ? product.discount.trim()
        : '';
    final selectedVariantId = product.offerVariantId?.trim().isNotEmpty == true
        ? product.offerVariantId!.trim()
        : product.defaultVariantId;
    ProductVariantData? selectedVariant;
    for (final variant in product.variants) {
      if (variant.id == selectedVariantId) {
        selectedVariant = variant;
        break;
      }
    }
    final variantDescription =
        selectedVariant?.attributeValues.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' / ') ??
        '';
    final quantityDescription = product.offerQuantity > 1
        ? '× ${product.offerQuantity}'
        : '';
    final meta = [
      variantDescription,
      quantityDescription,
    ].where((value) => value.isNotEmpty).join(' · ');
    return _OfferProduct(
      productId: product.id,
      variantId: selectedVariantId,
      image: product.image,
      titleEn: product.title,
      titleAr: product.title,
      brandEn: product.brand,
      brandAr: product.brand,
      price: AppCurrency.format(product.offerUnitPriceValue, fractionDigits: 2),
      oldPrice:
          product.applyProductDiscount && _moneyValue(product.discount) > 0
          ? AppCurrency.format(product.offerBasePriceValue, fractionDigits: 2)
          : product.oldPrice,
      badgeEn: discount,
      badgeAr: discount,
      metaEn: meta.isNotEmpty ? meta : (product.code ?? ''),
      metaAr: meta.isNotEmpty ? meta : (product.code ?? ''),
      quantity: product.offerQuantity,
    );
  }

  IconData _iconForApiOffer(String type) {
    return switch (type) {
      'flash' => AppIcons.flash_1,
      'delivery' => AppIcons.truck_fast,
      'discount' => AppIcons.receipt_text,
      'package' => AppIcons.box,
      'announcement' => AppIcons.global,
      _ => AppIcons.box,
    };
  }

  Color _colorForApiOffer(String type) {
    return switch (type) {
      'flash' => AppColors.warning,
      'delivery' => AppColors.info,
      'discount' => AppColors.error,
      'package' => AppColors.primary,
      'announcement' => AppColors.info,
      _ => AppColors.primary,
    };
  }

  String _badgeForApiOffer(String type, {bool arabic = false}) {
    return switch (type) {
      'flash' => arabic ? 'عرض سريع' : 'Flash',
      'delivery' => arabic ? 'توصيل' : 'Delivery',
      'discount' => arabic ? 'خصم' : 'Discount',
      'package' => arabic ? 'باكج' : 'Package',
      'announcement' => arabic ? 'إعلان' : 'Announcement',
      _ => arabic ? 'عرض' : 'Offer',
    };
  }
}

String _arabicDiscountLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;

  final normalized = trimmed.toLowerCase();
  if (!normalized.contains('discount') && !normalized.contains('off')) {
    return trimmed;
  }

  final percentage = RegExp(r'(\d+(?:[.,]\d+)?\s*%)').firstMatch(trimmed);
  return percentage == null ? 'خصم' : 'خصم ${percentage.group(1)}';
}
