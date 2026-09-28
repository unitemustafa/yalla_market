class AppMedia {
  const AppMedia({
    this.onboardingOne,
    this.onboardingTwo,
    this.onboardingThree,
    this.marketLogin,
  });

  final String? onboardingOne;
  final String? onboardingTwo;
  final String? onboardingThree;
  final String? marketLogin;

  String? onboardingAt(int index) => switch (index) {
    0 => onboardingOne,
    1 => onboardingTwo,
    _ => onboardingThree,
  };
}
