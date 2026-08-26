part of 'signup_view.dart';

extension on _SignupViewState {
  void _handleSignupState(BuildContext context, AuthState state) {
    if (state is AuthSignupSucceeded) {
      final email = state.email.trim().isEmpty
          ? _emailController.text.trim()
          : state.email.trim();
      final strings = AppTranslations.of(context);
      // ignore: discarded_futures
      const OtpCooldownStore().save(
        purpose: OtpPurpose.registration,
        identifier: email,
        seconds:
            context.read<AuthCubit>().lastOtpResendAfterSeconds ??
            OtpCooldownStore.fallbackDurations.first,
      );

      CustomSnackBar.showSuccess(
        context: context,
        title: strings.verifyEmailTitle,
        message: strings.verifyEmailDesc,
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.verifyEmail,
        (route) => false,
        arguments: email,
      );
    }

    if (state is AuthVerificationRequired) {
      final retryAfter = state.retryAfterSeconds;
      if (retryAfter != null && retryAfter > 0) {
        unawaited(
          const OtpCooldownStore().save(
            purpose: OtpPurpose.registration,
            identifier: state.email,
            seconds: retryAfter,
          ),
        );
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.verifyEmail,
        (route) => false,
        arguments: state.email,
      );
    }

    if (state is AuthFailure) {
      CustomSnackBar.showError(
        context: context,
        title: _signupErrorTitle(state.message),
        message: context.tr(state.message),
      );
    }
  }
}
