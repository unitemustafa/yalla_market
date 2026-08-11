import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../domain/entities/geocoding_place.dart';

class AddressLocationSearchContent extends StatelessWidget {
  const AddressLocationSearchContent({
    super.key,
    required this.isSearching,
    required this.searchFailed,
    required this.results,
    required this.failureMessage,
    required this.retryLabel,
    required this.onRetry,
    required this.onSelected,
  });

  final bool isSearching;
  final bool searchFailed;
  final List<GeocodingPlace> results;
  final String failureMessage;
  final String retryLabel;
  final VoidCallback onRetry;
  final ValueChanged<GeocodingPlace> onSelected;

  @override
  Widget build(BuildContext context) {
    if (isSearching) return const SearchLoadingList();
    if (searchFailed) {
      return Center(
        child: SearchMessage(
          message: failureMessage,
          actionLabel: retryLabel,
          onAction: onRetry,
        ),
      );
    }
    if (results.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: results.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 20, endIndent: 20),
      itemBuilder: (context, index) {
        final place = results[index];
        return SearchResultTile(place: place, onTap: () => onSelected(place));
      },
    );
  }
}

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({super.key, required this.place, required this.onTap});

  final GeocodingPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      place.addressLine1 ?? place.displayAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (place.addressLine2?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.addressLine2!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.north_west_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchLoadingList extends StatelessWidget {
  const SearchLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: 5,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0xFFF0F1F3)),
      itemBuilder: (_, _) => const SizedBox(
        height: 76,
        child: Row(
          children: [
            _SkeletonBlock(width: 42, height: 42, radius: 21),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(width: 190, height: 13, radius: 7),
                  SizedBox(height: 9),
                  _SkeletonBlock(width: 130, height: 11, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SearchMessage extends StatelessWidget {
  const SearchMessage({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        dense: true,
        title: Text(message),
        trailing: TextButton(onPressed: onAction, child: Text(actionLabel)),
      ),
    );
  }
}

class MissingMapConfiguration extends StatelessWidget {
  const MissingMapConfiguration({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.tr(
            'Map configuration is unavailable. Please try again later.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
