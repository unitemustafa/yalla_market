import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../models/local_auth_account.dart';
import 'local_auth_value_helpers.dart';

class LocalAuthStore {
  static const String _sessionKey = 'auth.local_session';
  static const String _accountsKey = 'auth.local_accounts';
  static const String _demoEmail = 'm@example.com';
  static const String _demoPassword = 'Password123!';
  static const String _marketEmail = 'market@admin.com';
  static const String _marketPassword = '01266666610';

  Future<StoredAuthSession?> loadSession() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSession = preferences.getString(_sessionKey);
    if (rawSession == null || rawSession.trim().isEmpty) return null;

    final decoded = jsonDecode(rawSession) as Map<String, dynamic>;
    return StoredAuthSession(
      user: authUserFromJson(decoded),
      expiresAt: _dateFromString(decoded['expiresAt']),
    );
  }

  Future<void> saveSession(AuthSession session, DateTime? expiresAt) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _sessionKey,
      jsonEncode({
        ...authUserToJson(session.user),
        'expiresAt': expiresAt?.toIso8601String(),
      }),
    );
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }

  Future<List<LocalAuthAccount>> loadAccounts() async {
    final preferences = await SharedPreferences.getInstance();
    final rawAccounts = preferences.getString(_accountsKey);
    if (rawAccounts == null || rawAccounts.trim().isEmpty) {
      return _seedAccounts();
    }

    final decoded = jsonDecode(rawAccounts) as List<dynamic>;
    final accounts = decoded
        .whereType<Map<String, dynamic>>()
        .map(LocalAuthAccount.fromJson)
        .toList(growable: true);
    return _withSeedAccounts(accounts);
  }

  Future<void> saveAccounts(List<LocalAuthAccount> accounts) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _accountsKey,
      jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }

  List<LocalAuthAccount> _seedAccounts() {
    const user = AuthUser(
      id: 'local-demo-shopper',
      email: _demoEmail,
      firstName: 'Yalla',
      lastName: 'Buyer',
      username: 'demo_buyer',
      role: 'CUSTOMER',
    );
    const marketUser = AuthUser(
      id: 'local-market-admin',
      email: _marketEmail,
      firstName: 'Market',
      lastName: 'Admin',
      username: 'market_admin',
      phone: _marketPassword,
      role: 'CUSTOMER',
    );

    return [
      LocalAuthAccount(
        user: user,
        passwordDigest: localAuthPasswordDigest(_demoPassword),
      ),
      LocalAuthAccount(
        user: marketUser,
        passwordDigest: localAuthPasswordDigest(_marketPassword),
      ),
    ];
  }

  List<LocalAuthAccount> _withSeedAccounts(List<LocalAuthAccount> accounts) {
    final merged = [...accounts];
    for (final seedAccount in _seedAccounts()) {
      if (merged.byEmail(seedAccount.user.email) == null) {
        merged.add(seedAccount);
      }
    }
    return merged;
  }
}

class StoredAuthSession {
  const StoredAuthSession({required this.user, required this.expiresAt});

  final AuthUser user;
  final DateTime? expiresAt;
}

DateTime? _dateFromString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}
