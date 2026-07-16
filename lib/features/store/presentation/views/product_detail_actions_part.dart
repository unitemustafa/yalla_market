part of 'product_detail_view.dart';

extension _ProductDetailActions on _ProductDetailViewState {
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
    _updateState(() {
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
        price: ProductPricing.formattedPrice(
          _productPrice,
          discount: _productDiscount,
        ),
        oldPrice:
            ProductPricing.originalPrice(
              _productPrice,
              discount: _productDiscount,
            ).isNotEmpty
            ? ProductPricing.originalPrice(
                _productPrice,
                discount: _productDiscount,
              )
            : _productOldPrice,
        discount: _discountBadgeLabel(context, _productDiscount),
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
        price:
            ProductPricing.firstPrice(
              selectedPrice,
              discount: _productDiscount,
            ) +
            _selectedAdditionsTotal,
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
    _updateState(() => quantity = 0);
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
                  onTap: () => _updateState(
                    () => selectedVariantId = _variants[index].id,
                  ),
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
          _buildFullWidthChoiceOptions(
            options: entry.value,
            selectedOption: _selectedAttributeValues[entry.key],
            onSelected: (option) => _selectVariantOption(entry.key, option),
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

  Widget _buildFullWidthChoiceOptions({
    required List<String> options,
    required String? selectedOption,
    required ValueChanged<String> onSelected,
  }) {
    final rows = <List<String>>[];
    for (var index = 0; index < options.length; index += 3) {
      rows.add(options.sublist(index, (index + 3).clamp(0, options.length)));
    }

    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          Row(
            children: [
              for (var index = 0; index < rows[rowIndex].length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildChoiceOption(
                    label: rows[rowIndex][index],
                    isSelected: selectedOption == rows[rowIndex][index],
                    onTap: () => onSelected(rows[rowIndex][index]),
                  ),
                ),
              ],
            ],
          ),
          if (rowIndex < rows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

extension _ProductDetailChoiceBuilder on _ProductDetailViewState {
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
            mainAxisSize: MainAxisSize.min,
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
