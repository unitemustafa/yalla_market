import 'package:flutter/material.dart';

import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/presentation/widgets/images/app_image.dart';
import '../../../domain/entities/store_data.dart';

class MarketTypeRail extends StatelessWidget {
  const MarketTypeRail({
    super.key,
    required this.classificationName,
    required this.types,
    required this.selectedId,
    required this.onSelected,
  });

  final String classificationName;
  final List<StoreMarketTypeData> types;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabic = languageCode.toLowerCase().startsWith('ar');
    final visibleTypes = types.take(4).toList(growable: false);
    final hasMore = types.length > visibleTypes.length;
    final effectiveSelectedId = types.any((type) => type.id == selectedId)
        ? selectedId
        : types.firstOrNull?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'كل $classificationName' : 'All $classificationName',
          key: const ValueKey('market_type_heading'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            key: const ValueKey('market_type_rail'),
            scrollDirection: Axis.horizontal,
            itemCount: visibleTypes.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              if (hasMore && index == visibleTypes.length) {
                return _MarketTypeMoreItem(
                  label: isArabic ? 'عرض الكل' : 'View all',
                  onTap: () => _showAllTypes(context, languageCode),
                );
              }
              final type = visibleTypes[index];
              final id = type.id;
              return _MarketTypeItem(
                key: ValueKey('market_type_$id'),
                label: type.localizedName(languageCode),
                image: type.image,
                selected: effectiveSelectedId == id,
                onTap: () => onSelected(id),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAllTypes(BuildContext context, String languageCode) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        final isArabic = languageCode.toLowerCase().startsWith('ar');
        final allItems = types;
        final effectiveSelectedId =
            allItems.any((type) => type.id == selectedId)
            ? selectedId
            : allItems.firstOrNull?.id;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'كل الفئات الثانوية'
                            : 'All secondary categories',
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: MaterialLocalizations.of(
                        sheetContext,
                      ).closeButtonTooltip,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Flexible(
                child: GridView.builder(
                  key: const ValueKey('market_type_all_sheet'),
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 28),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisExtent: 112,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    final type = allItems[index];
                    final id = type.id;
                    return _MarketTypeItem(
                      key: ValueKey('market_type_sheet_$id'),
                      label: type.localizedName(languageCode),
                      image: type.image,
                      selected: effectiveSelectedId == id,
                      onTap: () => Navigator.pop(sheetContext, id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    if (!context.mounted) return;
    onSelected(selected);
  }
}

class _MarketTypeMoreItem extends StatelessWidget {
  const _MarketTypeMoreItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: const ValueKey('market_type_view_all'),
        borderRadius: BorderRadius.circular(42),
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.10),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.30),
                  ),
                ),
                child: Icon(AppIcons.category, color: colors.primary, size: 25),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketTypeItem extends StatelessWidget {
  const _MarketTypeItem({
    super.key,
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(42),
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 64,
                height: 64,
                padding: EdgeInsets.all(selected ? 3 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? colors.primary.withValues(alpha: 0.10)
                      : colors.surfaceContainerHighest,
                  border: Border.all(
                    color: selected
                        ? colors.primary
                        : colors.outlineVariant.withValues(alpha: 0.55),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: ClipOval(
                  child: AppImage(
                    source: image,
                    width: 60,
                    height: 60,
                    role: AppImageRole.illustration,
                    fallbackType: AppImagePlaceholderType.category,
                    cacheWidth: 128,
                    cacheHeight: 128,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
