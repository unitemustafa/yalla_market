import '../../domain/entities/auth_user.dart';
import '../datasources/local_auth_value_helpers.dart';

class LocalAuthAccount {
  const LocalAuthAccount({required this.user, required this.passwordDigest});

  final AuthUser user;
  final String passwordDigest;

  LocalAuthAccount copyWith({AuthUser? user, String? passwordDigest}) {
    return LocalAuthAccount(
      user: user ?? this.user,
      passwordDigest: passwordDigest ?? this.passwordDigest,
    );
  }

  factory LocalAuthAccount.fromJson(Map<String, dynamic> json) {
    return LocalAuthAccount(
      user: authUserFromJson(json['user'] as Map<String, dynamic>),
      passwordDigest: json['passwordDigest'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {'user': authUserToJson(user), 'passwordDigest': passwordDigest};
  }
}

Map<String, Object?> authUserToJson(AuthUser user) {
  return {
    'id': user.id,
    'email': user.email,
    'firstName': user.firstName,
    'lastName': user.lastName,
    'role': user.role,
    'avatarUrl': user.avatarUrl,
    'hasPassword': user.hasPassword,
    'username': user.username,
    'phone': user.phone,
    'gender': user.gender,
    'birthDate': user.birthDate?.toIso8601String(),
    'usernameChangedAt': user.usernameChangedAt?.toIso8601String(),
  };
}

AuthUser authUserFromJson(Map<String, dynamic> json) {
  return AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    role: json['role'] as String? ?? 'CUSTOMER',
    avatarUrl: json['avatarUrl'] as String?,
    hasPassword: json['hasPassword'] as bool? ?? true,
    username: json['username'] as String?,
    phone: json['phone'] as String?,
    gender: json['gender'] as String?,
    birthDate: _dateFromString(json['birthDate']),
    usernameChangedAt: _dateFromString(json['usernameChangedAt']),
  );
}

DateTime? _dateFromString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

extension LocalAuthAccountsLookup on List<LocalAuthAccount> {
  LocalAuthAccount? byEmail(String email) {
    final normalized = normalizeAuthEmail(email);
    for (final account in this) {
      if (normalizeAuthEmail(account.user.email) == normalized) return account;
    }
    return null;
  }

  LocalAuthAccount? byUserId(String id) {
    for (final account in this) {
      if (account.user.id == id) return account;
    }
    return null;
  }

  LocalAuthAccount? byLoginIdentifier(String value) {
    final normalizedEmail = normalizeAuthEmail(value);
    final normalizedUsername = normalizeAuthUsername(value);
    final normalizedPhone = normalizeAuthPhone(value);

    for (final account in this) {
      if (normalizeAuthEmail(account.user.email) == normalizedEmail) {
        return account;
      }
      if (normalizeAuthUsername(account.user.username ?? '') ==
          normalizedUsername) {
        return account;
      }
      if (normalizedPhone.length >= 10 &&
          normalizeAuthPhone(account.user.phone ?? '') == normalizedPhone) {
        return account;
      }
    }
    return null;
  }
}
