import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedJsonEntry {
  const CachedJsonEntry({required this.value, required this.savedAt});

  final Object? value;
  final DateTime savedAt;

  bool isFresh(Duration maxAge, {DateTime? now}) {
    final reference = now ?? DateTime.now().toUtc();
    return reference.difference(savedAt).abs() <= maxAge;
  }
}

class PersistentJsonCache {
  const PersistentJsonCache();

  static const _storagePrefix = 'catalog_cache.v1.';

  Future<CachedJsonEntry?> read(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final storageKey = _storageKey(key);
    final encoded = preferences.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final envelope = jsonDecode(encoded);
      if (envelope is! Map<String, dynamic>) return null;
      final savedAt = DateTime.tryParse(envelope['saved_at']?.toString() ?? '');
      if (savedAt == null || !envelope.containsKey('value')) return null;
      return CachedJsonEntry(
        value: envelope['value'],
        savedAt: savedAt.toUtc(),
      );
    } on FormatException {
      await preferences.remove(storageKey);
      return null;
    }
  }

  Future<void> write(String key, Object? value, {DateTime? savedAt}) async {
    final preferences = await SharedPreferences.getInstance();
    final envelope = <String, Object?>{
      'saved_at': (savedAt ?? DateTime.now().toUtc()).toIso8601String(),
      'value': value,
    };
    await preferences.setString(_storageKey(key), jsonEncode(envelope));
  }

  Future<void> remove(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey(key));
  }

  String _storageKey(String key) {
    final normalized = key.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]+'),
      '_',
    );
    return '$_storagePrefix$normalized';
  }
}
