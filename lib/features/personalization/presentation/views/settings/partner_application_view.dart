import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../domain/entities/partner_application.dart';
import '../../../domain/usecases/submit_partner_application_usecase.dart';
import '../../controllers/user_profile_controller.dart';
import '../../cubit/partner_application_cubit.dart';
import '../../cubit/partner_application_state.dart';
import '../../widgets/partner_application_form_widgets.dart';
import '../../widgets/partner_application_picker.dart';

class PartnerApplicationView extends StatefulWidget {
  const PartnerApplicationView({super.key, this.submitApplication});

  final SubmitPartnerApplicationUseCase? submitApplication;

  @override
  State<PartnerApplicationView> createState() => _PartnerApplicationViewState();
}

class _PartnerApplicationViewState extends State<PartnerApplicationView> {
  final _formKey = GlobalKey<FormState>();
  late final PartnerApplicationCubit _cubit;
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
    _cubit = PartnerApplicationCubit(
      widget.submitApplication ?? sl<SubmitPartnerApplicationUseCase>(),
    );
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
    _cubit.close();
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
                PartnerIntroCard(isDark: isDark),
                const SizedBox(height: 18),
                PartnerFormCard(
                  isDark: isDark,
                  title: 'Business information',
                  icon: AppIcons.shop,
                  children: [
                    PartnerTextField(
                      controller: _businessNameController,
                      label: 'Business name',
                      icon: AppIcons.building,
                      enabled: !_isSubmitting,
                      validator: _requiredValidator,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    PartnerDropdown<String>(
                      value: _businessType,
                      label: 'Business type',
                      icon: AppIcons.category,
                      items: const [
                        PartnerDropdownOption(value: 'shop', label: 'Shop'),
                        PartnerDropdownOption(
                          value: 'restaurant',
                          label: 'Restaurant',
                        ),
                        PartnerDropdownOption(
                          value: 'service_provider',
                          label: 'Service provider',
                        ),
                      ],
                      enabled: !_isSubmitting,
                      onChanged: (value) =>
                          setState(() => _businessType = value),
                    ),
                    const SizedBox(height: 12),
                    PartnerDropdown<int>(
                      value: _branchesCount,
                      label: 'Number of branches',
                      icon: AppIcons.building_31,
                      items: List.generate(
                        5,
                        (index) => PartnerDropdownOption(
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
                PartnerFormCard(
                  isDark: isDark,
                  title: 'Contact person',
                  icon: AppIcons.user_tag,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PartnerTextField(
                            controller: _firstNameController,
                            label: 'First name',
                            enabled: !_isSubmitting,
                            validator: _requiredValidator,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PartnerTextField(
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
                    PartnerDropdown<String>(
                      value: _applicantRole,
                      label: 'Your role in the business',
                      icon: AppIcons.profile_tick,
                      items: const [
                        PartnerDropdownOption(
                          value: 'owner_partner',
                          label: 'Owner / Partner',
                        ),
                        PartnerDropdownOption(
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
                          child: PartnerSelectionButton(
                            label: context.tr('Yes'),
                            selected: _hasTradeLicense == true,
                            enabled: !_isSubmitting,
                            onTap: () =>
                                setState(() => _hasTradeLicense = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PartnerSelectionButton(
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
                PartnerFormCard(
                  isDark: isDark,
                  title: 'Contact details',
                  icon: AppIcons.call,
                  children: [
                    PartnerTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      icon: AppIcons.sms,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    PartnerTextField(
                      controller: _mobileController,
                      label: 'Mobile number',
                      icon: AppIcons.mobile,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.phone,
                      validator: _phoneValidator,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    PartnerTextField(
                      controller: _landlineController,
                      label: 'Landline (optional)',
                      icon: AppIcons.call,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    PartnerTextField(
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
    final state = await _cubit.submit(
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

    switch (state) {
      case PartnerApplicationSuccess(:final receipt):
        _showSuccessDialog(receipt.businessName);
      case PartnerApplicationFailure(:final message):
        CustomSnackBar.showError(
          context: context,
          title: 'Could not submit partner application',
          message: message,
        );
      case PartnerApplicationInitial() || PartnerApplicationSubmitting():
        break;
    }
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
