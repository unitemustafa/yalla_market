import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import '../cubit/splash_cubit.dart';
import '../cubit/splash_state.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final CurvedAnimation _logoOpacity;
  final _entranceCompleted = Completer<void>();
  bool _entranceStarted = false;
  bool _reduceMotion = false;
  bool _isNavigating = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SplashCubit>().determineStartupRoute();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      // Complete any awaiting ticker before changing its value.
      _entranceController.stop(canceled: false);
      _entranceController.value = _isExiting ? 0 : 1;
    }
    if (!_entranceStarted) {
      _entranceStarted = true;
      unawaited(_prepareEntrance());
    }
  }

  Future<void> _prepareEntrance() async {
    // Begin the visible animation after the bundled logo has been decoded.
    await precacheImage(const AssetImage(AppAssets.splashBrandLogo), context);
    if (!mounted) return;
    try {
      if (!_reduceMotion) {
        await _entranceController.forward().orCancel;
      }
      if (!_entranceCompleted.isCompleted) _entranceCompleted.complete();
    } on TickerCanceled {
      // Leaving the splash also cancels its animation.
    }
  }

  Future<void> _navigate(BuildContext context, SplashNavigateTo state) async {
    if (_isNavigating) return;
    _isNavigating = true;
    final authCubit = context.read<AuthCubit>();
    final locationCubit = context.read<LocationCubit>();
    if (state.session != null) {
      authCubit.hydrate(state.session!);
      await locationCubit.activateUser(state.session!.user.id);
      if (!context.mounted) return;
    }
    if (state.city != null) {
      locationCubit.syncCity(state.city);
    }
    if (state.pendingVerificationEmail case final email?) {
      authCubit.hydratePendingVerification(
        email,
        expiresAt: state.pendingVerificationExpiresAt,
      );
    }

    // Session restoration runs in parallel with the entrance. Fast local
    // results must not replace the screen before the logo is visible.
    await _entranceCompleted.future;
    if (!context.mounted) return;
    try {
      if (!_reduceMotion) {
        _isExiting = true;
        await _entranceController.reverse().orCancel;
      }
    } on TickerCanceled {
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(
      state.route,
      arguments: state.pendingVerificationEmail,
    );
    if (state.sessionExpired) {
      authCubit.markSessionExpired();
    }
  }

  @override
  void dispose() {
    _logoOpacity.dispose();
    _entranceController.dispose();
    if (!_entranceCompleted.isCompleted) _entranceCompleted.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateTo) unawaited(_navigate(context, state));
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.splashBackground,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: AppColors.splashBackground,
          body: FadeTransition(
            opacity: _logoOpacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _SplashBrandLogo(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + 28,
                  child: const _SplashLoadingDots(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashBrandLogo extends StatelessWidget {
  const _SplashBrandLogo();

  // Bounds of the opaque badge within the original transparent canvas.
  // Keep the full image to preserve its glow, but size and center the badge.
  static const _canvasSize = Size(1536, 1024);
  static const _badgeBounds = Rect.fromLTRB(162, 292, 1397, 636);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final badgeWidth = math.min(constraints.maxWidth * 0.70, 420.0);
        final scale = math.min(
          badgeWidth / _badgeBounds.width,
          constraints.maxHeight / _canvasSize.height,
        );
        final offset = _canvasSize.center(Offset.zero) - _badgeBounds.center;
        return Center(
          child: Transform.translate(
            offset: offset * scale,
            child: Image.asset(
              AppAssets.splashBrandLogo,
              key: const ValueKey('splash_brand_logo'),
              width: _canvasSize.width * scale,
              height: _canvasSize.height * scale,
              fit: BoxFit.contain,
              semanticLabel: 'Yalla Market',
              errorBuilder: (_, _, _) => const Text(
                'yalla market',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SplashLoadingDots extends StatefulWidget {
  const _SplashLoadingDots();

  @override
  State<_SplashLoadingDots> createState() => _SplashLoadingDotsState();
}

class _SplashLoadingDotsState extends State<_SplashLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (_controller.value - index / 3 + 1) % 1;
            final opacity = _reduceMotion
                ? 0.65
                : 0.35 + 0.65 * (1 - (phase * 2 - 1).abs());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 5, height: 5),
              ),
            );
          }),
        ),
      ),
    );
  }
}
