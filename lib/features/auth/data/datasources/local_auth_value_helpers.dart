String normalizeAuthEmail(String value) => value.trim().toLowerCase();

String normalizeAuthUsername(String value) => value.trim().toLowerCase();

String normalizeAuthPhone(String value) => value.replaceAll(RegExp(r'\D'), '');

String localAuthPasswordDigest(String password) {
  var hash = 2166136261;
  for (final unit in password.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

String localAuthUserId(String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'local-${normalized.isEmpty ? 'user' : normalized}';
}
