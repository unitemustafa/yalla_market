class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.avatarUrl,
    this.hasPassword = true,
    this.username,
    this.phone,
    this.gender,
    this.birthDate,
    this.usernameChangedAt,
    this.isActive = true,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? avatarUrl;
  final bool hasPassword;
  final String? username;
  final String? phone;
  final String? gender;
  final DateTime? birthDate;
  final DateTime? usernameChangedAt;
  final bool isActive;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _stringFromJson(json['id']) ?? '',
      email: _stringFromJson(json['email']) ?? '',
      firstName:
          _personNameFromJson(json['firstName']) ??
          _personNameFromJson(json['first_name']) ??
          '',
      lastName:
          _personNameFromJson(json['lastName']) ??
          _personNameFromJson(json['last_name']) ??
          '',
      role: _stringFromJson(json['role']) ?? 'CUSTOMER',
      avatarUrl:
          _stringFromJson(json['avatarUrl']) ??
          _stringFromJson(json['avatar_url']),
      hasPassword:
          json['hasPassword'] as bool? ?? json['has_password'] as bool? ?? true,
      username: _stringFromJson(json['username']),
      phone: _stringFromJson(json['phone']),
      gender: _stringFromJson(json['gender']),
      birthDate: _dateFromString(json['birthDate'] ?? json['birth_date']),
      usernameChangedAt: _dateFromString(
        json['usernameChangedAt'] ?? json['username_changed_at'],
      ),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'avatarUrl': avatarUrl,
      'hasPassword': hasPassword,
      'username': username,
      'phone': phone,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'usernameChangedAt': usernameChangedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? avatarUrl,
    bool? hasPassword,
    String? username,
    String? phone,
    String? gender,
    DateTime? birthDate,
    DateTime? usernameChangedAt,
    bool? isActive,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasPassword: hasPassword ?? this.hasPassword,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

String? _stringFromJson(Object? value) {
  if (value == null) return null;
  return value.toString();
}

String? _personNameFromJson(Object? value) {
  final name = _stringFromJson(value)?.trim();
  return name == '-' ? '' : name;
}

DateTime? _dateFromString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}
