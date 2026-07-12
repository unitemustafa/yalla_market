import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/formatters/app_currency.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../../../core/presentation/widgets/texts/green_currency_price.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
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

String? _displayDiscountLabel(BuildContext context, String? discount) {
  final value = _validDiscountLabel(discount);
  if (value == null || !context.isArabicLanguage) return value;

  final normalized = value.toLowerCase();
  if (!normalized.contains('discount') && !normalized.contains('off')) {
    return value;
  }

  final percentage = RegExp(r'(\d+(?:[.,]\d+)?\s*%)').firstMatch(value);
  return percentage == null ? 'خصم' : 'خصم ${percentage.group(1)}';
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
  });

  final String image, title, brand, price;
  final String productId;
  final String? productSlug;
  final String? oldPrice, discount;

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

  String get _resolvedProductId => _productId;

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
    if (!selectedStillExists) selectedVariantId = variants.first.id;
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

  void _showAdditionsSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF222326) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.64)
        : Colors.black.withValues(alpha: 0.58);
    final draftSelected = Set<String>.from(selectedAdditionIds);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.56,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
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
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            AppIcons.add,
                            color: AppColors.primary,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr('Additions'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _productAdditions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final addition = _productAdditions[index];
                          final selected = draftSelected.contains(addition.id);
                          return Material(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF3F5FA),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setSheetState(() {
                                  if (selected) {
                                    draftSelected.remove(addition.id);
                                  } else {
                                    draftSelected.add(addition.id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.tr(addition.name),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: textColor,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          if (addition.classification
                                              .trim()
                                              .isNotEmpty)
                                            Text(
                                              context.tr(
                                                addition.classification,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: mutedColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    AppCurrencyText(
                                      text: AppCurrency.format(
                                        _parsePrice(addition.price),
                                      ),
                                      currencyColor: AppColors.primary,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      selected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: selected
                                          ? AppColors.primary
                                          : mutedColor,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    AppActionButton(
                      label: 'OK',
                      onPressed: () {
                        setState(() {
                          selectedAdditionIds
                            ..clear()
                            ..addAll(draftSelected);
                        });
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                      fallbackType: AppImagePlaceholderType.product,
                      fit: BoxFit.contain,
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
    setState(() {
      _selectedAttributeValues[attribute] = option;
      selectedVariantId = _matchingVariantId(_selectedAttributeValues);
    });
  }

  String? _matchingVariantId(Map<String, String> selections) {
    final attributeNames = _variantOptionsByAttribute().keys;
    for (final variant in _variants) {
      final isExactMatch = attributeNames.every(
        (name) => variant.attributeValues[name] == selections[name],
      );
      if (isExactMatch) return variant.id;
    }
    return null;
  }

  String _variantFallbackLabel(ProductVariantData variant, int index) {
    final label = 'Option ${index + 1}';
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
        discount: _displayDiscountLabel(context, _productDiscount),
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
    if (selectedVariantId == null || selectedVariantId.isEmpty) {
      CustomSnackBar.showWarning(
        context: context,
        title: 'This product cannot be added to cart right now.',
      );
      return;
    }
    final selectedPrice = selectedVariant?.price ?? _selectedPrice;
    final variantAttributes =
        selectedVariant?.attributeValues.entries
            .map(
              (entry) =>
                  CartItemAttribute(label: entry.key, value: entry.value),
            )
            .toList(growable: false) ??
        const <CartItemAttribute>[];
    final additionAttributes = _selectedAdditions
        .map(
          (addition) => CartItemAttribute(
            label: context.isArabicLanguage ? 'إضافة' : 'Addition',
            value: addition.name,
          ),
        )
        .toList(growable: false);
    final cartAttributes = [...variantAttributes, ...additionAttributes];

    context.read<CartCubit>().addItem(
      CartItemData(
        id: _resolvedCartItemId,
        productId: _resolvedProductId,
        variantId: selectedVariantId,
        additionIds: selectedAdditionIds.toList(growable: false)..sort(),
        marketId: _marketId,
        marketName: _productBrand,
        image: currentImage,
        brand: _productBrand,
        title: _productTitle,
        price: _parsePrice(selectedPrice) + _selectedAdditionsTotal,
        quantity: quantity,
        attributes: cartAttributes.toList(growable: false),
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
    if (_variants.isEmpty) return const SizedBox.shrink();

    if (_variants.length == 1) {
      final attributes = _variants.single.attributeValues;
      if (attributes.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'المواصفات', isDark: isDark),
          const SizedBox(height: 10),
          for (final entry in attributes.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      );
    }

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
                  isSelected: _selectedAttributeValues[entry.key] == option,
                  onTap: () => _selectVariantOption(entry.key, option),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildAdditionsButton({
    required bool isDark,
    required Color mutedColor,
  }) {
    final selectedAdditions = _selectedAdditions;
    final label = selectedAdditions.isEmpty
        ? context.tr('Choose additions')
        : context.isArabicLanguage
        ? '${selectedAdditions.length} إضافات محددة'
        : '${selectedAdditions.length} additions selected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: isDark ? AppColors.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: _showAdditionsSheet,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.07),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.18 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      AppIcons.add,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(AppIcons.arrow_right_3, size: 18),
                ],
              ),
            ),
          ),
        ),
        if (selectedAdditions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final addition in selectedAdditions)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF1F3F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.tr(addition.name),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

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
                            ? 'هذا المنتج غير متاح في منطقتك حاليًا.'
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
        _parsePrice(selectedPrice) + _selectedAdditionsTotal;
    final hasUnavailableCombination =
        _variants.length > 1 &&
        _hasVariantAttributes() &&
        selectedVariantId == null;
    final isOutOfStock =
        !_isProductAvailable || _variants.isEmpty || hasUnavailableCombination;
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
                    discount: _displayDiscountLabel(context, _productDiscount),
                    price: _formatSinglePrice(selectedPrice),
                    oldPrice: _formatPrice(_productOldPrice),
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
