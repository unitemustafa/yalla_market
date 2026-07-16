import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/formatters/app_currency.dart';
import '../../../../core/formatters/product_pricing.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../../../core/presentation/widgets/texts/green_currency_price.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/shared_content_links.dart';
import '../../../../core/utils/image_downloader.dart';
import '../../../../features/cart/domain/entities/cart_item.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../data/demo/demo_categories.dart';
import '../../data/demo/demo_shops.dart';
import '../cubit/product_discovery_cubit.dart';
import '../../domain/entities/category_data.dart';
import '../../domain/entities/product_data.dart';
import '../../domain/usecases/get_product_usecase.dart';
import '../../../wishlist/domain/entities/wishlist_item.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';

part 'product_detail_gallery_part.dart';
part 'product_detail_info_part.dart';
part 'product_detail_cart_part.dart';
part 'product_detail_dialogs_part.dart';
part 'product_detail_actions_part.dart';

List<String> _uniqueImageSources(Iterable<String> sources) {
  final images = <String>[];
  final seen = <String>{};

  for (final source in sources) {
    final image = source.trim();
    if (image.isEmpty || !seen.add(image)) continue;
    images.add(image);
  }

  return images;
}

String? _discountBadgeLabel(BuildContext context, String? discount) {
  final percentage = ProductPricing.discountLabel(discount);
  if (percentage == null) return null;
  return context.isArabicLanguage ? 'خصم $percentage' : '$percentage OFF';
}

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({
    super.key,
    required this.image,
    required this.title,
    required this.brand,
    required this.price,
    required this.productId,
    this.productSlug,
    this.oldPrice,
    this.discount,
    this.initialVariantId,
  });

  final String image, title, brand, price;
  final String productId;
  final String? productSlug;
  final String? oldPrice, discount;
  final String? initialVariantId;

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int quantity = 0;
  String? selectedVariantId;
  final Map<String, String> _selectedAttributeValues = <String, String>{};
  final Set<String> selectedAdditionIds = <String>{};
  late String currentImage;
  ProductData? _loadedProduct;
  bool _isLoadingProductDetails = true;
  Failure? _productLoadFailure;

  @override
  void initState() {
    super.initState();
    currentImage = widget.image;
    selectedVariantId = widget.initialVariantId;
    _loadProductDetails();
  }

  String get _productImage => _loadedProduct?.image ?? widget.image;
  String get _productTitle => _loadedProduct?.title ?? widget.title;
  String get _productBrand => _loadedProduct?.brand ?? widget.brand;
  String get _productPrice => _loadedProduct?.price ?? widget.price;
  String? get _productOldPrice => _loadedProduct?.oldPrice ?? widget.oldPrice;
  String? get _productDiscount => _loadedProduct?.discount ?? widget.discount;
  String get _productDescription {
    final description = _loadedProduct?.description.trim() ?? '';
    if (description.isNotEmpty) return description;
    return context.isArabicLanguage
        ? 'لا يوجد وصف متاح لهذا المنتج.'
        : 'No description available for this product.';
  }

  String get _productId => _loadedProduct?.id ?? widget.productId;
  String? get _marketId => _loadedProduct?.marketId;
  bool get _isProductAvailable => _loadedProduct?.isAvailable ?? true;
  List<ProductVariantData> get _variants =>
      _loadedProduct?.variants ?? const [];
  List<ProductAdditionData> get _productAdditions =>
      _loadedProduct?.additions ?? const [];
  List<ProductAdditionData> get _selectedAdditions => _productAdditions
      .where((addition) => selectedAdditionIds.contains(addition.id))
      .toList(growable: false);
  ProductVariantData? get _selectedVariant {
    final id = selectedVariantId?.trim();
    if (id == null || id.isEmpty) return null;
    for (final variant in _variants) {
      if (variant.id == id) return variant;
    }
    return null;
  }

  String get _selectedPrice {
    final variantPrice = _selectedVariant?.price.trim();
    if (variantPrice != null && variantPrice.isNotEmpty) return variantPrice;
    return _productPrice;
  }

  String get _selectedDisplayPrice =>
      ProductPricing.formattedPrice(_selectedPrice, discount: _productDiscount);

  String get _selectedOriginalPrice =>
      ProductPricing.originalPrice(_selectedPrice, discount: _productDiscount);

  String get _resolvedProductId => _productId;

  String get _productShareLink {
    return SharedContentLinks.product(_resolvedProductId);
  }

  String get _productShareText {
    final title = context.tr(_productTitle);
    final brand = context.tr(_productBrand);
    if (context.isArabicLanguage) {
      return 'شوف $title على يلا ماركت\n'
          'من $brand\n'
          'السعر: $_selectedDisplayPrice\n'
          '$_productShareLink';
    }
    return 'Check out $title on Yalla Market\n'
        'By $brand\n'
        'Price: $_selectedDisplayPrice\n'
        '$_productShareLink';
  }

  String get _resolvedCartItemId {
    final variantId = _selectedVariant?.id.trim();
    final baseId = variantId != null && variantId.isNotEmpty
        ? variantId
        : _resolvedProductId;
    if (selectedAdditionIds.isEmpty) return baseId;
    final additionsKey = selectedAdditionIds.toList()..sort();
    return '$baseId:additions:${additionsKey.join(',')}';
  }

  Future<void> _loadProductDetails() async {
    final id = widget.productId.trim();
    if (id.isEmpty) {
      setState(() {
        _isLoadingProductDetails = false;
        _productLoadFailure = const ValidationFailure('Missing product ID.');
      });
      return;
    }
    if (!sl.isRegistered<GetProductUseCase>()) {
      setState(() {
        _isLoadingProductDetails = false;
        _productLoadFailure = const UnknownFailure(
          'Product details service is unavailable.',
        );
      });
      return;
    }

    setState(() {
      _isLoadingProductDetails = true;
      _productLoadFailure = null;
    });
    final result = await sl<GetProductUseCase>()(id);
    if (!mounted) return;

    result.when(
      success: (product) {
        setState(() {
          _loadedProduct = product;
          _syncSelectedVariant(product);
          currentImage = product.images.first;
          _isLoadingProductDetails = false;
          _productLoadFailure = null;
        });
      },
      failure: (failure) {
        setState(() {
          _isLoadingProductDetails = false;
          _productLoadFailure = failure;
        });
      },
    );
  }

  void _syncSelectedVariant(ProductData product) {
    selectedAdditionIds.removeWhere(
      (id) => !product.additions.any((addition) => addition.id == id),
    );
    final variants = product.variants;
    if (variants.isEmpty) {
      selectedVariantId = null;
      _selectedAttributeValues.clear();
      return;
    }

    final selectedId = selectedVariantId?.trim();
    final selectedStillExists =
        selectedId != null &&
        selectedId.isNotEmpty &&
        variants.any((variant) => variant.id == selectedId);
    if (!selectedStillExists) {
      selectedVariantId = variants.length == 1 ? variants.first.id : null;
    }
    _selectedAttributeValues
      ..clear()
      ..addAll(_selectedVariant?.attributeValues ?? const {});
  }

  String _formatPrice(String? price) {
    return AppCurrency.formatPriceText(price);
  }

  String _formatSinglePrice(String? price) {
    return AppCurrency.formatPriceText(
      price?.split(RegExp(r'[-~]')).first.trim(),
    );
  }

  double _parsePrice(String? price) {
    if (price == null) return 0;
    final singlePrice = price.split(RegExp(r'[-~]')).first.trim();
    return double.tryParse(
          singlePrice.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', ''),
        ) ??
        0;
  }

  double get _selectedAdditionsTotal => _selectedAdditions.fold<double>(
    0,
    (total, addition) => total + _parsePrice(addition.price),
  );

  void _updateState(VoidCallback update) => setState(update);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loadedProduct == null) {
      final failure = _productLoadFailure;
      final isNotFound = failure?.statusCode == 404;
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: _isLoadingProductDetails
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNotFound
                            ? Icons.inventory_2_outlined
                            : Icons.wifi_off,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isNotFound
                            ? 'هذا المنتج غير متاح في مدينتك حاليًا.'
                            : 'تحقق من اتصال الإنترنت ثم حاول مرة أخرى.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProductDetails,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }
    final selectedPrice = _selectedPrice;
    final selectedUnitPrice =
        ProductPricing.firstPrice(selectedPrice, discount: _productDiscount) +
        _selectedAdditionsTotal;
    final variantAttributeNames = _variantOptionsByAttribute().keys;
    final hasCompleteSelection =
        variantAttributeNames.isNotEmpty &&
        variantAttributeNames.every(
          (name) => _selectedAttributeValues[name]?.trim().isNotEmpty ?? false,
        );
    final hasUnavailableCombination =
        _variants.length > 1 &&
        _hasVariantAttributes() &&
        hasCompleteSelection &&
        selectedVariantId == null;
    final isOutOfStock =
        !_isProductAvailable ||
        _variants.isEmpty ||
        (_variants.length > 1 && selectedVariantId == null);
    final productIsAvailable = _isProductAvailable && _variants.isNotEmpty;
    final stock = productIsAvailable ? 'Available' : 'Out of Stock';
    final stockColor = productIsAvailable ? AppColors.success : AppColors.error;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final isFavorite = context.watch<WishlistCubit>().isFavorite(
      _resolvedProductId,
    );
    final thumbnailImages = _uniqueImageSources(_loadedProduct!.images);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductGallery(
              isDark: isDark,
              currentImage: currentImage,
              thumbnailImages: thumbnailImages,
              isFavorite: isFavorite,
              onBack: () => Navigator.pop(context),
              onShare: _showProductShareSheet,
              onImageTap: () => _showImageDialog(context, currentImage),
              onWishlistTap: () => _toggleWishlist(context, isFavorite),
              onThumbnailTap: (asset) => setState(() => currentImage = asset),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PriceHeader(
                    discount: _discountBadgeLabel(context, _productDiscount),
                    price: _selectedDisplayPrice,
                    oldPrice: _selectedOriginalPrice.isNotEmpty
                        ? _selectedOriginalPrice
                        : _formatPrice(_productOldPrice),
                    isDark: isDark,
                  ),
                  if (_isLoadingProductDetails) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (_variants.isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'هذا المنتج غير متاح للطلب حاليًا.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    context.tr(_productTitle),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontSize: 23,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusPill(
                        label: stock,
                        color: stockColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _BrandPill(brand: _productBrand, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildVariantSelectors(isDark: isDark),
                  if (hasUnavailableCombination) ...[
                    const SizedBox(height: 4),
                    Text(
                      'هذا الاختيار غير متاح حاليًا.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (_productAdditions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildAdditionsButton(
                      isDark: isDark,
                      mutedColor: mutedColor,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _InfoCard(
                    isDark: isDark,
                    title: 'Description',
                    child: Text(
                      _productDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomAddToCartBar(
        isDark: isDark,
        quantity: quantity,
        price: selectedUnitPrice,
        isOutOfStock: isOutOfStock,
        onDecrease: () {
          if (quantity > 0) setState(() => quantity--);
        },
        onIncrease: () {
          if (isOutOfStock) {
            CustomSnackBar.showWarning(
              context: context,
              title: 'Product is out of stock',
            );
            return;
          }
          setState(() => quantity++);
        },
        onAddToCart: () => _addSelectedProductToCart(
          context: context,
          isOutOfStock: isOutOfStock,
        ),
      ),
    );
  }
}
