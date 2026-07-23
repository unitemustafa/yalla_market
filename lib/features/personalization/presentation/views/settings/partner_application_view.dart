import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../domain/entities/partner_application.dart';
import '../../../domain/repositories/partner_application_repository.dart';
import '../../controllers/user_profile_controller.dart';

class PartnerApplicationView extends StatefulWidget {
  const PartnerApplicationView({super.key, this.repository});

  final PartnerApplicationRepository? repository;

  @override
  State<PartnerApplicationView> createState() => _PartnerApplicationViewState();
}

class _PartnerApplicationViewState extends State<PartnerApplicationView> {
  final _formKey = GlobalKey<FormState>();
  late final PartnerApplicationRepository _repository;
  late final TextEditingController _businessNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _landlineController;
  late final TextEditingController _notesController;

  String? _businessType;
  String? _applicantRole;
  int _branchesCount = 1;
  bool? _hasTradeLicense;
  bool _whatsAppOptIn = true;
  bool _isSubmitting = false;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? sl<PartnerApplicationRepository>();
    final profile = UserProfileController.instance;
    _businessNameController = TextEditingController();
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _emailController = TextEditingController(text: profile.email);
    _mobileController = TextEditingController(text: profile.phone);
    _landlineController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _landlineController.dispose();
    _notesController.dispose();
    super.dispose();
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
        child: Form(
          key: _formKey,
          autovalidateMode: _showValidationErrors
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageTopBar(
                  title: 'Register as a partner',
                  subtitle: 'Grow your business with Yalla Market',
                ),
                const SizedBox(height: 18),
                _PartnerIntroCard(isDark: isDark),
                const SizedBox(height: 18),
                _FormCard(
                  isDark: isDark,
                  title: 'Business information',
                  icon: AppIcons.shop,
                  children: [
                    _PartnerTextField(
                      controller: _businessNameController,
                      label: 'Business name',
                      icon: AppIcons.building,
                      enabled: !_isSubmitting,
                      validator: _requiredValidator,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _PartnerDropdown<String>(
                      value: _businessType,
                      label: 'Business type',
                      icon: AppIcons.category,
                      items: const [
                        _DropdownOption(value: 'shop', label: 'Shop'),
                        _DropdownOption(
                          value: 'restaurant',
                          label: 'Restaurant',
                        ),
                        _DropdownOption(
                          value: 'service_provider',
                          label: 'Service provider',
                        ),
                      ],
                      enabled: !_isSubmitting,
                      onChanged: (value) =>
                          setState(() => _businessType = value),
                    ),
                    const SizedBox(height: 12),
                    _PartnerDropdown<int>(
                      value: _branchesCount,
                      label: 'Number of branches',
                      icon: AppIcons.building_31,
                      items: List.generate(
                        5,
                        (index) => _DropdownOption(
                          value: index + 1,
                          label: switch (index + 1) {
                            1 => '1 branch',
                            2 => '2 branches',
                            _ => '${index + 1} branches',
                          },
                        ),
                      ),
                      enabled: !_isSubmitting,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _branchesCount = value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormCard(
                  isDark: isDark,
                  title: 'Contact person',
                  icon: AppIcons.user_tag,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PartnerTextField(
                            controller: _firstNameController,
                            label: 'First name',
                            enabled: !_isSubmitting,
                            validator: _requiredValidator,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PartnerTextField(
                            controller: _lastNameController,
                            label: 'Last name',
                            enabled: !_isSubmitting,
                            validator: _requiredValidator,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PartnerDropdown<String>(
                      value: _applicantRole,
                      label: 'Your role in the business',
                      icon: AppIcons.profile_tick,
                      items: const [
                        _DropdownOption(
                          value: 'owner_partner',
                          label: 'Owner / Partner',
                        ),
                        _DropdownOption(
                          value: 'manager_legal_representative',
                          label: 'Manager / Legal representative',
                        ),
                      ],
                      enabled: !_isSubmitting,
                      onChanged: (value) =>
                          setState(() => _applicantRole = value),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.tr('Do you have a trade license?'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _SelectionButton(
                            label: context.tr('Yes'),
                            selected: _hasTradeLicense == true,
                            enabled: !_isSubmitting,
                            onTap: () =>
                                setState(() => _hasTradeLicense = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SelectionButton(
                            label: context.tr('No'),
                            selected: _hasTradeLicense == false,
                            enabled: !_isSubmitting,
                            onTap: () =>
                                setState(() => _hasTradeLicense = false),
                          ),
                        ),
                      ],
                    ),
                    if (_showValidationErrors && _hasTradeLicense == null) ...[
                      const SizedBox(height: 7),
                      Text(
                        context.tr('Please select an option.'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _FormCard(
                  isDark: isDark,
                  title: 'Contact details',
                  icon: AppIcons.call,
                  children: [
                    _PartnerTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      icon: AppIcons.sms,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _PartnerTextField(
                      controller: _mobileController,
                      label: 'Mobile number',
                      icon: AppIcons.mobile,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.phone,
                      validator: _phoneValidator,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _PartnerTextField(
                      controller: _landlineController,
                      label: 'Landline (optional)',
                      icon: AppIcons.call,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _PartnerTextField(
                      controller: _notesController,
                      label: 'Additional notes (optional)',
                      icon: AppIcons.document_text,
                      enabled: !_isSubmitting,
                      minLines: 3,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _whatsAppOptIn,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() => _whatsAppOptIn = value ?? false);
                            },
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.success,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        context.tr(
                          'I would like to receive updates by WhatsApp',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(AppIcons.send_1, size: 19),
                    label: Text(
                      context.tr(
                        _isSubmitting
                            ? 'Submitting application...'
                            : 'Submit application',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.55,
                      ),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('This field is required.');
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    final normalized = value!.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)) {
      return context.tr('Enter a valid email address.');
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 13) {
      return context.tr('Enter a valid mobile number.');
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _showValidationErrors = true);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid ||
        _businessType == null ||
        _applicantRole == null ||
        _hasTradeLicense == null) {
      CustomSnackBar.showWarning(
        context: context,
        title: 'Please complete the required fields.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final result = await _repository.submit(
      PartnerApplicationRequest(
        businessName: _businessNameController.text,
        contactFirstName: _firstNameController.text,
        contactLastName: _lastNameController.text,
        businessType: _businessType!,
        branchesCount: _branchesCount,
        applicantRole: _applicantRole!,
        hasTradeLicense: _hasTradeLicense!,
        email: _emailController.text,
        mobileNumber: _mobileController.text,
        landline: _landlineController.text,
        whatsappOptIn: _whatsAppOptIn,
        notes: _notesController.text,
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (receipt) => _showSuccessDialog(receipt.businessName),
      failure: (failure) {
        CustomSnackBar.showError(
          context: context,
          title: 'Could not submit partner application',
          message: failure.message,
        );
      },
    );
  }

  void _showSuccessDialog(String businessName) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          icon: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.tick_circle,
              color: AppColors.success,
              size: 30,
            ),
          ),
          title: Text(
            context.tr('Application submitted'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '${context.tr('We received the partner application for')} $businessName. ${context.tr('Our team will review it and contact you soon.')}',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: Text(context.tr('Done')),
            ),
          ],
        );
      },
    );
  }
}

class _PartnerIntroCard extends StatelessWidget {
  const _PartnerIntroCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(AppIcons.shop, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Become a Yalla Market partner'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(
                    'Tell us about your business and our team will contact you after reviewing your application.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.children,
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _PartnerTextField extends StatelessWidget {
  const _PartnerTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final IconData? icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      decoration: _fieldDecoration(context, label: label, icon: icon),
    );
  }
}

class _PartnerDropdown<T> extends StatelessWidget {
  const _PartnerDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.enabled,
    required this.onChanged,
  });

  final T? value;
  final String label;
  final IconData icon;
  final List<_DropdownOption<T>> items;
  final bool enabled;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return FormField<T>(
      key: ValueKey<String>('partner-picker-$label-$value'),
      initialValue: value,
      validator: (value) =>
          value == null ? context.tr('This field is required.') : null,
      builder: (field) {
        _DropdownOption<T>? selectedOption;
        for (final item in items) {
          if (item.value == field.value) {
            selectedOption = item;
            break;
          }
        }

        final hasError = field.hasError;
        final activeBorderColor = hasError ? AppColors.error : borderColor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                key: ValueKey<String>('partner-picker-$label'),
                onTap: enabled
                    ? () async {
                        final selectedValue = await _showPartnerOptionsSheet<T>(
                          context: context,
                          title: label,
                          icon: icon,
                          items: items,
                          selectedValue: field.value,
                        );
                        if (selectedValue == null) return;
                        field.didChange(selectedValue);
                        onChanged(selectedValue);
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 68),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.035)
                        : const Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activeBorderColor,
                      width: hasError ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: isDark ? 0.18 : 0.09,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 19),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr(label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              selectedOption == null
                                  ? context.tr('Select an option')
                                  : context.tr(selectedOption.label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: selectedOption == null
                                        ? (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary)
                                        : null,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(
                          AppIcons.arrow_down_1,
                          size: 16,
                          color: selectedOption == null
                              ? (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary)
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: Text(
                  field.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

Future<T?> _showPartnerOptionsSheet<T>({
  required BuildContext context,
  required String title,
  required IconData icon,
  required List<_DropdownOption<T>> items,
  required T? selectedValue,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final sheetColor = isDark ? AppColors.darkCardColor : Colors.white;
      final mutedColor = isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary;

      return LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: constraints.maxHeight * 0.76,
              ),
              child: Container(
                key: ValueKey<String>('partner-options-sheet-$title'),
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.32 : 0.14,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: mutedColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(icon, color: AppColors.primary, size: 21),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sheetContext.tr(title),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sheetContext.tr('Select the suitable option'),
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: mutedColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => Navigator.pop(sheetContext),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: const Icon(Icons.close_rounded, size: 21),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final selected = item.value == selectedValue;
                          return _PartnerOptionTile(
                            label: item.label,
                            selected: selected,
                            onTap: () =>
                                Navigator.pop(sheetContext, item.value),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _DropdownOption<T> {
  const _DropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _PartnerOptionTile extends StatelessWidget {
  const _PartnerOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.09)
          : (isDark
                ? Colors.white.withValues(alpha: 0.025)
                : const Color(0xFFF7F8FB)),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05)),
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : mutedColor.withValues(alpha: 0.45),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr(label),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selected ? AppColors.primary : null,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.10)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? AppColors.primary : Colors.grey,
              ),
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String label,
  IconData? icon,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final borderColor = isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.08);
  return InputDecoration(
    labelText: context.tr(label),
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    filled: true,
    fillColor: isDark
        ? Colors.white.withValues(alpha: 0.035)
        : const Color(0xFFF7F8FB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error, width: 1.4),
    ),
  );
}
