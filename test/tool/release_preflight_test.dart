import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final script = File('tool/release_preflight.dart').absolute.path;
  late Directory fixture;

  setUp(() {
    fixture = Directory.systemTemp.createTempSync('yalla-release-preflight-');
    Directory('${fixture.path}/android/app').createSync(recursive: true);
    File('${fixture.path}/android/key.properties').writeAsStringSync(
      'storeFile=test.jks\nstorePassword=test-only\n'
      'keyAlias=upload\nkeyPassword=test-only\n',
    );
    File('${fixture.path}/android/app/google-services.json').writeAsStringSync(
      jsonEncode({
        'client': [
          {
            'client_info': {
              'android_client_info': {
                'package_name': 'com.yallamarket.app.com',
              },
            },
            'oauth_client': [
              {'client_type': 3},
            ],
          },
        ],
      }),
    );
  });

  tearDown(() => fixture.deleteSync(recursive: true));

  Future<ProcessResult> run({
    String url = 'https://api.market.test',
    Map<String, Object> flags = const {},
    String platform = 'android',
  }) {
    File('${fixture.path}/production.json').writeAsStringSync(
      jsonEncode({
        'API_BASE_URL': url,
        'MAPTILER_API_KEY': 'test-only-key',
        ...flags,
      }),
    );
    // flutter_tester is not a Dart CLI executable; use the pinned SDK binary.
    final dart =
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/dart-sdk/bin/'
        '${Platform.isWindows ? 'dart.exe' : 'dart'}';
    return Process.run(dart, [
      script,
      'production.json',
      '--platform=$platform',
    ], workingDirectory: fixture.path);
  }

  test(
    'accepts a production root with matching Firebase and signing',
    () async {
      expect((await run()).exitCode, 0);
    },
  );

  test('rejects release modes which bypass real production services', () async {
    for (final flag in ['PORTFOLIO_DEMO', 'PERFORMANCE_TEST_BUILD']) {
      final result = await run(flags: {flag: true});
      expect(result.exitCode, 2);
      expect(result.stderr, contains('$flag must be disabled'));
    }
  });

  test('rejects malformed, credentialed and local backend roots', () async {
    for (final url in [
      'http://api.market.test',
      'https://localhost',
      'https://127.0.0.1',
      'https://api.example.com',
      'https://api.market.test/api/v1',
      'https://user:private@api.market.test',
      'https://api.market.test?key=private',
      'https://api.market.test/#fragment',
    ]) {
      final result = await run(url: url);
      expect(result.exitCode, 2, reason: url);
      expect(result.stderr, contains('public HTTPS root URL'));
      expect(result.stderr, isNot(contains('private')));
    }
  });

  test('rejects Firebase configuration for a different package', () async {
    final config = File('${fixture.path}/android/app/google-services.json');
    config.writeAsStringSync(
      config.readAsStringSync().replaceAll(
        'com.yallamarket.app.com',
        'com.other.app',
      ),
    );
    final result = await run();
    expect(result.exitCode, 2);
    expect(result.stderr, contains('no client matching'));
  });

  test('rejects missing upload signing configuration', () async {
    File('${fixture.path}/android/key.properties').deleteSync();
    final result = await run();
    expect(result.exitCode, 2);
    expect(result.stderr, contains('upload signing configuration is missing'));
  });

  test('rejects unknown platforms instead of skipping native checks', () async {
    final result = await run(platform: 'andriod');
    expect(result.exitCode, 2);
    expect(result.stderr, contains('Platform must be android or ios'));
  });
}
