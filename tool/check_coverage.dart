import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/check_coverage.dart <lcov-file> [minimum-percent]',
    );
    exitCode = 64;
    return;
  }

  final coverageFile = File(arguments.first);
  final minimum = arguments.length == 2 ? double.tryParse(arguments[1]) : 64.0;
  if (minimum == null || minimum < 0 || minimum > 100) {
    stderr.writeln('Minimum coverage must be a number from 0 to 100.');
    exitCode = 64;
    return;
  }
  if (!coverageFile.existsSync()) {
    stderr.writeln('Coverage file not found: ${coverageFile.path}');
    exitCode = 66;
    return;
  }

  var executableLines = 0;
  var coveredLines = 0;
  for (final line in coverageFile.readAsLinesSync()) {
    if (!line.startsWith('DA:')) continue;
    final fields = line.substring(3).split(',');
    if (fields.length < 2) continue;
    final hits = int.tryParse(fields[1]);
    if (hits == null) continue;
    executableLines++;
    if (hits > 0) coveredLines++;
  }

  if (executableLines == 0) {
    stderr.writeln(
      'No executable Dart lines were found in ${coverageFile.path}.',
    );
    exitCode = 65;
    return;
  }

  final percent = coveredLines * 100 / executableLines;
  stdout.writeln(
    'Line coverage: ${percent.toStringAsFixed(2)}% '
    '($coveredLines/$executableLines), minimum ${minimum.toStringAsFixed(2)}%',
  );
  if (percent + 0.000001 < minimum) exitCode = 1;
}
