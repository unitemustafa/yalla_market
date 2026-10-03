import 'dart:io';

import 'package:yalla_market/core/localization/app_text_catalog.dart';

/// Checks the editable constants and their compatibility catalog without Flutter.
void main() {
  var valid = true;
  final localization = Platform.script.resolve('../lib/core/localization/');
  final arabicMembers = _members(
    File.fromUri(localization.resolve('app_texts_ar.dart')).readAsStringSync(),
  );
  final englishMembers = _members(
    File.fromUri(localization.resolve('app_texts_en.dart')).readAsStringSync(),
  );
  for (final (language, missing) in [
    ('Arabic', englishMembers.difference(arabicMembers)),
    ('English', arabicMembers.difference(englishMembers)),
  ]) {
    if (missing.isEmpty) continue;
    valid = false;
    stderr.writeln(
      'Missing $language constants or helpers: ${missing.join(', ')}',
    );
  }
  for (final (name, entries) in [
    ('keyed', AppTextCatalog.keyed),
    ('phrases', AppTextCatalog.phrases),
  ]) {
    for (final entry in entries.entries) {
      for (final (language, value) in [
        ('Arabic', entry.value.ar),
        ('English', entry.value.en),
      ]) {
        if (entry.key.trim().isNotEmpty && value.trim().isNotEmpty) continue;
        valid = false;
        stderr.writeln('$name: empty $language text or key: ${entry.key}');
      }
    }
  }
  if (!valid) {
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Translations passed: ${AppTextCatalog.keyed.length} keyed texts and '
    '${AppTextCatalog.phrases.length} phrases; matching named constants and '
    'helpers in Arabic and English.',
  );
}

Set<String> _members(String source) {
  final result = <String>{};
  final classes = RegExp(
    r'^abstract final class (\w+) \{([\s\S]*?)^\}',
    multiLine: true,
  );
  final members = RegExp(r'\bstatic (?:const|String) (\w+)');
  for (final section in classes.allMatches(source)) {
    for (final member in members.allMatches(section.group(2)!)) {
      result.add('${section.group(1)}.${member.group(1)}');
    }
  }
  return result;
}
