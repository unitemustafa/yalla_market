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
  bool _isChangingPage = false;
  bool _imagesPrecached = false;

  static const _pageTransitionDuration = Duration(milliseconds: 480);

  double get _pagePosition =>
      _pageController.hasClients &&
          _pageController.position.hasContentDimensions
      ? _pageController.page ?? _currentIndex.toDouble()
      : _currentIndex.toDouble();

  bool get _isScrolling =>
      _pageController.hasClients &&
      _pageController.position.isScrollingNotifier.value;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesPrecached) return;
    _imagesPrecached = true;
    for (final page in _pages(AppTranslations.of(context))) {
      precacheImage(
        AssetImage(page.imagePath),
        context,
        // AppImage renders its existing fallback if an asset cannot load.
        onError: (_, _) {},
      );
    }
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
    if (_isFinishing || _isChangingPage || _isScrolling) return;
    final page = _currentIndex;

    if (page >= _pages(AppTranslations.current).length - 1) {
      await _finishOnboarding();
      return;
    }

    await _goToPage(page + 1);
  }

  void _onPrevious() {
    if (_currentIndex == 0 || _isFinishing || _isChangingPage || _isScrolling) {
      return;
    }

    _goToPage(_currentIndex - 1);
  }

  Future<void> _goToPage(int index) async {
    if (!_pageController.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(index);
      return;
    }
    _isChangingPage = true;
    try {
      await _pageController.animateToPage(
        index,
        duration: _pageTransitionDuration,
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _isChangingPage = false;
    }
  }

  Color _backgroundColor(List<Color> colors) {
    final position = _pagePosition.clamp(0.0, colors.length - 1.0);
    return Color.lerp(
      colors[position.floor()],
      colors[position.ceil()],
      position - position.floor(),
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppTranslations.of(context);
    final pages = _pages(strings);
    final isLastPage = _currentIndex == pages.length - 1;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

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
            AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _backgroundColor(_topColors),
                      _backgroundColor(_bottomColors),
                    ],
                    stops: const [0.4, 0.6],
                  ),
                ),
              ),
            ),
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) => AnimatedBuilder(
                animation: _pageController,
                child: RepaintBoundary(
                  child: OnboardingPageItem(
                    model: pages[index],
                    accentColor: _topColors[index],
                    bottomColor: _bottomColors[index],
                    showBackground: false,
                    pageNumber: index + 1,
                    totalPages: pages.length,
                  ),
                ),
                builder: (context, child) {
                  final distance = reduceMotion
                      ? 0.0
                      : (_pagePosition - index).abs().clamp(0.0, 1.0);
                  final progress = Curves.easeInOut.transform(distance);
                  return Opacity(
                    opacity: 1 - progress * 0.35,
                    child: Transform.scale(
                      scale: 1 - progress * 0.035,
                      child: child,
                    ),
                  );
                },
              ),
            ),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: SafeArea(
                minimum: const EdgeInsets.all(16),
                child: AnimatedOpacity(
                  opacity: isLastPage ? 0 : 1,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
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
                          AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(pages.length, (index) {
                                final selected =
                                    1 -
                                    (_pagePosition - index).abs().clamp(
                                      0.0,
                                      1.0,
                                    );
                                return Container(
                                  width: 8 + 20 * selected,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color.lerp(
                                      Colors.white.withValues(alpha: 0.65),
                                      _gold,
                                      selected,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }),
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
