import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_constants.dart';
import '../../../icons/app_icons.dart';
import '../../../localization/app_translations.dart';

class AppSearchActionsBar extends StatelessWidget {
  const AppSearchActionsBar({
    super.key,
    required this.searchField,
    this.actions = const [],
  });

  final Widget searchField;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        Expanded(child: searchField),
        for (final action in actions) ...[const SizedBox(width: 8), action],
      ],
    );
  }
}

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.trailing,
  }) : assert(controller != null || onTap != null);

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late FocusNode _focusNode;
  Animation<double>? _secondaryRouteAnimation;

  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _secondaryRouteAnimation?.removeStatusListener(_handleRouteStatus);
    _secondaryRouteAnimation = ModalRoute.of(context)?.secondaryAnimation;
    _secondaryRouteAnimation?.addStatusListener(_handleRouteStatus);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    _secondaryRouteAnimation?.removeStatusListener(_handleRouteStatus);
    widget.controller?.removeListener(_handleControllerChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _handleRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) _focusNode.unfocus();
  }

  void _clear() {
    widget.controller?.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final content = Container(
      height: 48,
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(AppIcons.search_normal, color: mutedColor, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: widget.controller == null
                ? Text(
                    context.tr(widget.hintText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                      fontSize: AppFontSizes.small,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    onTapOutside: (_) => _focusNode.unfocus(),
                    textInputAction: TextInputAction.search,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppFontSizes.small,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr(widget.hintText),
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            color: mutedColor,
                            fontSize: AppFontSizes.small,
                            fontWeight: FontWeight.w600,
                          ),
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
          ),
          if (widget.controller?.text.isNotEmpty == true) ...[
            const SizedBox(width: 4),
            IconButton(
              key: const ValueKey('app_search_clear_button'),
              onPressed: _clear,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: mutedColor,
              tooltip: context.tr('Clear'),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
            ),
          ] else if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );

    return Material(
      color: isDark ? AppColors.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: widget.onTap == null
          ? content
          : InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: content,
            ),
    );
  }
}

class AppSearchActionButton extends StatelessWidget {
  const AppSearchActionButton({
    super.key,
    required this.child,
    this.onTap,
    this.badgeCount = 0,
    this.badgeKey,
  });

  final Widget child;
  final VoidCallback? onTap;
  final int badgeCount;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalizedBadgeCount = badgeCount < 0 ? 0 : badgeCount;
    final content = SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            alignment: Alignment.center,
            child: child,
          ),
          if (normalizedBadgeCount > 0)
            PositionedDirectional(
              key: badgeKey,
              top: -6,
              end: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardColor : Colors.white,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  normalizedBadgeCount > 99 ? '99+' : '$normalizedBadgeCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: AppFontSizes.caption,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Material(
      color: isDark ? AppColors.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: content,
            ),
    );
  }
}
