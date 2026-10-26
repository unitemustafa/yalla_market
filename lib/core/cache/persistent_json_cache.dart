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
  const PersistentJsonCache({
    this.maxEntries = 80,
    this.maxCharacters = 4 * 1024 * 1024,
    this.maxEntryCharacters = 512 * 1024,
    this.maxAge = const Duration(days: 7),
    this.now,
  });

  final int maxEntries;
  final int maxCharacters;
  final int maxEntryCharacters;
  final Duration maxAge;
  final DateTime Function()? now;
  static Future<void> _writes = Future.value();

  static const _storagePrefix = 'catalog_cache.v1.';
  static final _savedAtHeader = RegExp(r'^\s*\{\s*"saved_at"\s*:\s*"([^"]+)"');

  Future<CachedJsonEntry?> read(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final storageKey = _storageKey(key);
    final encoded = preferences.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return null;
    if (encoded.length > maxEntryCharacters) {
      await preferences.remove(storageKey);
      return null;
    }

    try {
      final envelope = jsonDecode(encoded);
      if (envelope is! Map<String, dynamic>) return null;
      final savedAt = DateTime.tryParse(envelope['saved_at']?.toString() ?? '');
      if (savedAt == null || !envelope.containsKey('value')) return null;
      if ((now?.call() ?? DateTime.now()).toUtc().difference(savedAt.toUtc()) >
          maxAge) {
        await preferences.remove(storageKey);
        return null;
      }
      return CachedJsonEntry(
        value: envelope['value'],
        savedAt: savedAt.toUtc(),
      );
    } on FormatException {
      await preferences.remove(storageKey);
      return null;
    }
  }

  Future<void> write(String key, Object? value, {DateTime? savedAt}) {
    final operation = _writes.then((_) => _write(key, value, savedAt: savedAt));
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _write(String key, Object? value, {DateTime? savedAt}) async {
    final preferences = await SharedPreferences.getInstance();
    final envelope = <String, Object?>{
      'saved_at': (savedAt ?? (now?.call() ?? DateTime.now()).toUtc())
          .toIso8601String(),
      'value': value,
    };
    final encoded = jsonEncode(envelope);
    final storageKey = _storageKey(key);
    if (encoded.length > maxEntryCharacters ||
        encoded.length > maxCharacters ||
        maxEntries < 1) {
      await preferences.remove(storageKey);
      return;
    }
    final entries = <(String, String)>[];
    var total = encoded.length;
    for (final entryKey in preferences.getKeys().where(
      (k) => k.startsWith(_storagePrefix) && k != storageKey,
    )) {
      final raw = preferences.getString(entryKey);
      if (raw == null) continue;
      entries.add((entryKey, raw));
      total += raw.length;
    }
    DateTime saved(String raw) {
      // Our envelope writes saved_at first. Eviction must not decode every
      // cached catalog just to compare timestamps, especially during migration.
      final header = raw.substring(0, raw.length.clamp(0, 128));
      return DateTime.tryParse(
            _savedAtHeader.firstMatch(header)?.group(1) ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    // Sort only timestamp metadata when the configured bounds are exceeded.
    if (entries.length + 1 > maxEntries || total > maxCharacters) {
      final times = {for (final entry in entries) entry.$1: saved(entry.$2)};
      entries.sort((a, b) => times[a.$1]!.compareTo(times[b.$1]!));
      var count = entries.length + 1;
      for (final entry in entries) {
        if (count <= maxEntries && total <= maxCharacters) break;
        await preferences.remove(entry.$1);
        total -= entry.$2.length;
        count--;
      }
    }
    await preferences.setString(storageKey, encoded);
  }

  String _storageKey(String key) {
    final normalized = key.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]+'),
      '_',
    );
    return '$_storagePrefix$normalized';
  }
}
