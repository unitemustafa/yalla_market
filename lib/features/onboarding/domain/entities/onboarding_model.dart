class OnboardingModel {
  const OnboardingModel({
    required this.imagePath,
    this.fallbackImagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String? fallbackImagePath;
  final String title;
  final String description;
}
