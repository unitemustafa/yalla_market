import 'package:yalla_market/core/constants/app_constants.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/otp/otp_cooldown_store.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../domain/entities/social_auth_result.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/warning_checkbox.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const _facebookAuthEnabled = bool.fromEnvironment(
    'FACEBOOK_AUTH_ENABLED',
  );

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  final TextInputFormatter _noWhitespaceInputFormatter =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authCubit = context.read<AuthCubit>();
    final identifier = _normalizeLoginIdentifier(_emailController.text);

    authCubit.login(
      email: identifier,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
  }

  Future<void> _navigateAfterSignIn(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final locationCubit = context.read<LocationCubit>();
    await locationCubit.activateUser(authState.session.user.id);
    if (!context.mounted) return;
    final selectedCity = await locationCubit.loadSelectedCity();
    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      selectedCity == null ? AppRoutes.selectCity : AppRoutes.navigationMenu,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final logoAsset = AppAssets.themedLogo(isDarkMode: isDarkMode);
    final strings = AppTranslations.of(context);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          CustomSnackBar.showSuccess(
            context: context,
            title: strings.signInSuccessTitle,
            message: strings.signInSuccessMessage,
          );
          unawaited(_navigateAfterSignIn(context));
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

        if (state is AuthSignupSucceeded) {
          final cubit = context.read<AuthCubit>();
          final resendAfter = cubit.lastOtpResendAfterSeconds;
          if (resendAfter != null && resendAfter > 0) {
            unawaited(
              const OtpCooldownStore().save(
                purpose: OtpPurpose.registration,
                identifier: state.email,
                seconds: resendAfter,
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

        if (state is AuthSocialProfileRequired) {
          unawaited(_showSocialProfileCompletion(state.result));
        }

        if (state is AuthSocialLinkRequired) {
          unawaited(_showSocialLinkDialog(state.result));
        }

        if (state is AuthFailure) {
          CustomSnackBar.showError(
            context: context,
            title: _signInErrorTitle(state.message, strings),
            message: context.tr(state.message),
          );
        }

        if (state is AuthLoginAccountDisabled) {
          CustomSnackBar.showError(
            context: context,
            title: 'Account disabled',
            message:
                'Your account is disabled. Contact technical support or create a new account.',
          );
        }
      },
      builder: (context, authState) {
        final isLoading = authState is AuthLoading;
        final surfaceColor = isDarkMode
            ? const Color(0xFF1A1B20)
            : Colors.white;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDarkMode
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDarkMode
                ? Brightness.dark
                : Brightness.light,
            systemNavigationBarColor: surfaceColor,
            systemNavigationBarIconBrightness: isDarkMode
                ? Brightness.light
                : Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: surfaceColor,
            body: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth >= 500
                      ? 32.0
                      : 20.0;
                  const bannerHeight = 240.0;
                  const overlap = 22.0;
                  final sheetMinHeight =
                      (constraints.maxHeight - (bannerHeight - overlap)).clamp(
                        300.0,
                        double.infinity,
                      );

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.manual,
                        child: Column(
                          children: [
                            // 1. Top Banner area with 3D illustration
                            SizedBox(
                              height: bannerHeight,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.asset(
                                      AppAssets.authMarketHeader,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      cacheHeight: 480,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(
                                              alpha: isDarkMode ? 0.35 : 0.05,
                                            ),
                                            Colors.transparent,
                                            Colors.black.withValues(
                                              alpha: isDarkMode ? 0.40 : 0.08,
                                            ),
                                          ],
                                          stops: const [0.0, 0.45, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. Curved bottom sheet with centered floating logo on the curve
                            Transform.translate(
                              offset: const Offset(0, -overlap),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.topCenter,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    constraints: BoxConstraints(
                                      minHeight: sheetMinHeight,
                                    ),
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(26),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDarkMode ? 0.35 : 0.07,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, -4),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      horizontalPadding,
                                      48,
                                      horizontalPadding,
                                      24,
                                    ),
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 430,
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                strings.welcomeBack,
                                                textAlign: TextAlign.start,
                                                style: theme
                                                    .textTheme
                                                    .headlineLarge
                                                    ?.copyWith(
                                                      fontSize: 22,
                                                      height: 1.15,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : AppColors
                                                                .lightTextPrimary,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                strings.loginSubtitle,
                                                textAlign: TextAlign.start,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontSize: 13.5,
                                                      color: isDarkMode
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                )
                                                          : Colors.black
                                                                .withValues(
                                                                  alpha: 0.55,
                                                                ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              const SizedBox(height: 22),
                                              CustomTextField(
                                                controller: _emailController,
                                                labelText:
                                                    'Mobile / Email / Username',
                                                prefixIcon:
                                                    AppIcons.direct_right,
                                                keyboardType:
                                                    TextInputType.text,
                                                validator:
                                                    Validators.loginIdentifier,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                inputFormatters: [
                                                  _noWhitespaceInputFormatter,
                                                ],
                                              ),
                                              CustomTextField(
                                                controller: _passwordController,
                                                labelText: strings.password,
                                                prefixIcon:
                                                    AppIcons.password_check,
                                                obscureText: _obscurePassword,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                suffixIcon: _obscurePassword
                                                    ? AppIcons.eye_slash
                                                    : AppIcons.eye,
                                                onSuffixIconPressed: () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                                inputFormatters: [
                                                  _noWhitespaceInputFormatter,
                                                ],
                                                validator:
                                                    Validators.passwordRequired,
                                              ),
                                              _buildRememberAndForgotRow(
                                                theme,
                                                isDarkMode,
                                                strings,
                                              ),
                                              const SizedBox(height: 22),
                                              _buildActionButtons(
                                                context,
                                                strings,
                                                isLoading: isLoading,
                                                isDarkMode: isDarkMode,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Centered floating logo badge positioned on the curve
                                  Positioned(
                                    top: -37,
                                    child: Container(
                                      width: 74,
                                      height: 74,
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? const Color(0xFF013C7E)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: surfaceColor,
                                          width: 3.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF013C7E,
                                            ).withValues(alpha: 0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: AppImage(
                                          source: logoAsset,
                                          role: AppImageRole.logo,
                                          cacheWidth: 160,
                                          cacheHeight: 160,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRememberAndForgotRow(
    ThemeData theme,
    bool isDarkMode,
    AppTranslations strings,
  ) {
    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.88)
        : Colors.black.withValues(alpha: 0.78);

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _rememberMe = !_rememberMe;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: WarningCheckbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    strings.rememberMe,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSizes.body,
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.forgetPassword);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            strings.forgetPasswordLink,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: AppFontSizes.body,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppTranslations strings, {
    required bool isLoading,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AppActionButton(
          label: strings.signIn,
          isLoading: isLoading,
          onPressed: isLoading ? null : _onSignIn,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Divider(color: theme.dividerColor.withValues(alpha: 0.6)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                strings.orContinueWith,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: theme.dividerColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _socialPillButton(
                context,
                provider: SocialAuthProvider.google,
                icon: Image.asset(AppAssets.googleLogo, width: 20, height: 20),
                label: 'Google',
                isLoading: isLoading,
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _socialPillButton(
                context,
                provider: SocialAuthProvider.apple,
                icon: FaIcon(
                  FontAwesomeIcons.apple,
                  size: 20,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                label: 'Apple',
                isLoading: isLoading,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
        if (_facebookAuthEnabled) ...[
          const SizedBox(height: 12),
          _socialPillButton(
            context,
            provider: SocialAuthProvider.facebook,
            icon: const FaIcon(
              FontAwesomeIcons.facebookF,
              size: 18,
              color: Color(0xFF1877F2),
            ),
            label: 'Facebook',
            isLoading: isLoading,
            isDarkMode: isDarkMode,
          ),
        ],
        const SizedBox(height: 24),
        _buildSignUpPrompt(theme, isDarkMode, strings),
      ],
    );
  }

  Widget _socialPillButton(
    BuildContext context, {
    required SocialAuthProvider provider,
    required Widget icon,
    required String label,
    required bool isLoading,
    required bool isDarkMode,
  }) {
    final bgColor = isDarkMode
        ? const Color(0xFF23242A)
        : const Color(0xFFF3F4F6);
    final borderColor = isDarkMode
        ? const Color(0xFF383A42)
        : const Color(0xFFE5E7EB);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: isLoading
            ? null
            : () => context.read<AuthCubit>().socialSignIn(
                provider: provider,
                rememberMe: _rememberMe,
              ),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                context.tr(label),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt(
    ThemeData theme,
    bool isDarkMode,
    AppTranslations strings,
  ) {
    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.6);
    final linkColor = theme.colorScheme.primary;

    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.signup);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text.rich(
            TextSpan(
              text: '${strings.dontHaveAccount} ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppFontSizes.body,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: strings.signUpAction,
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: linkColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _showSocialProfileCompletion(SocialAuthResult result) async {
    if (!mounted) return;
    final formKey = GlobalKey<FormState>();
    final firstName = TextEditingController(text: result.firstName);
    final lastName = TextEditingController(text: result.lastName);
    final username = TextEditingController();
    final phone = TextEditingController();
    final city = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('Complete your account')),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(result.email, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: firstName,
                    decoration: InputDecoration(
                      labelText: context.tr('First name'),
                    ),
                    validator: Validators.required,
                  ),
                  TextFormField(
                    controller: lastName,
                    decoration: InputDecoration(
                      labelText: context.tr('Last name'),
                    ),
                  ),
                  TextFormField(
                    controller: username,
                    decoration: InputDecoration(
                      labelText: context.tr('Username'),
                    ),
                    validator: (value) {
                      final requiredMessage = Validators.required(value);
                      if (requiredMessage != null) return requiredMessage;
                      return RegExp(
                            r'^[A-Za-z][A-Za-z0-9._]{2,29}$',
                          ).hasMatch(value!.trim())
                          ? null
                          : context.tr('Enter a valid username');
                    },
                  ),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.tr('Phone number'),
                    ),
                    validator: Validators.egyptianMobile,
                  ),
                  TextFormField(
                    controller: city,
                    decoration: InputDecoration(
                      labelText: context.tr('City (optional)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(dialogContext, true);
              },
              child: Text(context.tr('Continue')),
            ),
          ],
        ),
      );
      if (submitted != true || !mounted) return;
      await context.read<AuthCubit>().completeSocialSignup(
        firstName: firstName.text,
        lastName: lastName.text,
        username: username.text,
        phone: Validators.normalizeEgyptianMobileNumber(phone.text),
        city: city.text,
        rememberMe: _rememberMe,
      );
    } finally {
      firstName.dispose();
      lastName.dispose();
      username.dispose();
      phone.dispose();
      city.dispose();
    }
  }

  Future<void> _showSocialLinkDialog(SocialAuthResult result) async {
    if (!mounted) return;
    final password = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('Link existing account')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(
                  'Enter your current password once to link this sign-in method.',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(labelText: context.tr('Password')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('Cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, password.text.isNotEmpty),
              child: Text(context.tr('Link account')),
            ),
          ],
        ),
      );
      if (submitted != true || !mounted) return;
      await context.read<AuthCubit>().linkSocialAccount(
        password: password.text,
        rememberMe: _rememberMe,
      );
    } finally {
      password.dispose();
    }
  }

  String _signInErrorTitle(String? message, AppTranslations strings) {
    final normalizedMessage = message?.toLowerCase() ?? '';

    if (normalizedMessage.contains('does not exist') ||
        normalizedMessage.contains('create an account')) {
      return strings.signInCreateAccountTitle;
    }

    if (normalizedMessage.contains('invalid email or password')) {
      return strings.signInCredentialsTitle;
    }

    if (normalizedMessage.contains('internet') ||
        normalizedMessage.contains('connection') ||
        normalizedMessage.contains('timed out')) {
      return strings.signInConnectionTitle;
    }

    return strings.signInFailureTitle;
  }

  String _normalizeLoginIdentifier(String value) {
    final trimmed = value.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return trimmed;

    if (digits.startsWith('0')) return '+20${digits.substring(1)}';
    if (digits.startsWith('20')) return '+$digits';
    if (digits.length == 10 && digits.startsWith('1')) return '+20$digits';
    return trimmed;
  }
}
