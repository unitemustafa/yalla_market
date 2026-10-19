import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 65),
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    final output =
        Platform.environment['PERF_OUTPUT'] ?? 'build/performance/raw.json';
    final file = File(output);
    await file.parent.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  },
);
