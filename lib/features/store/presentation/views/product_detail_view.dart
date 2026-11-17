import 'dart:math' as math;

import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:yalla_market/core/presentation/widgets/buttons/app_button_feedback.dart';
import '../../../../core/cache/data_freshness.dart';
import '../../../../core/presentation/widgets/refresh_on_return.dart';
import '../../../../core/utils/coalesced_operation.dart';
import '../../../../core/presentation/actions/copy_content_link.dart';

import '../../../../core/presentation/widgets/states/app_skeleton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/formatters/app_currency.dart';
import '../../../../core/formatters/product_pricing.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/products/cart_counter_icon.dart';
import '../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/texts/app_currency_text.dart';
import '../../../../core/presentation/widgets/texts/green_currency_price.dart';
import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../app/routing/shared_content_links.dart';
import '../../../../core/utils/image_downloader.dart';
import '../../../../features/cart/domain/entities/cart_item.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../cubit/product_discovery_cubit.dart';
import '../../domain/entities/category_data.dart';
import '../../domain/entities/market_shop_data.dart';
import '../../domain/entities/product_data.dart';
import '../../domain/services/market_shop_catalog.dart';
import '../../domain/usecases/get_product_usecase.dart';
import '../../../wishlist/domain/entities/wishlist_item.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';

part 'product_detail_gallery_part.dart';
part 'product_detail_info_part.dart';
part 'product_detail_cart_part.dart';
part 'product_detail_dialogs_part.dart';
part 'product_detail_actions_part.dart';
part 'product_detail_cart_animation_part.dart';

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

class _ProductDetailViewState extends State<ProductDetailView>
    with SingleTickerProviderStateMixin {
  int quantity = 0;
  String? selectedVariantId;
  final Map<String, String> _selectedAttributeValues = <String, String>{};
  final Set<String> selectedAdditionIds = <String>{};
  late String currentImage;
  ProductData? _loadedProduct;
  bool _isLoadingProductDetails = true;
  Failure? _productLoadFailure;
  final _productFreshness = DataFreshness();
  final _detailLoads = CoalescedOperation();
  final _cartTargetKey = GlobalKey();
  final _productImageKey = GlobalKey();
  final _addButtonKey = GlobalKey();
  late final AnimationController _cartAnimation;
  OverlayEntry? _flyingProduct;
  bool _isAddingToCart = false;
  int _cartFeedbackGeneration = 0;

  @override
  void initState() {
    super.initState();
    _cartAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    );
    currentImage = widget.image;
    selectedVariantId = widget.initialVariantId;
    _loadProductDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent != false;
    if (!isCurrent) _cartFeedbackGeneration++;
    if (_cartAnimation.isAnimating &&
        (!isCurrent || MediaQuery.disableAnimationsOf(context))) {
      // The overlay is outside this subtree; notify it after the current build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cancelCartAnimation();
      });
    }
  }

  @override
  void dispose() {
    _removeFlyingProduct();
    _cartAnimation.dispose();
    super.dispose();
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
    return SharedContentLinks.product(
      _resolvedProductId,
      variantId: _selectedVariant?.id,
    );
  }

  String get _productShareText {
    final title = context.tr(_productTitle);
    final brand = context.tr(_productBrand);
    final selection = _selectedVariant?.attributeValues.entries
        .map((entry) => '${context.tr(entry.key)}: ${context.tr(entry.value)}')
        .join('، ');
    final selectionLine = selection == null || selection.isEmpty
        ? ''
        : '$selection\n';
    if (context.isArabicLanguage) {
      return 'شوف $title على يلا ماركت\n'
          'من $brand\n'
          '$selectionLine'
          'السعر: $_selectedDisplayPrice\n'
          '$_productShareLink';
    }
    return 'Check out $title on Yalla Market\n'
        'By $brand\n'
        '$selectionLine'
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

  Future<void> _loadProductDetails({
    bool forceRefresh = false,
    bool silent = false,
  }) => _detailLoads.run(
    () => _fetchProductDetails(forceRefresh: forceRefresh, silent: silent),
  );

  Future<void> _refreshProductIfStale({bool invalidated = false}) async {
    if (invalidated) _productFreshness.invalidate();
    if (!_productFreshness.isStale) return;
    final joinedActiveLoad = _detailLoads.isRunning;
    final revision = _productFreshness.revision;
    await _loadProductDetails(forceRefresh: true, silent: true);
    // An event arriving during another load must not be swallowed by that load.
    if (mounted &&
        invalidated &&
        joinedActiveLoad &&
        _productFreshness.isStale &&
        revision == _productFreshness.revision) {
      await _loadProductDetails(forceRefresh: true, silent: true);
    }
  }

  Future<void> _fetchProductDetails({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
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

    if (!silent) {
      setState(() {
        _isLoadingProductDetails = true;
        _productLoadFailure = null;
      });
    }
    final revision = _productFreshness.revision;
    final result = await sl<GetProductUseCase>()(
      id,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    if (result case ApiSuccess(origin: DataOrigin.network)) {
      _productFreshness.markNetworkSuccess(revision: revision);
    }

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
        if (silent && _loadedProduct != null) return;
        setState(() {
          _isLoadingProductDetails = false;
          _productLoadFailure = failure;
        });
      },
    );
    final servedCache = switch (result) {
      ApiSuccess(origin: DataOrigin.cache) => true,
      _ => false,
    };
    if (!forceRefresh && servedCache) {
      await _fetchProductDetails(forceRefresh: true, silent: true);
    }
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
  Widget build(BuildContext context) => RefreshOnReturn(
    refreshOnMount: false,
    onRefresh: _refreshProductIfStale,
    onInvalidated: () => _refreshProductIfStale(invalidated: true),
    child: _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loadedProduct == null) {
      final failure = _productLoadFailure;
      final isNotFound = failure?.statusCode == 404;
      return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: Center(
          child: _isLoadingProductDetails
              ? const AppProductDetailsSkeleton()
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
                      AppButtonFeedback(
                        builder: (_, pressStates) => ElevatedButton(
                          statesController: pressStates,
                          onPressed: _loadProductDetails,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('إعادة المحاولة'),
                        ),
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
    final isFavorite = context.watch<WishlistCubit>().isFavorite(
      _resolvedProductId,
    );
    final thumbnailImages = _uniqueImageSources(_loadedProduct!.images);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AppContentReveal(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final toolbarHeight = _productToolbarHeight(context);
            return CustomScrollView(
              key: const ValueKey('product_detail_scroll'),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildProductHeader(
                  isDark: isDark,
                  isFavorite: isFavorite,
                  thumbnailImages: thumbnailImages,
                  width: constraints.maxWidth,
                  toolbarHeight: toolbarHeight,
                ),
                SliverToBoxAdapter(
                  child: ConstrainedBox(
                    // Keep enough scroll extent to collapse even a short page.
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        0,
                        constraints.maxHeight -
                            MediaQuery.paddingOf(context).top -
                            toolbarHeight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PriceHeader(
                            discount: _discountBadgeLabel(
                              context,
                              _productDiscount,
                            ),
                            price: _selectedDisplayPrice,
                            oldPrice: _selectedOriginalPrice.isNotEmpty
                                ? _selectedOriginalPrice
                                : _formatPrice(_productOldPrice),
                            isDark: isDark,
                          ),
                          if (_isLoadingProductDetails) ...[
                            const SizedBox(height: 8),
                            const AppLoadingPlaceholder(width: 80),
                          ],
                          if (_variants.isEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'هذا المنتج غير متاح للطلب حاليًا.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatusPill(
                                label: stock,
                                color: stockColor,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 10),
                              _BrandPill(
                                brand: _productBrand,
                                isDark: isDark,
                                marketId: _marketId,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildVariantSelectors(isDark: isDark),
                          if (hasUnavailableCombination) ...[
                            const SizedBox(height: 4),
                            Text(
                              'هذا الاختيار غير متاح حاليًا.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: mutedColor,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _BottomAddToCartBar(
        isDark: isDark,
        quantity: quantity,
        price: selectedUnitPrice,
        isOutOfStock: isOutOfStock,
        isBusy: _isAddingToCart,
        addButtonKey: _addButtonKey,
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
