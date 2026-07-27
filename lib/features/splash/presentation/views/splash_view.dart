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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SplashCubit>().determineStartupRoute();
    });
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
    return Container(
      key: const ValueKey('splash_brand_logo'),
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AppImage(
        source: AppAssets.homeBrandLogo,
        fit: BoxFit.contain,
        borderRadius: BorderRadius.circular(16),
        cacheWidth: 192,
        cacheHeight: 192,
      ),
    );
  }
}
