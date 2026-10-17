import '../../../core/domain/media_focal_point.dart';

class AppMedia {
  const AppMedia({
    this.onboardingOne,
    this.onboardingTwo,
    this.onboardingThree,
    this.marketLogin,
    this.marketLoginPoster,
    this.marketLoginFocus = MediaFocalPoint.topCenter,
  });

  final String? onboardingOne;
  final String? onboardingTwo;
  final String? onboardingThree;
  final String? marketLogin;
  final String? marketLoginPoster;
  final MediaFocalPoint marketLoginFocus;
}
