import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../app/routing/app_routes.dart';
import '../../domain/entities/onboarding_model.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_page_item.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isFinishing = false;

  List<OnboardingModel> _pages(AppTranslations strings) {
    return [
      OnboardingModel(
        imagePath: AppAssets.onboardingProducts,
        title: strings.onboardingTitle1,
        description: strings.onboardingDesc1,
      ),
      OnboardingModel(
        imagePath: AppAssets.onboardingFastDelivery,
        title: strings.onboardingTitle3,
        description: strings.onboardingDesc3,
      ),
      OnboardingModel(
        imagePath: AppAssets.onboardingCashOnDelivery,
        title: strings.onboardingTitle2,
        description: strings.onboardingDesc2,
      ),
    ];
  }

  static const _navy = Color(0xFF002D78);
  static const _gold = Color(0xFFFFC233);
  static const _topColors = [_navy, Color(0xFFFBF2E9), Color(0xFFF9EFE7)];
  static const _bottomColors = [
    Color(0xFFF3BC32),
    Color(0xFF064B82),
    Color(0xFF044481),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;

    setState(() {
      _isFinishing = true;
    });

    final saved = await context.read<OnboardingCubit>().markOnboardingSeen();

    if (!mounted) return;

    if (!saved) {
      setState(() {
        _isFinishing = false;
      });
      CustomSnackBar.showError(
        context: context,
        title: 'Could not continue',
        message: 'Please try again.',
      );
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<void> _onNext() async {
    final page = _pageController.hasClients
        ? (_pageController.page ?? _currentIndex.toDouble()).round()
        : _currentIndex;

    if (page >= _pages(AppTranslations.current).length - 1) {
      await _finishOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPrevious() {
    if (_currentIndex == 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppTranslations.of(context);
    final pages = _pages(strings);
    final isLastPage = _currentIndex == pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _currentIndex == 0
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: _currentIndex == 0
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: _navy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _topColors[_currentIndex],
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) => OnboardingPageItem(
                model: pages[index],
                accentColor: _topColors[index],
                bottomColor: _bottomColors[index],
                pageNumber: index + 1,
                totalPages: pages.length,
              ),
            ),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: SafeArea(
                minimum: const EdgeInsets.all(16),
                child: AnimatedOpacity(
                  opacity: isLastPage ? 0 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: IgnorePointer(
                    ignoring: isLastPage,
                    child: TextButton(
                      onPressed: _isFinishing ? null : _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            _topColors[_currentIndex].computeLuminance() > 0.5
                            ? _navy
                            : _gold,
                        backgroundColor: Colors.transparent,
                        minimumSize: const Size(64, 44),
                        textStyle: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      child: Text(strings.skip),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _navy.withValues(alpha: 0),
                      _navy.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              pages.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                width: index == _currentIndex ? 28 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: index == _currentIndex
                                      ? _gold
                                      : Colors.white.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              if (_currentIndex > 0) ...[
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: IconButton(
                                    onPressed: _isFinishing
                                        ? null
                                        : _onPrevious,
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).backButtonTooltip,
                                    style: IconButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: _navy,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: Icon(
                                      context.isArabicLanguage
                                          ? AppIcons.arrow_right_3
                                          : AppIcons.arrow_left_2,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isFinishing ? null : _onNext,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _gold,
                                      foregroundColor: _navy,
                                      disabledBackgroundColor: _gold,
                                      disabledForegroundColor: _navy,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _isFinishing
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _navy,
                                            ),
                                          )
                                        : FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  isLastPage
                                                      ? strings.startShopping
                                                      : strings.continueText,
                                                ),
                                                const SizedBox(width: 10),
                                                Icon(
                                                  context.isArabicLanguage
                                                      ? AppIcons.arrow_left_2
                                                      : AppIcons.arrow_right_3,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
