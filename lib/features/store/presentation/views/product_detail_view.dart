import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/demo/demo_categories.dart';
import '../../data/demo/demo_shops.dart';
import '../../../../core/formatters/app_currency.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../../../core/presentation/widgets/texts/green_currency_price.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/image_downloader.dart';
import '../../../../features/cart/domain/entities/cart_item.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../cubit/product_discovery_cubit.dart';
import '../../domain/entities/category_data.dart';
import '../../domain/entities/product_data.dart';
import '../../domain/usecases/get_product_usecase.dart';
import '../../../wishlist/domain/entities/wishlist_item.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';

part 'product_detail_gallery_part.dart';
part 'product_detail_info_part.dart';
part 'product_detail_cart_part.dart';

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

String? _validDiscountLabel(String? discount) {
  final value = discount?.trim();
  if (value == null || value.isEmpty) return null;

  final numericValue = double.tryParse(
    value.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', ''),
  );
  if (numericValue != null && numericValue <= 0) return null;

  return value;
}

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({
    super.key,
    required this.image,
    required this.title,
    required this.brand,
    required this.price,
    this.productId,
    this.productSlug,
    this.oldPrice,
    this.discount,
  });

  final String image, title, brand, price;
  final String? productId, productSlug;
  final String? oldPrice, discount;

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int quantity = 0;
  String? selectedVariantId;
  late String currentImage;
  ProductData? _loadedProduct;
  bool _isLoadingProductDetails = false;

  @override
  void initState() {
    super.initState();
    currentImage = widget.image;
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

  String? get _productId => _loadedProduct?.id ?? widget.productId;
  String? get _marketId => _loadedProduct?.marketId;
  bool get _isProductAvailable => _loadedProduct?.isAvailable ?? true;
  List<ProductVariantData> get _variants =>
      _loadedProduct?.variants ?? const [];
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

  String get _resolvedProductId {
    final productId = _productId?.trim();
    if (productId != null && productId.isNotEmpty) return productId;
    // TODO: Pass productId from all product sources instead of falling back.
    return _productTitle;
  }

  String get _resolvedCartItemId {
    final variantId = _selectedVariant?.id.trim();
    if (variantId != null && variantId.isNotEmpty) return variantId;
    return _resolvedProductId;
  }

  Future<void> _loadProductDetails() async {
    final id = widget.productId?.trim();
    if (id == null || id.isEmpty || _isLoadingProductDetails) return;
    if (!sl.isRegistered<GetProductUseCase>()) return;

    _isLoadingProductDetails = true;
    final result = await sl<GetProductUseCase>()(id);
    if (!mounted) return;

    result.when(
      success: (product) {
        setState(() {
          _loadedProduct = product;
          _syncSelectedVariant(product);
          if (currentImage == widget.image) currentImage = product.image;
          _isLoadingProductDetails = false;
        });
      },
      failure: (_) {
        setState(() => _isLoadingProductDetails = false);
      },
    );
  }

  void _syncSelectedVariant(ProductData product) {
    final variants = product.variants;
    if (variants.isEmpty) {
      selectedVariantId = null;
      return;
    }

    final selectedId = selectedVariantId?.trim();
    final selectedStillExists =
        selectedId != null &&
        selectedId.isNotEmpty &&
        variants.any((variant) => variant.id == selectedId);
    if (!selectedStillExists) selectedVariantId = variants.first.id;
  }

  String _formatPrice(String? price) {
    return AppCurrency.formatPriceText(price);
  }

  String _formatSinglePrice(String? price) {
    return AppCurrency.formatPriceText(price?.split('-').first.trim());
  }

  double _parsePrice(String? price) {
    if (price == null) return 0;
    final singlePrice = price.split('-').first.trim();
    return double.tryParse(
          singlePrice.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll(',', ''),
        ) ??
        0;
  }

  void _showImageDialog(BuildContext context, String imagePath) {
    final pageContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardColor : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF3F5FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: AppImage(
                      source: imagePath,
                      fit: BoxFit.contain,
                      fallback: const Icon(AppIcons.image),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(pageContext.tr('Close')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final fileName = _imageFileName(imagePath);
                          final didDownload = await downloadAssetImage(
                            imagePath,
                            fileName,
                          );

                          if (!pageContext.mounted || !dialogContext.mounted) {
                            return;
                          }
                          Navigator.pop(dialogContext);

                          if (didDownload) {
                            CustomSnackBar.showSuccess(
                              context: pageContext,
                              title: 'Image download started',
                              message: fileName,
                            );
                          } else {
                            CustomSnackBar.showInfo(
                              context: pageContext,
                              title: 'Download unavailable here',
                              message: 'Try it from the web preview.',
                            );
                          }
                        },
                        icon: const Icon(AppIcons.document_download, size: 18),
                        label: Text(pageContext.tr('Download')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _imageFileName(String imagePath) {
    final uri = Uri.tryParse(imagePath);
    final path = uri?.path ?? imagePath;
    final name = path.split('/').where((part) => part.isNotEmpty).lastOrNull;
    return name == null || name.isEmpty ? 'image' : name;
  }

  Map<String, List<String>> _variantOptionsByAttribute() {
    final optionsByAttribute = <String, List<String>>{};
    final seenOptions = <String, Set<String>>{};

    for (final variant in _variants) {
      for (final entry in variant.attributeValues.entries) {
        final attribute = entry.key.trim();
        final option = entry.value.trim();
        if (attribute.isEmpty || option.isEmpty) continue;

        final seen = seenOptions.putIfAbsent(attribute, () => <String>{});
        if (!seen.add(option)) continue;
        optionsByAttribute.putIfAbsent(attribute, () => <String>[]).add(option);
      }
    }

    return optionsByAttribute;
  }

  bool _hasVariantAttributes() {
    return _variants.any((variant) => variant.attributeValues.isNotEmpty);
  }

  void _selectVariantOption(String attribute, String option) {
    final selectedAttributes = Map<String, String>.from(
      _selectedVariant?.attributeValues ?? const {},
    );
    selectedAttributes[attribute] = option;

    ProductVariantData? bestMatch;
    for (final variant in _variants) {
      final matchesRequestedOption =
          variant.attributeValues[attribute] == option;
      final matchesOtherSelections = selectedAttributes.entries.every((entry) {
        final value = variant.attributeValues[entry.key];
        return value == null || value == entry.value;
      });
      if (matchesRequestedOption && matchesOtherSelections) {
        bestMatch = variant;
        break;
      }
    }

    bestMatch ??= _variants.firstWhere(
      (variant) => variant.attributeValues[attribute] == option,
      orElse: () => _variants.first,
    );

    setState(() => selectedVariantId = bestMatch?.id);
  }

  String _variantFallbackLabel(ProductVariantData variant, int index) {
    final sku = variant.sku?.trim();
    final label = sku != null && sku.isNotEmpty ? sku : 'Option ${index + 1}';
    final price = _formatSinglePrice(variant.price);
    return price.isEmpty ? label : '$label - $price';
  }

  void _toggleWishlist(BuildContext context, bool wasFavorite) {
    context.read<WishlistCubit>().toggleItem(
      WishlistItem(
        productId: _resolvedProductId,
        image: _productImage,
        title: _productTitle,
        brand: _productBrand,
        price: _productPrice,
        oldPrice: _productOldPrice,
        discount: _validDiscountLabel(_productDiscount),
      ),
    );

    if (wasFavorite) {
      CustomSnackBar.showRemoved(
        context: context,
        title: 'Item removed from wishlist',
      );
    } else {
      CustomSnackBar.showAdded(
        context: context,
        title: 'Item added to wishlist',
      );
    }
  }

  void _addSelectedProductToCart({
    required BuildContext context,
    required bool isOutOfStock,
  }) {
    if (isOutOfStock) {
      CustomSnackBar.showWarning(
        context: context,
        title: 'Product is out of stock',
      );
      return;
    }

    if (quantity == 0) {
      CustomSnackBar.showWarning(
        context: context,
        title: 'Select quantity first',
      );
      return;
    }

    final selectedVariant = _selectedVariant;
    final selectedVariantId = selectedVariant?.id.trim();
    final selectedPrice = selectedVariant?.price ?? _selectedPrice;

    context.read<CartCubit>().addItem(
      CartItemData(
        id: _resolvedCartItemId,
        productId: _resolvedProductId,
        variantId: selectedVariantId == null || selectedVariantId.isEmpty
            ? null
            : selectedVariantId,
        marketId: _marketId,
        marketName: _productBrand,
        image: currentImage,
        brand: _productBrand,
        title: _productTitle,
        price: _parsePrice(selectedPrice),
        quantity: quantity,
        attributes:
            selectedVariant?.attributeValues.entries
                .map(
                  (entry) =>
                      CartItemAttribute(label: entry.key, value: entry.value),
                )
                .toList(growable: false) ??
            const [],
      ),
      quantity,
    );

    CustomSnackBar.showAdded(
      context: context,
      title: context.isArabicLanguage
          ? 'تمت إضافة ${context.productCount(quantity)} للسلة'
          : '${context.productCount(quantity)} added to cart',
    );
    setState(() => quantity = 0);
  }

  Widget _buildVariantSelectors({required bool isDark}) {
    if (_variants.length <= 1) return const SizedBox.shrink();

    if (!_hasVariantAttributes()) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Options', isDark: isDark),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < _variants.length; index++)
                _buildChoiceOption(
                  label: _variantFallbackLabel(_variants[index], index),
                  isSelected: selectedVariantId == _variants[index].id,
                  onTap: () =>
                      setState(() => selectedVariantId = _variants[index].id),
                ),
            ],
          ),
        ],
      );
    }

    final optionsByAttribute = _variantOptionsByAttribute();
    if (optionsByAttribute.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in optionsByAttribute.entries) ...[
          _SectionTitle(title: entry.key, isDark: isDark),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in entry.value)
                _buildChoiceOption(
                  label: option,
                  isSelected:
                      _selectedVariant?.attributeValues[entry.key] == option,
                  onTap: () => _selectVariantOption(entry.key, option),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedPrice = _selectedPrice;
    final isOutOfStock = !_isProductAvailable;
    final stock = isOutOfStock ? 'Out of Stock' : 'Available';
    final stockColor = isOutOfStock ? AppColors.error : AppColors.success;
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
    final thumbnailImages = _uniqueImageSources([
      _productImage,
      AppAssets.temporaryMarketPlaceholder,
      AppAssets.tshirtBlueNoCollarFront,
      AppAssets.samsungS9Mobile,
    ]);

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
                    discount: _validDiscountLabel(_productDiscount),
                    price: _formatSinglePrice(selectedPrice),
                    oldPrice: _formatPrice(_productOldPrice),
                    isDark: isDark,
                  ),
                  if (_isLoadingProductDetails) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
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
                  const SizedBox(height: 18),
                  _VariationCard(
                    price: _formatSinglePrice(selectedPrice),
                    oldPrice: _formatSinglePrice(_productOldPrice),
                    stock: stock,
                    stockColor: stockColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildVariantSelectors(isDark: isDark),
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
        price: _parsePrice(selectedPrice),
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

  Widget _buildChoiceOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkCardColor : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.ltr,
            children: [
              Flexible(
                child: Text(
                  context.tr(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.lightTextPrimary),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check, color: Colors.white, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
