import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
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
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  Timer? _navigationTimer;
  bool _motionPreferenceApplied = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.72, curve: Curves.easeOutBack),
      ),
    );
    _entranceController.forward();
    _navigationTimer = Timer(
      const Duration(milliseconds: 1500),
      () => context.read<SplashCubit>().determineStartupRoute(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionPreferenceApplied) return;
    _motionPreferenceApplied = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entranceController.value = 1;
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) async {
        if (state is! SplashNavigateTo) return;
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
        Navigator.of(context).pushReplacementNamed(state.route);
        if (state.sessionExpired) {
          authCubit.markSessionExpired();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: const _CompactSplashLogo(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSplashLogo extends StatelessWidget {
  const _CompactSplashLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('splash_brand_logo'),
      width: 150,
      height: 116,
      child: ClipRect(
        child: OverflowBox(
          alignment: const Alignment(0, -0.1),
          maxWidth: 270,
          maxHeight: 270,
          child: AppImage(
            source: AppAssets.homeBrandLogo,
            width: 270,
            height: 270,
            fit: BoxFit.contain,
            cacheWidth: 540,
            cacheHeight: 540,
          ),
        ),
      ),
    );
  }
}
