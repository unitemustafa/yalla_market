import 'dart:async';
import 'package:yalla_market/core/constants/app_constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../cubit/auth_state.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/fixed_auth_page_layout.dart';

class ForgetPasswordView extends StatefulWidget {
  const ForgetPasswordView({
    super.key,
    OtpCooldownStore? cooldownStore,
    DateTime Function()? now,
  }) : cooldownStore = cooldownStore ?? OtpCooldownStore.instance,
       now = now ?? DateTime.now;

  final OtpCooldownStore cooldownStore;
  final DateTime Function() now;

  @override
  State<ForgetPasswordView> createState() => _ForgetPasswordViewState();
}

class _ForgetPasswordViewState extends State<ForgetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextInputFormatter _noWhitespaceInputFormatter =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));
  Timer? _emailCheckDebounce;
  Timer? _cooldownTimer;
  String? _lastCheckedEmail;
  String? _cooldownEmail;
  DateTime? _cooldownDeadline;
  bool? _isEmailRegistered;
  bool _isCheckingEmail = false;
  bool _isSubmitting = false;
  bool _hasActiveCooldown = false;
  int _cooldownReadGeneration = 0;
  int _remainingCooldownSeconds = 0;

  bool get _isCoolingDown =>
      _hasActiveCooldown && _remainingCooldownSeconds > 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailController.addListener(_scheduleEmailCheck);
    _restoreCooldownForCurrentEmail();
  }

  @override
  void dispose() {
    _emailCheckDebounce?.cancel();
    _cancelCooldownTimer();
    _emailController.removeListener(_scheduleEmailCheck);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final authCubit = context.read<AuthCubit>();
    final navigator = Navigator.of(context);
    if (!(_formKey.currentState?.validate() ?? false) ||
        !await _ensureEmailRegistered()) {
      return;
    }
    if (!mounted) return;

    final email = _normalizedEmail();
    if (_isCooldownActiveFor(email)) {
      navigator.pushNamed(AppRoutes.resetPassword, arguments: email);
      return;
    }

    setState(() => _isSubmitting = true);
    final sent = await authCubit.requestPasswordReset(email);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!sent) {
      final retryAfter = authCubit.lastOtpRetryAfterSeconds;
      if (retryAfter != null && retryAfter > 0) {
        await _saveAndStartCooldown(email: email, seconds: retryAfter);
        if (!mounted) return;
        CustomSnackBar.showInfo(
          context: context,
          title: 'Code already sent',
          message:
              'You can use the code already sent to your email. You can request another code when the timer ends.',
        );
        return;
      }

      final authState = authCubit.state;
      final failureMessage = authState is AuthFailure
          ? authState.message
          : authCubit.lastPasswordResetError;
      CustomSnackBar.showError(
        context: context,
        title: 'Could not send code',
        message: failureMessage == null
            ? 'Check the email and try again.'
            : context.tr(failureMessage),
      );
      return;
    }

    final resendAfter =
        authCubit.lastOtpResendAfterSeconds ??
        OtpCooldownStore.fallbackDurations.first;
    await _saveAndStartCooldown(email: email, seconds: resendAfter);
    if (!mounted) return;

    navigator.pushNamed(AppRoutes.resetPassword, arguments: email);
  }

  void _scheduleEmailCheck() {
    _emailCheckDebounce?.cancel();
    _restoreCooldownForCurrentEmail();

    final email = _normalizedEmail();
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
    final email = _normalizedEmail();
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
    final email = _normalizedEmail();
    if (Validators.email(email) != null) return false;

    final authCubit = context.read<AuthCubit>();
    setState(() => _isCheckingEmail = true);
    try {
      final isRegistered = await authCubit.isEmailRegistered(email);
      if (!mounted || email != _normalizedEmail()) {
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
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: DecoratedBox(
        decoration: _buildBackgroundDecoration(isDarkMode),
        child: SafeArea(
          child: FixedAuthPageLayout(
            isKeyboardVisible: isKeyboardVisible,
            nonScrollingMinHeight: 440,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthTopBar(showBack: true),
                  const SizedBox(height: 24),
                  _buildHeader(context, theme, isDarkMode),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _emailController,
                    labelText: AppStrings.email,
                    prefixIcon: AppIcons.direct_right,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [_noWhitespaceInputFormatter],
                    errorText: _activeEmailErrorText(),
                    suffix: _buildEmailStatusSuffix(isDarkMode),
                    validator: _validateEmail,
                    compact: true,
                  ),
                  const SizedBox(height: 8),
                  _buildCooldownNotice(theme, isDarkMode),
                  _buildSubmitButton(),
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
          key: const ValueKey('auth_lock_artwork'),
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
            fontSize: AppFontSizes.pageTitle,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.forgetPasswordDesc,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: subtitleColor,
            fontSize: AppFontSizes.bodyLarge,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final email = _normalizedEmail();
    final canSubmit =
        _lastCheckedEmail == email &&
        _isEmailRegistered == true &&
        !_isCheckingEmail;

    return AppActionButton(
      key: const ValueKey('forgot_password_primary_button'),
      label: _isCooldownActiveFor(email) ? 'Enter' : 'Send',
      isLoading: _isSubmitting,
      onPressed: _isSubmitting || !canSubmit ? null : _onSubmit,
    );
  }

  Widget _buildCooldownNotice(ThemeData theme, bool isDarkMode) {
    final email = _normalizedEmail();
    if (!_isCooldownActiveFor(email)) return const SizedBox.shrink();

    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.68)
        : Colors.black.withValues(alpha: 0.58);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        '${context.tr('You can use the code already sent to your email.')}\n'
        '${context.tr('Resend available in')} '
        '${widget.cooldownStore.formatCountdown(_remainingCooldownSeconds)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final validationMessage = Validators.email(value);
    if (validationMessage != null) return validationMessage;

    final email = widget.cooldownStore.normalizeIdentifier(value ?? '');
    if (_lastCheckedEmail == email && _isEmailRegistered == false) {
      return context.tr('This email is not registered.');
    }

    return null;
  }

  String? _activeEmailErrorText() {
    final email = _normalizedEmail();
    if (email.isEmpty || _isCheckingEmail) return null;
    if (_lastCheckedEmail == email && _isEmailRegistered == false) {
      return context.tr('This email is not registered.');
    }
    return null;
  }

  Widget? _buildEmailStatusSuffix(bool isDarkMode) {
    final email = _normalizedEmail();
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

  Future<void> _restoreCooldownForCurrentEmail() async {
    final email = _normalizedEmail();
    final readGeneration = ++_cooldownReadGeneration;
    _cancelCooldownTimer();
    if (Validators.email(email) != null) {
      _setCooldownInactive();
      return;
    }

    final snapshot = await widget.cooldownStore.read(
      purpose: OtpPurpose.passwordReset,
      identifier: email,
    );
    if (!mounted || readGeneration != _cooldownReadGeneration) return;
    if (email != _normalizedEmail()) return;

    if (snapshot == null) {
      _setCooldownInactive();
      return;
    }

    _startCooldownTimer(
      normalizedEmail: email,
      deadline: widget.now().add(Duration(seconds: snapshot.remainingSeconds)),
    );
  }

  Future<void> _saveAndStartCooldown({
    required String email,
    required int seconds,
  }) async {
    final snapshot = await widget.cooldownStore.save(
      purpose: OtpPurpose.passwordReset,
      identifier: email,
      seconds: seconds,
    );
    if (!mounted || email != _normalizedEmail()) return;
    ++_cooldownReadGeneration;
    _startCooldownTimer(
      normalizedEmail: email,
      deadline: widget.now().add(Duration(seconds: snapshot.remainingSeconds)),
    );
  }

  void _startCooldownTimer({
    required String normalizedEmail,
    required DateTime deadline,
  }) {
    _cancelCooldownTimer();

    _syncCooldownState(normalizedEmail: normalizedEmail, deadline: deadline);

    if (!_hasActiveCooldown) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _syncCooldownState(normalizedEmail: normalizedEmail, deadline: deadline);
    });
  }

  void _cancelCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }

  void _setCooldownInactive() {
    if (!mounted) return;
    if (!_hasActiveCooldown &&
        _cooldownEmail == null &&
        _cooldownDeadline == null &&
        _remainingCooldownSeconds == 0) {
      return;
    }

    setState(() {
      _cooldownEmail = null;
      _cooldownDeadline = null;
      _hasActiveCooldown = false;
      _remainingCooldownSeconds = 0;
    });
  }

  void _syncCooldownState({
    required String normalizedEmail,
    required DateTime deadline,
  }) {
    if (!mounted || normalizedEmail != _normalizedEmail()) {
      return;
    }

    final remainingMilliseconds = deadline
        .difference(widget.now())
        .inMilliseconds;
    if (remainingMilliseconds <= 0) {
      _cancelCooldownTimer();

      setState(() {
        _cooldownEmail = null;
        _cooldownDeadline = null;
        _hasActiveCooldown = false;
        _remainingCooldownSeconds = 0;
      });
      unawaited(
        widget.cooldownStore.clear(
          purpose: OtpPurpose.passwordReset,
          identifier: normalizedEmail,
        ),
      );
      return;
    }

    final seconds = (remainingMilliseconds / 1000).ceil();
    if (!_hasActiveCooldown ||
        _cooldownEmail != normalizedEmail ||
        _cooldownDeadline != deadline ||
        seconds != _remainingCooldownSeconds) {
      setState(() {
        _cooldownEmail = normalizedEmail;
        _cooldownDeadline = deadline;
        _hasActiveCooldown = true;
        _remainingCooldownSeconds = seconds;
      });
    }
  }

  bool _isCooldownActiveFor(String email) {
    return _cooldownEmail == email && _isCoolingDown;
  }

  String _normalizedEmail() {
    return widget.cooldownStore.normalizeIdentifier(_emailController.text);
  }
}
