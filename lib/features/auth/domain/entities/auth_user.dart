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
    this.city,
    this.gender,
    this.birthDate,
    this.usernameChangedAt,
    this.isActive = true,
    this.profileUsernamePending = false,
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
  final String? city;
  final String? gender;
  final DateTime? birthDate;
  final DateTime? usernameChangedAt;
  final bool isActive;
  final bool profileUsernamePending;

  List<String> get missingProfileFields {
    return <String>[
      if ('$firstName $lastName'.trim().isEmpty) 'name',
      if (email.trim().isEmpty) 'email',
      if (profileUsernamePending || (username?.trim().isEmpty ?? true))
        'username',
      if (phone?.trim().isEmpty ?? true) 'phone',
      if (city?.trim().isEmpty ?? true) 'city',
      if (gender?.trim().isEmpty ?? true) 'gender',
      if (birthDate == null) 'birth_date',
    ];
  }

  int get profileCompletionPercent {
    const fieldCount = 7;
    final completed = fieldCount - missingProfileFields.length;
    return ((completed / fieldCount) * 100).round();
  }

  bool get isProfileComplete => missingProfileFields.isEmpty;

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
      city: _stringFromJson(json['city']),
      gender: _stringFromJson(json['gender']),
      birthDate: _dateFromString(json['birthDate'] ?? json['birth_date']),
      usernameChangedAt: _dateFromString(
        json['usernameChangedAt'] ?? json['username_changed_at'],
      ),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      profileUsernamePending:
          json['profile_username_pending'] as bool? ??
          json['profileUsernamePending'] as bool? ??
          false,
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
      'city': city,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'usernameChangedAt': usernameChangedAt?.toIso8601String(),
      'isActive': isActive,
      'profileUsernamePending': profileUsernamePending,
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
    String? city,
    String? gender,
    DateTime? birthDate,
    DateTime? usernameChangedAt,
    bool? isActive,
    bool? profileUsernamePending,
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
      city: city ?? this.city,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
      isActive: isActive ?? this.isActive,
      profileUsernamePending:
          profileUsernamePending ?? this.profileUsernamePending,
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
