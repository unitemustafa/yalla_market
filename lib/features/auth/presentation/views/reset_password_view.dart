import 'dart:async';
import 'package:yalla_market/core/constants/app_constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/otp/otp_cooldown_store.dart';
import '../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/fixed_auth_page_layout.dart';
import '../widgets/password_strength_meter.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  static const _cooldownStore = OtpCooldownStore();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  final TextInputFormatter _noWhitespaceInputFormatter =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));

  Timer? _resendTimer;
  int _remainingSeconds = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _isResending = false;

  bool get _isCoolingDown => _remainingSeconds > 0;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _restoreSavedCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;

    final authCubit = context.read<AuthCubit>();
    setState(() => _isSubmitting = true);
    final success = await authCubit.resetPassword(
      email: widget.email,
      code: _codeController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      final authState = authCubit.state;
      final failureMessage = authState is AuthFailure
          ? authState.message
          : null;
      CustomSnackBar.showError(
        context: context,
        title: _copy(ar: 'تعذر تغيير كلمة السر', en: 'Password was not reset'),
        message: failureMessage == null
            ? _copy(
                ar: 'راجع الكود وكلمة السر وحاول مرة تانية.',
                en: 'Check the code and password, then try again.',
              )
            : context.tr(failureMessage),
      );
      return;
    }

    CustomSnackBar.showSuccess(
      context: context,
      title: _copy(ar: 'تم تغيير كلمة السر', en: 'Password reset'),
      message: _copy(
        ar: 'استخدم كلمة السر الجديدة لتسجيل الدخول.',
        en: 'Use your new password to sign in.',
      ),
    );
    _resendTimer?.cancel();
    await _cooldownStore.clear(
      purpose: OtpPurpose.passwordReset,
      identifier: widget.email,
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _onResend() async {
    if (_isCoolingDown || _isResending) return;

    final authCubit = context.read<AuthCubit>();
    setState(() => _isResending = true);
    final sent = await authCubit.resendPasswordResetCode(widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (!sent) {
      final retryAfter = authCubit.lastOtpRetryAfterSeconds;
      if (retryAfter != null && retryAfter > 0) {
        await _saveAndStartCooldown(retryAfter);
        if (!mounted) return;
      }
      CustomSnackBar.showError(
        context: context,
        title: _copy(ar: 'تعذر إرسال الكود', en: 'Code was not sent'),
        message: _copy(
          ar: 'حاول مرة تانية بعد لحظات.',
          en: 'Please try again in a moment.',
        ),
      );
      return;
    }

    CustomSnackBar.showSuccess(
      context: context,
      title: _copy(ar: 'تم إرسال الكود', en: 'Code sent'),
      message: _copy(
        ar: 'بعتنا كود جديد على الإيميل.',
        en: 'We sent a new code to your email.',
      ),
    );
    final resendAfter =
        authCubit.lastOtpResendAfterSeconds ??
        OtpCooldownStore.fallbackDurations.first;
    await _saveAndStartCooldown(resendAfter);
  }

  Future<void> _restoreSavedCooldown() async {
    final snapshot = await _cooldownStore.read(
      purpose: OtpPurpose.passwordReset,
      identifier: widget.email,
    );
    if (!mounted || snapshot == null) return;
    setState(() => _remainingSeconds = snapshot.remainingSeconds);
    _startCooldown(snapshot.remainingSeconds);
  }

  Future<void> _saveAndStartCooldown(int seconds) async {
    final snapshot = await _cooldownStore.save(
      purpose: OtpPurpose.passwordReset,
      identifier: widget.email,
      seconds: seconds,
    );
    if (!mounted) return;
    setState(() => _remainingSeconds = snapshot.remainingSeconds);
    _startCooldown(snapshot.remainingSeconds);
  }

  void _startCooldown(int seconds) {
    _resendTimer?.cancel();
    _remainingSeconds = seconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return _copy(
        ar: 'اكتب كود مكون من 6 أرقام',
        en: 'Enter the 6-digit code.',
      );
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return _copy(
        ar: 'كلمتا السر غير متطابقتين',
        en: 'Passwords do not match.',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: DecoratedBox(
        decoration: _buildBackgroundDecoration(isDarkMode),
        child: SafeArea(
          child: FixedAuthPageLayout(
            isKeyboardVisible: isKeyboardVisible,
            nonScrollingMinHeight: 650,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthTopBar(showBack: true),
                  const SizedBox(height: 24),
                  _buildHeader(theme, isDarkMode),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _codeController,
                    labelText: _copy(
                      ar: 'كود التأكيد',
                      en: 'Verification code',
                    ),
                    prefixIcon: AppIcons.sms,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: _validateCode,
                    compact: true,
                  ),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: _copy(
                      ar: 'كلمة السر الجديدة',
                      en: 'New password',
                    ),
                    prefixIcon: AppIcons.password_check,
                    obscureText: _obscurePassword,
                    suffixIcon: _obscurePassword
                        ? AppIcons.eye_slash
                        : AppIcons.eye,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    inputFormatters: [_noWhitespaceInputFormatter],
                    validator: Validators.password,
                    compact: true,
                  ),
                  PasswordStrengthMeter(controller: _passwordController),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: _copy(
                      ar: 'تأكيد كلمة السر',
                      en: 'Confirm password',
                    ),
                    prefixIcon: AppIcons.password_check,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: _obscureConfirmPassword
                        ? AppIcons.eye_slash
                        : AppIcons.eye,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    inputFormatters: [_noWhitespaceInputFormatter],
                    validator: _validateConfirmPassword,
                    compact: true,
                  ),
                  const SizedBox(height: 6),
                  AppActionButton(
                    label: _copy(ar: 'تغيير كلمة السر', en: 'Reset password'),
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _onSubmit,
                  ),
                  const SizedBox(height: 4),
                  _buildResendButton(theme, isDarkMode),
                ],
              ),
            ),
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

  Widget _buildHeader(ThemeData theme, bool isDarkMode) {
    final titleColor = isDarkMode ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.58)
        : Colors.black.withValues(alpha: 0.56);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const ValueKey('auth_lock_artwork'),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: isDarkMode ? 0.18 : 0.10,
            ),
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
          _copy(ar: 'غيّر كلمة السر', en: 'Reset password'),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: titleColor,
            fontSize: AppFontSizes.pageTitle,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _copy(
            ar: 'اكتب كود التأكيد وكلمة السر الجديدة للحساب التالي:',
            en: 'Enter the verification code and new password for this account:',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: subtitleColor,
            fontSize: AppFontSizes.bodyLarge,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        _buildEmailBadge(theme, isDarkMode),
      ],
    );
  }

  Widget _buildEmailBadge(ThemeData theme, bool isDarkMode) {
    final backgroundColor = AppColors.primary.withValues(
      alpha: isDarkMode ? 0.16 : 0.09,
    );
    final borderColor = AppColors.primary.withValues(
      alpha: isDarkMode ? 0.30 : 0.20,
    );

    return Container(
      key: const ValueKey('reset_password_email_badge'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Icon(AppIcons.sms, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.email.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: AppFontSizes.bodyLarge,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResendButton(ThemeData theme, bool isDarkMode) {
    final label = _isCoolingDown
        ? _copy(
            ar: 'إعادة الإرسال خلال ${_formatCooldown(_remainingSeconds)}',
            en: 'Resend in ${_formatCooldown(_remainingSeconds)}',
          )
        : _copy(ar: 'ابعت الكود تاني', en: 'Resend code');
    final enabledColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.lightTextPrimary;
    final disabledColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.34)
        : Colors.black.withValues(alpha: 0.34);

    return Center(
      child: TextButton(
        onPressed: _isCoolingDown || _isResending ? null : _onResend,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          disabledForegroundColor: disabledColor,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: _isCoolingDown ? disabledColor : enabledColor,
          ),
        ),
      ),
    );
  }

  String _formatCooldown(int seconds) {
    return _cooldownStore.formatCountdown(seconds);
  }

  String _copy({required String ar, required String en}) {
    return context.isArabicLanguage ? ar : en;
  }
}
