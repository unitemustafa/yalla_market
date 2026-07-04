import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../cubit/auth_cubit.dart';

/// Handles availability checking (email, phone, username) extracted from
/// [_SignupViewState] to keep the main state class focused on UI.
///
/// Call [updateContext] on every [build] call to keep the [BuildContext]
/// fresh for async operations triggered from listener callbacks.
class SignupAvailabilityChecker {
  SignupAvailabilityChecker({
    required this.emailController,
    required this.phoneController,
    required this.usernameController,
    required this.onStateChanged,
    required this.validateUsernameField,
    required this.validateEmailField,
    required this.validatePhoneField,
    required this.phoneForLookup,
    required this.validatePhoneFormat,
    required this.validateUsername,
    required this.canCheckEmail,
    required this.canCheckPhone,
  });

  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController usernameController;

  /// Called whenever internal state changes — pass `() => setState(() {})`.
  final VoidCallback onStateChanged;
  final VoidCallback validateUsernameField;
  final VoidCallback validateEmailField;
  final VoidCallback validatePhoneField;

  /// Returns the phone number in lookup format (dial code + digits).
  final String Function() phoneForLookup;

  /// Returns a validation error message or null if valid.
  final String? Function(String?) validatePhoneFormat;

  /// Returns a validation error message or null if valid.
  final String? Function(String?) validateUsername;

  /// Allows email lookup only after previous fields are valid.
  final bool Function() canCheckEmail;

  /// Allows phone lookup only after email has already been verified available.
  final bool Function() canCheckPhone;
  bool _isNotifyingStateChange = false;

  /// Must be updated each build via [updateContext].
  BuildContext? _context;

  /// Call this at the top of the widget's [build] method to keep the context
  /// up-to-date for async operations triggered by text-field listeners.
  void updateContext(BuildContext context) => _context = context;

  // ── State ────────────────────────────────────────────────────────────────

  Timer? _usernameLookupDebounce;
  Timer? _emailLookupDebounce;
  Timer? _phoneLookupDebounce;

  String? usernameAvailabilityMessage;
  String? emailAvailabilityMessage;
  String? phoneAvailabilityMessage;

  String? _lastCheckedUsername;
  String? _lastCheckedEmail;
  String? _lastCheckedPhone;
  String? _lastRequestedUsername;
  String? _lastRequestedEmail;
  String? _lastRequestedPhone;
  int _usernameRequestGeneration = 0;
  int _emailRequestGeneration = 0;
  int _phoneRequestGeneration = 0;

  String? get lastCheckedUsername => _lastCheckedUsername;
  String? get lastCheckedEmail => _lastCheckedEmail;
  String? get lastCheckedPhone => _lastCheckedPhone;
  bool get hasUsernameCheckError =>
      usernameAvailabilityMessage == 'Could not check this username.';
  bool get hasEmailCheckError =>
      emailAvailabilityMessage == 'Could not check this email.';
  bool get hasPhoneCheckError =>
      phoneAvailabilityMessage == 'Could not check this phone number.';

  bool? isUsernameAvailable;
  bool? isEmailAvailable;
  bool? isPhoneAvailable;

  bool isCheckingUsername = false;
  bool isCheckingEmail = false;
  bool isCheckingPhone = false;

  void _notifyStateChanged() {
    if (_isNotifyingStateChange) return;

    _isNotifyingStateChange = true;
    onStateChanged();
    _isNotifyingStateChange = false;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  void dispose() {
    _usernameLookupDebounce?.cancel();
    _emailLookupDebounce?.cancel();
    _phoneLookupDebounce?.cancel();
  }

  // ── Email ────────────────────────────────────────────────────────────────

  void scheduleEmailCheck() {
    _emailLookupDebounce?.cancel();

    final email = emailController.text.trim().toLowerCase();
    final validationMessage = Validators.email(email);

    if (email == _lastRequestedEmail && !isCheckingEmail) return;

    _lastCheckedEmail = null;
    _lastRequestedEmail = null;
    _emailRequestGeneration++;
    isEmailAvailable = null;
    isCheckingEmail = false;
    emailAvailabilityMessage = null;
    _notifyStateChanged();

    if (email.isEmpty || validationMessage != null || !canCheckEmail()) return;

    _lastRequestedEmail = email;
    final generation = _emailRequestGeneration;
    _emailLookupDebounce = Timer(const Duration(milliseconds: 450), () {
      final ctx = _context;
      if (ctx == null || !ctx.mounted) return;
      // ignore: discarded_futures
      _checkEmailAvailability(
        context: ctx,
        showWarningOnError: false,
        generation: generation,
      );
    });
  }

  Future<bool> ensureEmailAvailable(BuildContext context) async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty || Validators.email(email) != null || !canCheckEmail()) {
      validateEmailField();
      return false;
    }

    if (_lastCheckedEmail == email && isEmailAvailable == true) {
      return true;
    }
    if (_lastCheckedEmail == email && isEmailAvailable == false) {
      validateEmailField();
      return false;
    }
    if (_lastRequestedEmail == email && hasEmailCheckError) {
      return true;
    }

    final available = await _checkEmailAvailability(
      context: context,
      showWarningOnError: true,
      generation: ++_emailRequestGeneration,
    );

    if (!available) {
      validateEmailField();
    }

    return available;
  }

  Future<bool> _checkEmailAvailability({
    required BuildContext context,
    required bool showWarningOnError,
    required int generation,
  }) async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty || Validators.email(email) != null || !canCheckEmail()) {
      isCheckingEmail = false;
      isEmailAvailable = null;
      _lastCheckedEmail = null;
      emailAvailabilityMessage = null;
      _notifyStateChanged();
      return false;
    }

    isCheckingEmail = true;
    _lastRequestedEmail = email;
    emailAvailabilityMessage = 'Checking email...';
    _notifyStateChanged();

    try {
      final isAvailable = await context.read<AuthCubit>().isEmailAvailable(
        email,
      );

      if (generation != _emailRequestGeneration ||
          email != emailController.text.trim().toLowerCase()) {
        return false;
      }

      isCheckingEmail = false;
      isEmailAvailable = isAvailable;
      _lastCheckedEmail = email;
      emailAvailabilityMessage = isAvailable
          ? 'Email is available.'
          : 'This email is already registered.';
      validateEmailField();
      _notifyStateChanged();

      return isAvailable;
    } catch (_) {
      if (generation != _emailRequestGeneration ||
          email != emailController.text.trim().toLowerCase()) {
        return false;
      }

      isCheckingEmail = false;
      isEmailAvailable = null;
      _lastCheckedEmail = null;
      _lastRequestedEmail = email;
      emailAvailabilityMessage = 'Could not check this email.';
      validateEmailField();
      _notifyStateChanged();

      if (showWarningOnError && context.mounted) {
        CustomSnackBar.showWarning(
          context: context,
          title: 'Email check skipped',
          message: 'We will verify it while creating your account.',
        );
      }

      return showWarningOnError;
    }
  }

  // ── Phone ────────────────────────────────────────────────────────────────

  void schedulePhoneCheck() {
    _phoneLookupDebounce?.cancel();

    final validationMessage = validatePhoneFormat(phoneController.text);
    final phone = phoneForLookup();

    if (phone == _lastRequestedPhone && !isCheckingPhone) return;

    _lastCheckedPhone = null;
    _lastRequestedPhone = null;
    _phoneRequestGeneration++;
    isPhoneAvailable = null;
    isCheckingPhone = false;
    phoneAvailabilityMessage = null;
    _notifyStateChanged();

    if (validationMessage != null || !canCheckPhone()) return;

    _lastRequestedPhone = phone;
    final generation = _phoneRequestGeneration;
    _phoneLookupDebounce = Timer(const Duration(milliseconds: 450), () {
      final ctx = _context;
      if (ctx == null || !ctx.mounted) return;
      // ignore: discarded_futures
      _checkPhoneAvailability(
        context: ctx,
        showWarningOnError: false,
        generation: generation,
      );
    });
  }

  Future<bool> ensurePhoneAvailable(BuildContext context) async {
    final validationMessage = validatePhoneFormat(phoneController.text);

    if (validationMessage != null || !canCheckPhone()) {
      validatePhoneField();
      return false;
    }

    final phone = phoneForLookup();
    if (_lastCheckedPhone == phone && isPhoneAvailable == true) {
      return true;
    }
    if (_lastCheckedPhone == phone && isPhoneAvailable == false) {
      validatePhoneField();
      return false;
    }
    if (_lastRequestedPhone == phone && hasPhoneCheckError) {
      return true;
    }

    final available = await _checkPhoneAvailability(
      context: context,
      showWarningOnError: true,
      generation: ++_phoneRequestGeneration,
    );

    if (!available) {
      validatePhoneField();
    }

    return available;
  }

  Future<bool> _checkPhoneAvailability({
    required BuildContext context,
    required bool showWarningOnError,
    required int generation,
  }) async {
    final validationMessage = validatePhoneFormat(phoneController.text);

    if (validationMessage != null || !canCheckPhone()) {
      isCheckingPhone = false;
      isPhoneAvailable = null;
      _lastCheckedPhone = null;
      phoneAvailabilityMessage = null;
      _notifyStateChanged();
      return false;
    }

    final phone = phoneForLookup();

    isCheckingPhone = true;
    _lastRequestedPhone = phone;
    phoneAvailabilityMessage = 'Checking phone number...';
    _notifyStateChanged();

    try {
      final isAvailable = await context.read<AuthCubit>().isPhoneAvailable(
        phone,
      );

      if (generation != _phoneRequestGeneration || phone != phoneForLookup()) {
        return false;
      }

      isCheckingPhone = false;
      isPhoneAvailable = isAvailable;
      _lastCheckedPhone = phone;
      phoneAvailabilityMessage = isAvailable
          ? 'Phone number is available.'
          : 'This phone number is already registered.';
      validatePhoneField();
      _notifyStateChanged();

      return isAvailable;
    } catch (_) {
      if (generation != _phoneRequestGeneration || phone != phoneForLookup()) {
        return false;
      }

      isCheckingPhone = false;
      isPhoneAvailable = null;
      _lastCheckedPhone = null;
      _lastRequestedPhone = phone;
      phoneAvailabilityMessage = 'Could not check this phone number.';
      validatePhoneField();
      _notifyStateChanged();

      if (showWarningOnError && context.mounted) {
        CustomSnackBar.showWarning(
          context: context,
          title: 'Phone check skipped',
          message: 'We will verify it while creating your account.',
        );
      }

      return showWarningOnError;
    }
  }

  // ── Username ─────────────────────────────────────────────────────────────

  void scheduleUsernameCheck() {
    _usernameLookupDebounce?.cancel();

    final username = usernameController.text.trim();
    final validationMessage = validateUsername(username);

    if (username == _lastRequestedUsername && !isCheckingUsername) return;

    _lastCheckedUsername = null;
    _lastRequestedUsername = null;
    _usernameRequestGeneration++;
    isUsernameAvailable = null;
    isCheckingUsername = false;
    usernameAvailabilityMessage = validationMessage;
    _notifyStateChanged();

    if (username.isEmpty || validationMessage != null) return;

    _lastRequestedUsername = username;
    final generation = _usernameRequestGeneration;
    _usernameLookupDebounce = Timer(const Duration(milliseconds: 450), () {
      final ctx = _context;
      if (ctx == null || !ctx.mounted) return;
      // ignore: discarded_futures
      _checkUsernameAvailability(
        context: ctx,
        showWarningOnError: false,
        generation: generation,
      );
    });
  }

  Future<bool> ensureUsernameAvailable(BuildContext context) async {
    final username = usernameController.text.trim();

    if (username.isEmpty) return true;

    if (_lastCheckedUsername == username && isUsernameAvailable == true) {
      return true;
    }
    if (_lastCheckedUsername == username && isUsernameAvailable == false) {
      validateUsernameField();
      return false;
    }
    if (_lastRequestedUsername == username && hasUsernameCheckError) {
      return true;
    }

    final available = await _checkUsernameAvailability(
      context: context,
      showWarningOnError: true,
      generation: ++_usernameRequestGeneration,
    );

    if (!available) {
      validateUsernameField();
    }

    return available;
  }

  Future<bool> _checkUsernameAvailability({
    required BuildContext context,
    required bool showWarningOnError,
    required int generation,
  }) async {
    final username = usernameController.text.trim();
    final validationMessage = validateUsername(username);

    if (username.isEmpty) {
      isCheckingUsername = false;
      isUsernameAvailable = null;
      _lastCheckedUsername = null;
      usernameAvailabilityMessage = null;
      _notifyStateChanged();
      return true;
    }

    if (validationMessage != null) {
      isCheckingUsername = false;
      isUsernameAvailable = null;
      _lastCheckedUsername = null;
      usernameAvailabilityMessage = validationMessage;
      _notifyStateChanged();
      return false;
    }

    isCheckingUsername = true;
    _lastRequestedUsername = username;
    usernameAvailabilityMessage = 'Checking username...';
    _notifyStateChanged();

    try {
      final isAvailable = await context.read<AuthCubit>().isUsernameAvailable(
        username,
      );

      if (generation != _usernameRequestGeneration ||
          username != usernameController.text.trim()) {
        return false;
      }

      isCheckingUsername = false;
      isUsernameAvailable = isAvailable;
      _lastCheckedUsername = username;
      usernameAvailabilityMessage = isAvailable
          ? 'Username is available.'
          : 'This username is already taken.';
      validateUsernameField();
      _notifyStateChanged();

      return isAvailable;
    } catch (_) {
      if (generation != _usernameRequestGeneration ||
          username != usernameController.text.trim()) {
        return false;
      }

      isCheckingUsername = false;
      isUsernameAvailable = null;
      _lastCheckedUsername = null;
      _lastRequestedUsername = username;
      usernameAvailabilityMessage = 'Could not check this username.';
      validateUsernameField();
      _notifyStateChanged();

      if (showWarningOnError && context.mounted) {
        CustomSnackBar.showWarning(
          context: context,
          title: 'Username check skipped',
          message: 'We will verify it while creating your account.',
        );
      }

      return showWarningOnError;
    }
  }
}
