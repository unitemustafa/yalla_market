import 'package:flutter/material.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../location/data/datasources/device_location_data_source.dart';
import 'address_entry.dart';

class AddNewAddressView extends StatefulWidget {
  const AddNewAddressView({
    super.key,
    this.address,
    required this.locationDataSource,
  });

  final AddressEntry? address;
  final DeviceLocationDataSource locationDataSource;

  @override
  State<AddNewAddressView> createState() => _AddNewAddressViewState();
}

class _AddNewAddressViewState extends State<AddNewAddressView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  bool _isSaving = false;
  late bool _usesCustomDistrict;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;

    _nameController = TextEditingController(text: address?.name ?? '');
    _phoneController = TextEditingController(text: address?.phoneNumber ?? '');
    _streetController = TextEditingController(text: address?.street ?? '');
    _districtController = TextEditingController(text: address?.district ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _countryController = TextEditingController(text: address?.country ?? '');
    _usesCustomDistrict =
        _districtController.text.trim().isNotEmpty &&
        !_knownDistricts.contains(_districtController.text.trim());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSaving) return;

    setState(() => _isSaving = true);

    final existingAddress = widget.address;
    DeviceCoordinates coordinates;
    try {
      if (existingAddress?.latitude != null &&
          existingAddress?.longitude != null) {
        coordinates = DeviceCoordinates(
          existingAddress!.latitude!,
          existingAddress.longitude!,
        );
      } else {
        coordinates = await widget.locationDataSource
            .resolveCurrentCoordinates();
      }
    } on LocationSelectionException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      CustomSnackBar.showError(
        context: context,
        title: 'Location required',
        message: error.message,
      );
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      CustomSnackBar.showError(
        context: context,
        title: 'Location required',
        message:
            'Turn on GPS and allow location access before saving the address.',
      );
      return;
    }

    if (!mounted) return;
    final address = AddressEntry(
      id: existingAddress?.id ?? '',
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      district: _districtController.text.trim(),
      postalCode: existingAddress?.postalCode ?? '',
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      country: _countryController.text.trim(),
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      isDefault: existingAddress?.isDefault ?? false,
    );

    Navigator.pop(context, address);
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('This field is required');
    }
    return null;
  }

  String? _validatePhone(String? value) {
    return Validators.egyptianMobile(value);
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 760
                ? 640.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        PageTopBar(
                          title: _isEditing ? 'Edit Address' : 'Add Address',
                          subtitle: _isEditing
                              ? 'Update this delivery location'
                              : 'Save a delivery location',
                        ),
                        const SizedBox(height: 18),
                        _AddressHero(isDark: isDark, isEditing: _isEditing),
                        const SizedBox(height: 18),
                        _AddressFormCard(
                          isDark: isDark,
                          children: [
                            _AddressTextField(
                              controller: _nameController,
                              icon: AppIcons.user,
                              label: 'Name',
                              validator: _requiredField,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddressTextField(
                              controller: _phoneController,
                              icon: AppIcons.mobile,
                              label: 'Phone Number',
                              keyboardType: TextInputType.phone,
                              validator: _validatePhone,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddressTextField(
                              controller: _streetController,
                              icon: AppIcons.building_31,
                              label: 'Street',
                              validator: _requiredField,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddressDistrictField(
                              controller: _districtController,
                              usesCustomDistrict: _usesCustomDistrict,
                              onCustomModeChanged: (value) {
                                setState(() => _usesCustomDistrict = value);
                              },
                              validator: _requiredField,
                            ),
                            _ResponsiveFieldPair(
                              first: _AddressTextField(
                                controller: _cityController,
                                icon: AppIcons.building,
                                label: 'City',
                                validator: _requiredField,
                                textInputAction: TextInputAction.next,
                              ),
                              second: _AddressTextField(
                                controller: _stateController,
                                icon: AppIcons.activity,
                                label: 'State',
                                validator: _requiredField,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            _AddressTextField(
                              controller: _countryController,
                              icon: AppIcons.global,
                              label: 'Country',
                              validator: _requiredField,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _saveAddress(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AppActionButton(
                          label: _isEditing ? 'Save Changes' : 'Save',
                          icon: AppIcons.tick_circle,
                          isLoading: _isSaving,
                          onPressed: _isSaving ? null : _saveAddress,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

const _knownDistricts = [
  'Nasr City',
  'Heliopolis',
  'New Cairo',
  'Maadi',
  'Zamalek',
  'Shubra',
  'Mokattam',
  'Downtown Cairo',
  'Helwan',
  '15 May',
  'Naama Bay',
  'Nabq',
  'Hadaba',
];

class _AddressHero extends StatelessWidget {
  const _AddressHero({required this.isDark, required this.isEditing});

  final bool isDark;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25273A) : const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEditing ? AppIcons.edit : AppIcons.location_add,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    isEditing
                        ? 'Keep delivery details fresh'
                        : 'Add a new stop',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(
                    'Complete address details help checkout and delivery move faster.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.35,
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

class _AddressDistrictField extends StatelessWidget {
  const _AddressDistrictField({
    required this.controller,
    required this.usesCustomDistrict,
    required this.onCustomModeChanged,
    required this.validator,
  });

  final TextEditingController controller;
  final bool usesCustomDistrict;
  final ValueChanged<bool> onCustomModeChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    if (usesCustomDistrict) {
      return _AddressTextField(
        controller: controller,
        icon: AppIcons.location,
        label: 'Region',
        validator: validator,
        textInputAction: TextInputAction.next,
        suffixIcon: IconButton(
          onPressed: () => _showDistrictPicker(context),
          icon: const Icon(AppIcons.arrow_down_1),
          tooltip: context.tr('Choose manually'),
        ),
      );
    }

    return _AddressPickerField(
      controller: controller,
      icon: AppIcons.location,
      label: 'Region',
      validator: validator,
      onTap: () => _showDistrictPicker(context),
    );
  }

  Future<void> _showDistrictPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _DistrictPickerSheet(),
    );

    if (selected == null || !context.mounted) return;

    if (selected == _customDistrictToken) {
      controller.clear();
      onCustomModeChanged(true);
      return;
    }

    controller.text = selected;
    onCustomModeChanged(false);
  }
}

const _customDistrictToken = '__custom_district__';

class _DistrictPickerSheet extends StatelessWidget {
  const _DistrictPickerSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Region'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _DistrictTile(
              icon: AppIcons.edit,
              label: 'If your area is not here, add it manually',
              color: AppColors.primary,
              isDark: isDark,
              onTap: () => Navigator.pop(context, _customDistrictToken),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _knownDistricts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final district = _knownDistricts[index];
                  return _DistrictTile(
                    icon: AppIcons.location,
                    label: district,
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () => Navigator.pop(context, district),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistrictTile extends StatelessWidget {
  const _DistrictTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const Icon(AppIcons.arrow_right_3, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressFormCard extends StatelessWidget {
  const _AddressFormCard({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _AddressTextField extends StatelessWidget {
  const _AddressTextField({
    required this.controller,
    required this.icon,
    required this.label,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        labelText: context.tr(label),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7F8FB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

class _AddressPickerField extends StatelessWidget {
  const _AddressPickerField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.onTap,
    this.validator,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: true,
      onTap: onTap,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(AppIcons.arrow_down_1),
        labelText: context.tr(label),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7F8FB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveFieldPair extends StatelessWidget {
  const _ResponsiveFieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackFields = constraints.maxWidth < 520;

        if (stackFields) {
          return Column(children: [first, const SizedBox(height: 14), second]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
