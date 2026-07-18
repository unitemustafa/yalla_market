part of 'signup_view.dart';

extension _SignupFormFields on _SignupViewState {
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

  Widget _buildTitle(BuildContext context, ThemeData theme, bool isDarkMode) {
    return Text(
      AppTranslations.of(context).createYourAccount,
      style: theme.textTheme.headlineLarge?.copyWith(
        color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
        fontSize: AppFontSizes.pageTitle,
        height: 1.1,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildNameFields(double availableWidth) {
    final shouldStack = availableWidth < 370;

    if (shouldStack) {
      return Column(
        children: [
          CustomTextField(
            controller: _firstNameController,
            labelText: AppStrings.firstName,
            prefixIcon: AppIcons.user,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateRequiredNoWhitespace,
            inputFormatters: [_noWhitespaceInputFormatter],
          ),
          CustomTextField(
            controller: _lastNameController,
            labelText: AppStrings.lastName,
            prefixIcon: AppIcons.user,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateRequiredNoWhitespace,
            inputFormatters: [_noWhitespaceInputFormatter],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: _firstNameController,
            labelText: AppStrings.firstName,
            prefixIcon: AppIcons.user,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateRequiredNoWhitespace,
            inputFormatters: [_noWhitespaceInputFormatter],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: CustomTextField(
            controller: _lastNameController,
            labelText: AppStrings.lastName,
            prefixIcon: AppIcons.user,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateRequiredNoWhitespace,
            inputFormatters: [_noWhitespaceInputFormatter],
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField(bool isDarkMode) {
    final username = _usernameController.text.trim();
    final showAvailabilityState =
        _usernameFocusNode.hasFocus ||
        (username.isNotEmpty && _checker.lastCheckedUsername == username);

    return CustomTextField(
      fieldKey: _usernameFieldKey,
      controller: _usernameController,
      focusNode: _usernameFocusNode,
      labelText: AppStrings.username,
      prefixIcon: AppIcons.user_edit,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validateUsername,
      errorText: _activeUsernameAvailabilityError(),
      inputFormatters: [
        _noWhitespaceInputFormatter,
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
      ],
      suffix: _buildAvailabilityStatusSuffix(
        isDarkMode,
        isChecking: showAvailabilityState && _checker.isCheckingUsername,
        isAvailable: showAvailabilityState
            ? _checker.isUsernameAvailable
            : null,
        showError:
            showAvailabilityState &&
            _usernameController.text.trim().isNotEmpty &&
            _checker.usernameAvailabilityMessage != null &&
            !_checker.hasUsernameCheckError &&
            !_checker.isCheckingUsername,
      ),
    );
  }

  Widget _buildEmailField(bool isDarkMode) {
    final email = _emailController.text.trim().toLowerCase();
    final showAvailabilityState =
        _emailFocusNode.hasFocus ||
        (email.isNotEmpty && _checker.lastCheckedEmail == email);

    return CustomTextField(
      fieldKey: _emailFieldKey,
      controller: _emailController,
      focusNode: _emailFocusNode,
      labelText: AppStrings.email,
      prefixIcon: AppIcons.direct_right,
      keyboardType: TextInputType.emailAddress,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validateEmail,
      errorText: _activeEmailAvailabilityError(),
      inputFormatters: [_noWhitespaceInputFormatter],
      suffix: _buildAvailabilityStatusSuffix(
        isDarkMode,
        isChecking: showAvailabilityState && _checker.isCheckingEmail,
        isAvailable: showAvailabilityState ? _checker.isEmailAvailable : null,
      ),
    );
  }

  Widget? _buildAvailabilityStatusSuffix(
    bool isDarkMode, {
    required bool isChecking,
    required bool? isAvailable,
    bool showError = false,
  }) {
    if (isChecking) {
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

    if (isAvailable == true) {
      return const Icon(
        key: ValueKey('availability_success_icon'),
        AppIcons.tick_circle,
        size: 23,
        color: AppColors.success,
      );
    }

    if (isAvailable == false || showError) {
      return const Icon(
        key: ValueKey('availability_error_icon'),
        AppIcons.danger,
        size: 23,
        color: AppColors.error,
      );
    }

    return null;
  }

  Widget _buildPhoneField(ThemeData theme, bool isDarkMode) {
    final phone = _phoneForLookup();
    final showAvailabilityState =
        _phoneFocusNode.hasFocus ||
        (phone.isNotEmpty && _checker.lastCheckedPhone == phone);
    final fillColor = isDarkMode
        ? const Color(0xFF222326)
        : const Color(0xFFF5F6FA);
    final borderColor = isDarkMode
        ? const Color(0xFF3A3B41)
        : const Color(0xFFE4E7F0);
    final iconColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.64)
        : Colors.black.withValues(alpha: 0.48);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF17181C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        key: _phoneFieldKey,
        controller: _phoneController,
        focusNode: _phoneFocusNode,
        keyboardType: TextInputType.phone,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: _validatePhone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[+0-9]')),
          LengthLimitingTextInputFormatter(13),
        ],
        cursorColor: theme.colorScheme.primary,
        onTapOutside: (_) {},
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontSize: AppFontSizes.bodyLarge,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: AppTranslations.of(context).phoneNumber,
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          labelStyle: TextStyle(
            color: iconColor,
            fontSize: AppFontSizes.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(AppIcons.call, color: iconColor, size: 21),
          hintText: '01xxxxxxxxx',
          hintStyle: TextStyle(
            color: iconColor,
            fontSize: AppFontSizes.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
          suffixIcon: _buildAvailabilityStatusSuffix(
            isDarkMode,
            isChecking: showAvailabilityState && _checker.isCheckingPhone,
            isAvailable: showAvailabilityState
                ? _checker.isPhoneAvailable
                : null,
          ),
          errorText: _activePhoneAvailabilityError(),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
          ),
        ),
      ),
    );
  }
}
