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
import '../cubit/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/policy_link.dart';
import '../widgets/warning_checkbox.dart';
import 'signup_availability_checker.dart';

part 'signup_form_fields.dart';
part 'signup_policy_widgets.dart';
part 'signup_error_messages.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final FocusNode _usernameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _phoneFocusNode;
  bool _obscurePassword = true;
  bool _agreeToPrivacy = true;
  bool _showPrivacyError = false;
  late final SignupAvailabilityChecker _checker;
  final TextInputFormatter _noWhitespaceInputFormatter =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _usernameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _checker = SignupAvailabilityChecker(
      emailController: _emailController,
      phoneController: _phoneController,
      usernameController: _usernameController,
      onStateChanged: _handleAvailabilityStateChanged,
      validateUsernameField: () => _usernameFieldKey.currentState?.validate(),
      validateEmailField: () => _emailFieldKey.currentState?.validate(),
      validatePhoneField: () => _phoneFieldKey.currentState?.validate(),
      phoneForLookup: _phoneForLookup,
      validatePhoneFormat: _validatePhoneFormat,
      validateUsername: _validateUsername,
      canCheckEmail: _canCheckEmailAvailability,
      canCheckPhone: _canCheckPhoneAvailability,
    );
    _usernameController.addListener(_checker.scheduleUsernameCheck);
    _usernameController.addListener(_checker.scheduleEmailCheck);
    _usernameController.addListener(_checker.schedulePhoneCheck);
    _emailController.addListener(_checker.scheduleEmailCheck);
    _emailController.addListener(_checker.schedulePhoneCheck);
    _phoneController.addListener(_checker.schedulePhoneCheck);
    _usernameFocusNode.addListener(_handleFocusedAvailabilityFieldChanged);
    _emailFocusNode.addListener(_handleFocusedAvailabilityFieldChanged);
    _phoneFocusNode.addListener(_handleFocusedAvailabilityFieldChanged);
  }

  @override
  void dispose() {
    _checker.dispose();
    _usernameController.removeListener(_checker.scheduleUsernameCheck);
    _usernameController.removeListener(_checker.scheduleEmailCheck);
    _usernameController.removeListener(_checker.schedulePhoneCheck);
    _emailController.removeListener(_checker.scheduleEmailCheck);
    _emailController.removeListener(_checker.schedulePhoneCheck);
    _phoneController.removeListener(_checker.schedulePhoneCheck);
    _usernameFocusNode.removeListener(_handleFocusedAvailabilityFieldChanged);
    _emailFocusNode.removeListener(_handleFocusedAvailabilityFieldChanged);
    _phoneFocusNode.removeListener(_handleFocusedAvailabilityFieldChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _handleAvailabilityStateChanged() {
    if (!mounted) return;

    setState(() {});
  }

  void _handleFocusedAvailabilityFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onCreateAccount() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final acceptedTerms = _ensurePrivacyAccepted();
    if (!isFormValid || !acceptedTerms) return;

    final emailAvailable = await _checker.ensureEmailAvailable(context);
    if (!mounted) return;

    final phoneAvailable = await _checker.ensurePhoneAvailable(context);
    if (!mounted) return;

    final usernameAvailable = await _checker.ensureUsernameAvailable(context);

    if (!mounted) return;

    if (emailAvailable && phoneAvailable && usernameAvailable) {
      final username = _usernameController.text.trim();
      context.read<AuthCubit>().signup(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: username,
        email: _emailController.text.trim(),
        phone: _phoneForLookup(),
        password: _passwordController.text,
      );
    }
  }

  bool _ensurePrivacyAccepted() {
    if (_agreeToPrivacy) {
      if (_showPrivacyError) {
        setState(() {
          _showPrivacyError = false;
        });
      }
      return true;
    }

    setState(() {
      _showPrivacyError = true;
    });
    CustomSnackBar.showError(
      context: context,
      title: 'Agreement required',
      message:
          'Please agree to the Privacy Policy and Terms of use before creating your account.',
    );
    return false;
  }

  void _togglePrivacyAgreement() {
    _setPrivacyAgreement(!_agreeToPrivacy);
  }

  void _setPrivacyAgreement(bool? value) {
    setState(() {
      final nextValue = value ?? false;
      _agreeToPrivacy = nextValue;
      if (nextValue) _showPrivacyError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    _checker.updateContext(context);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
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

        if (state is AuthFailure) {
          CustomSnackBar.showError(
            context: context,
            title: _signupErrorTitle(state.message),
            message: context.tr(state.message),
          );
        }
      },
      builder: (context, authState) {
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
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AuthTopBar(showBack: true),
                                const SizedBox(height: 30),
                                _buildTitle(context, theme, isDarkMode),
                                const SizedBox(height: 28),
                                _buildNameFields(constraints.maxWidth),
                                _buildUsernameField(isDarkMode),
                                _buildEmailField(isDarkMode),
                                _buildPhoneField(theme, isDarkMode),
                                CustomTextField(
                                  controller: _passwordController,
                                  labelText: AppStrings.password,
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
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: _validatePassword,
                                  inputFormatters: [
                                    _noWhitespaceInputFormatter,
                                  ],
                                ),
                                PasswordStrengthMeter(
                                  controller: _passwordController,
                                ),
                                const SizedBox(height: 2),
                                _buildPrivacyRow(theme, isDarkMode),
                                const SizedBox(height: 30),
                                _buildCreateAccountButton(
                                  isLoading: authState is AuthLoading,
                                ),
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
      },
    );
  }

  String? _validateEmail(String? value) {
    final whitespaceMessage = _validateNoWhitespace(value);
    if (whitespaceMessage != null) return whitespaceMessage;

    final validationMessage = Validators.email(value);
    if (validationMessage != null) return validationMessage;

    final email = value?.trim().toLowerCase() ?? '';
    if (_checker.lastCheckedEmail == email &&
        _checker.isEmailAvailable == false) {
      return context.tr('This email is already registered.');
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return AppTranslations.current.fieldRequired;
    }

    final whitespaceMessage = _validateNoWhitespace(password);
    if (whitespaceMessage != null) return whitespaceMessage;

    return Validators.password(password);
  }

  String? _validatePhone(String? value) {
    final validationMessage = _validatePhoneFormat(value);
    if (validationMessage != null) return validationMessage;

    final phone = _phoneForLookup(value);
    if (_checker.lastCheckedPhone == phone &&
        _checker.isPhoneAvailable == false) {
      return context.tr('This phone number is already registered.');
    }

    return null;
  }

  String? _activeUsernameAvailabilityError() {
    final username = _usernameController.text.trim();
    if (!_usernameFocusNode.hasFocus ||
        username.isEmpty ||
        _checker.isCheckingUsername) {
      return null;
    }

    if (_checker.lastCheckedUsername == username &&
        _checker.isUsernameAvailable == false) {
      return context.tr('This username is already taken');
    }

    if (_checker.hasUsernameCheckError) {
      return context.tr('Could not check this username.');
    }

    return null;
  }

  String? _activeEmailAvailabilityError() {
    final email = _emailController.text.trim().toLowerCase();
    if (!_emailFocusNode.hasFocus ||
        email.isEmpty ||
        _checker.isCheckingEmail) {
      return null;
    }

    if (_checker.lastCheckedEmail == email &&
        _checker.isEmailAvailable == false) {
      return context.tr('This email is already registered.');
    }

    if (_checker.hasEmailCheckError) {
      return context.tr('Could not check this email.');
    }

    return null;
  }

  String? _activePhoneAvailabilityError() {
    final phone = _phoneForLookup();
    if (!_phoneFocusNode.hasFocus ||
        phone.isEmpty ||
        _checker.isCheckingPhone) {
      return null;
    }

    if (_checker.lastCheckedPhone == phone &&
        _checker.isPhoneAvailable == false) {
      return context.tr('This phone number is already registered.');
    }

    if (_checker.hasPhoneCheckError) {
      return context.tr('Could not check this phone number.');
    }

    return null;
  }

  String? _validatePhoneFormat(String? value) {
    final phone = value ?? '';

    if (phone.trim().isEmpty) {
      return AppTranslations.current.fieldRequired;
    }

    final whitespaceMessage = _validateNoWhitespace(phone);
    if (whitespaceMessage != null) return whitespaceMessage;

    if (!Validators.isEgyptianMobileNumber(phone)) {
      return AppTranslations.current.invalidPhone;
    }

    return null;
  }

  String _phoneForLookup([String? value]) {
    return Validators.normalizeEgyptianMobileNumber(
      value ?? _phoneController.text,
    );
  }

  bool _canCheckEmailAvailability() {
    return _validateEmail(_emailController.text) == null;
  }

  bool _canCheckPhoneAvailability() {
    return _validatePhoneFormat(_phoneController.text) == null;
  }

  String? _validateUsername(String? value) {
    final username = value ?? '';

    if (username.trim().isEmpty) return AppTranslations.current.fieldRequired;

    final whitespaceMessage = _validateNoWhitespace(username);
    if (whitespaceMessage != null) return whitespaceMessage;

    if (username.length < 3) {
      return context.tr('Username must be at least 3 characters');
    }

    if (username.length > 30) {
      return context.tr('Username is too long');
    }

    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      return context.tr(
        'Use English letters, numbers, dots, and underscores only',
      );
    }

    if (!RegExp(r'[a-zA-Z]').hasMatch(username)) {
      return context.tr('Username must include a letter');
    }

    if (_checker.lastCheckedUsername == username &&
        _checker.isUsernameAvailable == false) {
      return context.tr('This username is already taken');
    }

    return null;
  }

  String? _validateNoWhitespace(String? value) {
    if (value != null && RegExp(r'\s').hasMatch(value)) {
      return context.tr('Spaces are not allowed in this field');
    }

    return null;
  }

  String? _validateRequiredNoWhitespace(String? value) {
    final requiredMessage = Validators.required(value);
    if (requiredMessage != null) return requiredMessage;

    return _validateNoWhitespace(value);
  }
}
