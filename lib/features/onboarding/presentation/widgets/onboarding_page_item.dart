import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../domain/entities/onboarding_model.dart';

class OnboardingPageItem extends StatelessWidget {
  final OnboardingModel model;
  final Color accentColor;
  final Color? bottomColor;
  final bool showBackground;
  final int pageNumber;
  final int totalPages;

  const OnboardingPageItem({
    super.key,
    required this.model,
    required this.accentColor,
    this.bottomColor,
    this.showBackground = true,
    required this.pageNumber,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final image = AppImage(
      source: model.imagePath,
      role: AppImageRole.illustration,
      fit: BoxFit.contain,
      semanticLabel:
          '$pageNumber/$totalPages. ${model.title}. ${model.description}',
      fallback: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '${model.title}\n\n${model.description}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: accentColor.computeLuminance() > 0.5
                  ? const Color(0xFF002D78)
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
    if (!showBackground) return image;

    return DecoratedBox(
      decoration: BoxDecoration(
        // Extend the artwork's colors into space left by other screen ratios.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor, bottomColor ?? accentColor],
          stops: const [0.4, 0.6],
        ),
      ),
      child: image,
    );
  }
}
