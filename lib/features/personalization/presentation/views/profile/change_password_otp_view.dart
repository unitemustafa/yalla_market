import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/otp/otp_cooldown_store.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../../auth/presentation/widgets/password_strength_meter.dart';
import '../../controllers/user_profile_controller.dart';

class ChangePasswordOtpView extends StatefulWidget {
  const ChangePasswordOtpView({super.key});

  @override
  State<ChangePasswordOtpView> createState() => _ChangePasswordOtpViewState();
}

class _ChangePasswordOtpViewState extends State<ChangePasswordOtpView> {
  static const _cooldownStore = OtpCooldownStore();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  final TextInputFormatter _noWhitespaceInputFormatter =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));

  bool _codeSent = false;
  bool _isSendingCode = false;
  bool _isChangingPassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Timer? _resendTimer;
  int _remainingSeconds = 0;

  String get _email => UserProfileController.instance.email.trim();
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
    _cancelResendTimer(updateState: false);
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSendingCode || _isCoolingDown || _email.isEmpty) return;

    final authCubit = context.read<AuthCubit>();
    setState(() => _isSendingCode = true);
    final sent = await authCubit.requestPasswordReset(_email);
    if (!mounted) return;
    setState(() {
      _isSendingCode = false;
      _codeSent = sent || _codeSent;
    });

    if (!sent) {
      final retryAfter = authCubit.lastOtpRetryAfterSeconds;
      if (retryAfter != null && retryAfter > 0) {
        await _saveAndStartCooldown(retryAfter);
        if (!mounted) return;
      }
      CustomSnackBar.showError(
        context: context,
        title: 'Could not send verification code',
        message: authCubit.lastPasswordResetError ?? 'Please try again.',
      );
      return;
    }

    CustomSnackBar.showSuccess(
      context: context,
      title: 'Verification code sent',
      message: 'Verification code',
    );
    final resendAfter =
        authCubit.lastOtpResendAfterSeconds ??
        OtpCooldownStore.fallbackDurations.first;
    await _saveAndStartCooldown(resendAfter);
  }

  Future<void> _changePassword() async {
    if (!_codeSent ||
        _isChangingPassword ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authCubit = context.read<AuthCubit>();
    setState(() => _isChangingPassword = true);
    final success = await authCubit.resetPassword(
      email: _email,
      code: _codeController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isChangingPassword = false);

    if (!success) {
      CustomSnackBar.showError(
        context: context,
        title: 'Could not change password',
        message: authCubit.lastPasswordResetError ?? 'Please try again.',
      );
      return;
    }

    _cancelResendTimer();
    await _cooldownStore.clear(
      purpose: OtpPurpose.passwordReset,
      identifier: _email,
    );
    if (!mounted) return;
    UserProfileController.instance.reset();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            dialogContext.tr('Password changed'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            dialogContext.tr(
              'Your password was changed successfully. Sign in again to continue.',
            ),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('password_changed_sign_in_button'),
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  dialogContext.tr('Confirm'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return context.tr('Enter the 6-digit verification code.');
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return context.tr('Passwords do not match.');
    }
    return null;
  }

  Future<void> _restoreSavedCooldown() async {
    final snapshot = await _cooldownStore.read(
      purpose: OtpPurpose.passwordReset,
      identifier: _email,
    );
    if (!mounted || snapshot == null) return;
    setState(() {
      _codeSent = true;
      _remainingSeconds = snapshot.remainingSeconds;
    });
    _startResendTimer(snapshot.remainingSeconds);
  }

  Future<void> _saveAndStartCooldown(int seconds) async {
    final snapshot = await _cooldownStore.save(
      purpose: OtpPurpose.passwordReset,
      identifier: _email,
      seconds: seconds,
    );
    if (!mounted) return;
    setState(() => _remainingSeconds = snapshot.remainingSeconds);
    _startResendTimer(snapshot.remainingSeconds);
  }

  void _startResendTimer(int seconds) {
    _cancelResendTimer(updateState: false);
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

  void _cancelResendTimer({bool updateState = true}) {
    _resendTimer?.cancel();
    _resendTimer = null;
    if (updateState && mounted && _remainingSeconds != 0) {
      setState(() => _remainingSeconds = 0);
    } else {
      _remainingSeconds = 0;
    }
  }

  String _sendCodeLabel(BuildContext context) {
    if (_isSendingCode) return 'Sending code...';
    if (_isCoolingDown) {
      return '${context.tr('Resend in')} ${_formatCountdown(_remainingSeconds)}';
    }
    return _codeSent ? 'Resend code' : 'Send code';
  }

  String _formatCountdown(int seconds) {
    return _cooldownStore.formatCountdown(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageTopBar(
                      title: 'Change Password',
                      subtitle: 'Verify your email to set a new password',
                    ),
                    const SizedBox(height: 18),
                    _SecurityCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('E-mail'),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _email,
                            readOnly: true,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(AppIcons.sms),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF7F8FB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AppActionButton(
                            label: _sendCodeLabel(context),
                            icon: AppIcons.sms_tracking,
                            isLoading: _isSendingCode,
                            onPressed: _isSendingCode || _isCoolingDown
                                ? null
                                : _sendCode,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SecurityCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _codeController,
                            labelText: context.tr('Verification code'),
                            prefixIcon: AppIcons.sms,
                            enabled: _codeSent && !_isChangingPassword,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            validator: _validateCode,
                          ),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: context.tr('New Password'),
                            prefixIcon: AppIcons.password_check,
                            enabled: _codeSent && !_isChangingPassword,
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
                          ),
                          PasswordStrengthMeter(
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _confirmPasswordController,
                            labelText: context.tr('Confirm New Password'),
                            prefixIcon: AppIcons.password_check,
                            enabled: _codeSent && !_isChangingPassword,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: _obscureConfirmPassword
                                ? AppIcons.eye_slash
                                : AppIcons.eye,
                            onSuffixIconPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            inputFormatters: [_noWhitespaceInputFormatter],
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: 18),
                          AppActionButton(
                            key: const ValueKey(
                              'change_password_submit_button',
                            ),
                            label: 'Change Password',
                            icon: AppIcons.lock_1,
                            isLoading: _isChangingPassword,
                            onPressed: !_codeSent || _isChangingPassword
                                ? null
                                : _changePassword,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: child,
    );
  }
}
