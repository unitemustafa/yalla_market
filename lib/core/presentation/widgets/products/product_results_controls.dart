part of 'product_results_view.dart';

class _ProductSearchField extends StatelessWidget {
  const _ProductSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: context.tr('Filter products...'),
          prefixIcon: const Icon(AppIcons.search_normal),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: context.tr('Clear'),
                ),
          filled: true,
          fillColor: isDark ? AppColors.darkCardColor : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductResultsSummary extends StatelessWidget {
  const _ProductResultsSummary({
    required this.count,
    required this.query,
    required this.page,
    required this.totalPages,
  });

  final int count;
  final String query;
  final int page;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final text = query.isEmpty
        ? context.productCount(count)
        : context.searchResults(count, query);

    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          context.isArabicLanguage
              ? 'صفحة $page من $totalPages'
              : 'Page $page of $totalPages',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: mutedColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final previousIcon = isRtl ? AppIcons.arrow_right_3 : AppIcons.arrow_left_2;
    final nextIcon = isRtl ? AppIcons.arrow_left_2 : AppIcons.arrow_right_3;

    return Row(
      children: [
        Expanded(
          child: AppActionButton(
            label: 'Previous',
            icon: previousIcon,
            onPressed: onPrevious,
            variant: AppActionButtonVariant.outlined,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 58,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            context.tr('${page + 1}/$totalPages'),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppActionButton(
            label: 'Next',
            icon: nextIcon,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}
