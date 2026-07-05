import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/otp/otp_cooldown_store.dart';
import '../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/custom_text_field.dart';

class ForgetPasswordView extends StatefulWidget {
  const ForgetPasswordView({super.key});

  @override
  State<ForgetPasswordView> createState() => _ForgetPasswordViewState();
}

class _ForgetPasswordViewState extends State<ForgetPasswordView> {
  static const _cooldownStore = OtpCooldownStore();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextInputFormatter _noWhitespaceInputFormatter =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));
  Timer? _emailCheckDebounce;
  String? _lastCheckedEmail;
  bool? _isEmailRegistered;
  bool _isCheckingEmail = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailController.addListener(_scheduleEmailCheck);
  }

  @override
  void dispose() {
    _emailCheckDebounce?.cancel();
    _emailController.removeListener(_scheduleEmailCheck);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final authCubit = context.read<AuthCubit>();
    if ((_formKey.currentState?.validate() ?? false) &&
        await _ensureEmailRegistered()) {
      setState(() => _isSubmitting = true);
      final email = _emailController.text.trim();
      final sent = await authCubit.requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (!sent) {
        CustomSnackBar.showError(
          context: context,
          title: context.isArabicLanguage
              ? 'تعذر إرسال الكود'
              : 'Code was not sent',
          message: context.isArabicLanguage
              ? 'راجع الإيميل وحاول مرة تانية.'
              : 'Check the email and try again.',
        );
        return;
      }

      final resendAfter =
          authCubit.lastOtpResendAfterSeconds ??
          OtpCooldownStore.fallbackDurations.first;
      await _cooldownStore.save(
        purpose: OtpPurpose.passwordReset,
        identifier: email,
        seconds: resendAfter,
      );
      if (!mounted) return;

      Navigator.pushNamed(context, AppRoutes.resetPassword, arguments: email);
    }
  }

  void _scheduleEmailCheck() {
    _emailCheckDebounce?.cancel();

    final email = _emailController.text.trim().toLowerCase();
    final canCheck = Validators.email(email) == null;

    setState(() {
      _lastCheckedEmail = null;
      _isEmailRegistered = null;
      _isCheckingEmail = false;
    });

    if (!canCheck) return;

    _emailCheckDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      // ignore: discarded_futures
      _checkEmailRegistration(showWarningOnError: false);
    });
  }

  Future<bool> _ensureEmailRegistered() async {
    final email = _emailController.text.trim().toLowerCase();
    if (Validators.email(email) != null) {
      _formKey.currentState?.validate();
      return false;
    }

    if (_lastCheckedEmail == email && _isEmailRegistered == true) return true;

    final isRegistered = await _checkEmailRegistration(
      showWarningOnError: true,
    );
    if (!isRegistered) _formKey.currentState?.validate();
    return isRegistered;
  }

  Future<bool> _checkEmailRegistration({
    required bool showWarningOnError,
  }) async {
    final email = _emailController.text.trim().toLowerCase();
    if (Validators.email(email) != null) return false;

    final authCubit = context.read<AuthCubit>();
    setState(() => _isCheckingEmail = true);
    try {
      final isRegistered = await authCubit.isEmailRegistered(email);
      if (!mounted || email != _emailController.text.trim().toLowerCase()) {
        return false;
      }

      setState(() {
        _lastCheckedEmail = email;
        _isEmailRegistered = isRegistered;
        _isCheckingEmail = false;
      });
      return isRegistered;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _lastCheckedEmail = null;
        _isEmailRegistered = null;
        _isCheckingEmail = false;
      });

      if (showWarningOnError) {
        CustomSnackBar.showError(
          context: context,
          title: context.tr('Email check failed'),
          message: context.tr('Could not check email right now.'),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: _buildBackgroundDecoration(isDarkMode),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = (constraints.maxHeight - 20).clamp(
                0.0,
                double.infinity,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AuthTopBar(showClose: true),
                            const SizedBox(height: 34),
                            _buildHeader(context, theme, isDarkMode),
                            const SizedBox(height: 30),
                            CustomTextField(
                              controller: _emailController,
                              labelText: AppStrings.email,
                              prefixIcon: AppIcons.direct_right,
                              keyboardType: TextInputType.emailAddress,
                              inputFormatters: [_noWhitespaceInputFormatter],
                              errorText: _activeEmailErrorText(),
                              suffix: _buildEmailStatusSuffix(isDarkMode),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 14),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(bool isDarkMode) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDarkMode
            ? const [
                Color(0xFF111214),
                AppColors.darkBackground,
                Color(0xFF171717),
              ]
            : const [
                Color(0xFFF3F6FF),
                AppColors.lightBackground,
                Color(0xFFFAFBFF),
              ],
        stops: const [0, 0.45, 1],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDarkMode) {
    final strings = AppTranslations.of(context);
    final titleColor = isDarkMode ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.58)
        : Colors.black.withValues(alpha: 0.56);
    final iconBackground = isDarkMode
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primary.withValues(alpha: 0.10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            AppIcons.lock_1,
            color: theme.colorScheme.primary,
            size: 26,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          strings.forgetPasswordTitle,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: titleColor,
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.forgetPasswordDesc,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: subtitleColor,
            fontSize: 14.5,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit =
        _lastCheckedEmail == _emailController.text.trim().toLowerCase() &&
        _isEmailRegistered == true &&
        !_isCheckingEmail;

    return AppActionButton(
      label: AppStrings.submit,
      isLoading: _isSubmitting,
      onPressed: _isSubmitting || !canSubmit ? null : _onSubmit,
    );
  }

  String? _validateEmail(String? value) {
    final validationMessage = Validators.email(value);
    if (validationMessage != null) return validationMessage;

    final email = value?.trim().toLowerCase() ?? '';
    if (_lastCheckedEmail == email && _isEmailRegistered == false) {
      return context.tr('This email is not registered.');
    }

    return null;
  }

  String? _activeEmailErrorText() {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || _isCheckingEmail) return null;
    if (_lastCheckedEmail == email && _isEmailRegistered == false) {
      return context.tr('This email is not registered.');
    }
    return null;
  }

  Widget? _buildEmailStatusSuffix(bool isDarkMode) {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || Validators.email(email) != null) return null;

    if (_isCheckingEmail) {
      final progressColor = isDarkMode
          ? Colors.white.withValues(alpha: 0.62)
          : Colors.black.withValues(alpha: 0.42);

      return Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      );
    }

    if (_lastCheckedEmail != email || _isEmailRegistered == null) return null;

    return Icon(
      _isEmailRegistered == true ? AppIcons.tick_circle : AppIcons.danger,
      size: 23,
      color: _isEmailRegistered == true ? AppColors.success : AppColors.error,
    );
  }
}
