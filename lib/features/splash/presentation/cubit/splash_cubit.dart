import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/errors/failure.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/otp/pending_verification_store.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';
import '../../../location/domain/entities/city_data.dart';
import '../../../location/domain/usecases/location_usecases.dart';
import '../../../onboarding/domain/usecases/onboarding_usecases.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(
    this._onboardingUseCases,
    this._authUseCases,
    this._locationUseCases, {
    PendingVerificationStore? pendingVerificationStore,
    bool? enableOnboarding,
    Duration startupTimeout = const Duration(seconds: 15),
  }) : _pendingVerificationStore =
           pendingVerificationStore ?? const PendingVerificationStore(),
       _enableOnboarding = enableOnboarding ?? AppEnvironment.enableOnboarding,
       _startupTimeout = startupTimeout,
       super(const SplashLoading());

  final OnboardingUseCases _onboardingUseCases;
  final AuthUseCases _authUseCases;
  final LocationUseCases _locationUseCases;
  final PendingVerificationStore _pendingVerificationStore;
  final bool _enableOnboarding;
  final Duration _startupTimeout;
  Future<SplashNavigateTo>? _pendingRoute;
  bool _isDetermining = false;
  Timer? _deadlineTimer;
  Completer<SplashNavigateTo>? _routeWaiter;

  Future<void> determineStartupRoute() async {
    if (isClosed || _isDetermining || state is SplashNavigateTo) return;
    _isDetermining = true;
    emit(const SplashLoading());
    // A timeout stops waiting; it does not cancel storage or token refresh.
    // Retry the same operation until it settles to avoid overlapping mutations.
    final operation = _pendingRoute ??= _startRouteResolution();
    try {
      final destination = await _waitForRoute(operation);
      _pendingRoute = null;
      if (!isClosed) emit(destination);
    } on _StartupDeadlineExceeded {
      if (!isClosed) {
        emit(
          const SplashFailure(
            NetworkFailure(
              'Starting the app took too long. Please check your connection and try again.',
            ),
          ),
        );
      }
    } on _StartupCancelled {
      // Closing the provider cancels only its deadline, not a native operation.
    } on Failure catch (failure) {
      _pendingRoute = null;
      if (!isClosed) emit(SplashFailure(failure));
    } catch (_) {
      _pendingRoute = null;
      if (!isClosed) {
        emit(
          const SplashFailure(
            UnknownFailure('We could not start the app. Please try again.'),
          ),
        );
      }
    } finally {
      _isDetermining = false;
    }
  }

  Future<SplashNavigateTo> _waitForRoute(Future<SplashNavigateTo> operation) {
    final waiter = Completer<SplashNavigateTo>();
    _routeWaiter = waiter;
    final timer = Timer(_startupTimeout, () {
      if (!waiter.isCompleted) {
        waiter.completeError(const _StartupDeadlineExceeded());
      }
    });
    _deadlineTimer = timer;
    unawaited(
      operation.then<void>(
        (destination) {
          if (!waiter.isCompleted) waiter.complete(destination);
        },
        onError: (Object error, StackTrace stack) {
          if (!waiter.isCompleted) waiter.completeError(error, stack);
        },
      ),
    );
    return waiter.future.whenComplete(() {
      timer.cancel();
      if (identical(_routeWaiter, waiter)) {
        _routeWaiter = null;
        _deadlineTimer = null;
      }
    });
  }

  @override
  Future<void> close() {
    _deadlineTimer?.cancel();
    final waiter = _routeWaiter;
    if (waiter != null && !waiter.isCompleted) {
      waiter.completeError(const _StartupCancelled());
    }
    return super.close();
  }

  Future<SplashNavigateTo> _startRouteResolution() {
    final operation = _resolveStartupRoute();
    unawaited(
      operation.then<void>(
        (_) {},
        onError: (Object error, StackTrace stack) {
          // A completed failure can be retried immediately, including when its
          // original waiter already timed out. Successful late results stay
          // available for an explicit retry, without navigating in the background.
          if (identical(_pendingRoute, operation)) _pendingRoute = null;
        },
      ),
    );
    return operation;
  }

  Future<SplashNavigateTo> _resolveStartupRoute() async {
    if (_enableOnboarding) {
      final onboardingResult = await _onboardingUseCases.hasSeenOnboarding();
      final hasSeenOnboarding = onboardingResult.when(
        success: (seen) => seen,
        failure: (_) => false,
      );

      if (!hasSeenOnboarding) {
        return const SplashNavigateTo(AppRoutes.onboarding);
      }
    }

    AuthSession? session;
    var sessionExpired = false;
    final sessionResult = await _authUseCases.restoreSavedSession();
    session = sessionResult.when(
      success: (s) => s,
      failure: (failure) {
        sessionExpired = _isExpiredSessionFailure(failure);
        return null;
      },
    );

    if (session == null) {
      if (!sessionExpired) {
        final pending = await _pendingVerificationStore.read();
        if (pending != null) {
          return SplashNavigateTo(
            AppRoutes.verifyEmail,
            pendingVerificationEmail: pending.email,
            pendingVerificationExpiresAt: pending.expiresAt,
          );
        }
      }
      return SplashNavigateTo(AppRoutes.login, sessionExpired: sessionExpired);
    }

    final activationResult = await _locationUseCases.activateUser(
      session.user.id,
    );
    activationResult.when(success: (_) {}, failure: (failure) => throw failure);
    CityData? city;
    final cityResult = await _locationUseCases.getSelectedCity();
    city = cityResult.when(success: (c) => c, failure: (_) => null);

    return SplashNavigateTo(
      city == null ? AppRoutes.selectCity : AppRoutes.navigationMenu,
      session: session,
      city: city,
    );
  }

  bool _isExpiredSessionFailure(Failure failure) {
    return failure is UnauthorizedFailure &&
        failure.message.toLowerCase().contains('session expired');
  }
}

final class _StartupDeadlineExceeded implements Exception {
  const _StartupDeadlineExceeded();
}

final class _StartupCancelled implements Exception {
  const _StartupCancelled();
}
