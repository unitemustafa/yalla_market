import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/auth_user.dart';

class UserProfileController extends ChangeNotifier
    implements ValueListenable<UserProfileController> {
  UserProfileController._();

  static final UserProfileController instance = UserProfileController._();

  String _displayName = 'Guest User';
  String _id = '';
  String _firstName = 'Guest';
  String _lastName = 'User';
  String _username = 'guest';
  String _email = 'guest@yallamarket.local';
  String _phone = '';
  String _city = '';
  String _gender = '';
  bool _hasPassword = true;
  DateTime? _birthDate;
  DateTime? _usernameChangedAt;
  String? _avatarUrl;
  Uint8List? _avatarBytes;
  int _profileCompletionPercent = 100;
  List<String> _missingProfileFields = const [];

  String get displayName => _displayName;
  String get id => _id;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get username => _username;
  String get email => _email;
  String get phone => _phone;
  String get city => _city;
  String get gender => _gender;
  bool get hasPassword => _hasPassword;
  DateTime? get birthDate => _birthDate;
  DateTime? get usernameChangedAt => _usernameChangedAt;
  String? get avatarUrl => _avatarUrl;
  Uint8List? get avatarBytes => _avatarBytes;
  int get profileCompletionPercent => _profileCompletionPercent;
  List<String> get missingProfileFields => _missingProfileFields;
  bool get isProfileComplete => _missingProfileFields.isEmpty;
  DateTime? get nextUsernameChangeAt {
    final changedAt = _usernameChangedAt;
    if (changedAt == null) return null;
    return changedAt.add(const Duration(days: 7));
  }

  bool get canChangeUsername {
    final nextChangeAt = nextUsernameChangeAt;
    return nextChangeAt == null || !nextChangeAt.isAfter(DateTime.now());
  }

  @override
  UserProfileController get value => this;

  String get initials {
    final words = _displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'U';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();

    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  void updateDisplayName(String value) {
    final nextName = value.trim();
    if (nextName.isEmpty || nextName == _displayName) return;

    _displayName = nextName;
    notifyListeners();
  }

  void updateAvatar(Uint8List bytes) {
    _avatarBytes = bytes;
    notifyListeners();
  }

  void updateFromAuthUser(AuthUser user) {
    final nextDisplayName = '${user.firstName} ${user.lastName}'.trim();

    _id = user.id;
    _firstName = user.firstName;
    _lastName = user.lastName;
    _displayName = nextDisplayName.isEmpty ? user.email : nextDisplayName;
    _username =
        !user.profileUsernamePending && user.username?.trim().isNotEmpty == true
        ? user.username!.trim()
        : '';
    _email = user.email;
    _phone = _displayPhone(user.phone);
    _city = user.city ?? '';
    _gender = user.gender ?? '';
    _hasPassword = user.hasPassword;
    _birthDate = user.birthDate;
    _usernameChangedAt = user.usernameChangedAt;
    _avatarUrl = user.avatarUrl;
    _avatarBytes = null;
    _profileCompletionPercent = user.profileCompletionPercent;
    _missingProfileFields = List.unmodifiable(user.missingProfileFields);
    notifyListeners();
  }

  void reset() {
    _displayName = 'Guest User';
    _id = '';
    _firstName = 'Guest';
    _lastName = 'User';
    _username = 'guest';
    _email = 'guest@yallamarket.local';
    _phone = '';
    _city = '';
    _gender = '';
    _hasPassword = true;
    _birthDate = null;
    _usernameChangedAt = null;
    _avatarUrl = null;
    _avatarBytes = null;
    _profileCompletionPercent = 100;
    _missingProfileFields = const [];
    notifyListeners();
  }

  String _displayPhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return '';

    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('20')) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 10 && digits.startsWith('1')) {
      return '0$digits';
    }
    return phone;
  }
}
