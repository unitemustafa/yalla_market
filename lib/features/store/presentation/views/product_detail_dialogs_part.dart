part of 'product_detail_view.dart';

extension _ProductDetailDialogs on _ProductDetailViewState {
  void _showProductShareSheet() {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ProductShareSheet(
          image: _productImage,
          title: pageContext.tr(_productTitle),
          brand: pageContext.tr(_productBrand),
          price: _selectedDisplayPrice,
          onCopyLink: () async {
            Navigator.pop(sheetContext);
            await _copyProductLink();
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
            await _shareProduct(origin);
          },
        );
      },
    );
  }

  Future<void> _copyProductLink() async {
    await Clipboard.setData(ClipboardData(text: _productShareLink));
    if (!mounted) return;
    CustomSnackBar.showSuccess(
      context: context,
      title: 'Product link copied',
      message: 'You can share it with anyone.',
    );
  }

  Future<void> _shareProduct(Rect sharePositionOrigin) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _productShareText,
          title: context.tr(_productTitle),
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      CustomSnackBar.showError(
        context: context,
        title: 'Could not share product',
        message: 'Please try again.',
      );
    }
  }

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
                                      currencyColor: AppColors.currency,
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
                        _updateState(() {
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
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(dialogContext);
        final imageLogicalWidth = (MediaQuery.sizeOf(dialogContext).width - 88)
            .clamp(1.0, 720.0);

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
                      cacheWidth: (imageLogicalWidth * devicePixelRatio)
                          .round(),
                      cacheHeight: (300 * devicePixelRatio).round(),
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
}

class _ProductShareSheet extends StatelessWidget {
  const _ProductShareSheet({
    required this.image,
    required this.title,
    required this.brand,
    required this.price,
    required this.onCopyLink,
    required this.onShare,
  });

  final String image;
  final String title;
  final String brand;
  final String price;
  final VoidCallback onCopyLink;
  final void Function(BuildContext context) onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF222326) : Colors.white;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF3F5FA);
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.64)
        : Colors.black.withValues(alpha: 0.58);

    return SafeArea(
      top: false,
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 18),
            Text(
              context.tr('Share product'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('Send this product or copy its link.'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: AppImage(
                        source: image,
                        fallbackType: AppImagePlaceholderType.product,
                        fit: BoxFit.cover,
                        cacheWidth: 128,
                        cacheHeight: 128,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ProductShareAction(
                    icon: AppIcons.send_1,
                    label: context.tr('Share'),
                    color: AppColors.primary,
                    textColor: Colors.white,
                    onTap: onShare,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProductShareAction(
                    icon: AppIcons.copy,
                    label: context.tr('Copy link'),
                    color: cardColor,
                    textColor: textColor,
                    onTap: (_) => onCopyLink(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductShareAction extends StatelessWidget {
  const _ProductShareAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final void Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: textColor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
