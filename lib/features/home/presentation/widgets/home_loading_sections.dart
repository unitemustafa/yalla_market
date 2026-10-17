import 'package:flutter/material.dart';

import '../../../../core/constants/app_media_specs.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/presentation/widgets/brands/category_tile.dart';
import '../../../../core/presentation/widgets/states/app_skeleton.dart';

class HomePromoSkeleton extends StatelessWidget {
  const HomePromoSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const AppSkeleton(
    child: AspectRatio(
      aspectRatio: AppMediaSpecs.offerBannerAspectRatio,
      child: SkeletonBox(height: 150),
    ),
  );
}

class HomeCatalogSkeleton extends StatelessWidget {
  const HomeCatalogSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AppSkeleton(child: SkeletonBox(height: 20, width: 150, radius: 6)),
      const SizedBox(height: 12),
      AppSkeleton(
        child: Row(
          children: [
            Expanded(
              child: SkeletonBox(
                height: CategoryTile.heightFor(context),
                radius: AppCategoryLayout.cornerRadius,
              ),
            ),
            const SizedBox(width: AppCategoryLayout.spacing),
            Expanded(
              child: SkeletonBox(
                height: CategoryTile.heightFor(context),
                radius: AppCategoryLayout.cornerRadius,
              ),
            ),
            const SizedBox(width: AppCategoryLayout.spacing),
            Expanded(
              child: SkeletonBox(
                height: CategoryTile.heightFor(context),
                radius: AppCategoryLayout.cornerRadius,
              ),
            ),
            const SizedBox(width: AppCategoryLayout.spacing),
            Expanded(
              child: SkeletonBox(
                height: CategoryTile.heightFor(context),
                radius: AppCategoryLayout.cornerRadius,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const AppSkeleton(child: SkeletonBox(height: 20, width: 150, radius: 6)),
      const SizedBox(height: 14),
      const AppProductSkeletonRail(),
    ],
  );
}
