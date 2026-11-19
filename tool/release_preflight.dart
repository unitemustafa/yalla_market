import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final environmentPath = arguments
      .where((argument) => !argument.startsWith('--platform='))
      .firstOrNull;
  final platform = arguments
      .where((argument) => argument.startsWith('--platform='))
      .map((argument) => argument.substring('--platform='.length))
      .firstOrNull;
  final errors = <String>[];

  if (platform != null && platform != 'android' && platform != 'ios') {
    errors.add('Platform must be android or ios.');
  }

  if (environmentPath == null) {
    errors.add('Pass the production JSON file path.');
  } else {
    final file = File(environmentPath);
    if (!file.existsSync()) {
      errors.add('Production environment file is missing.');
    } else {
      try {
        final value = jsonDecode(file.readAsStringSync());
        final environment = value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{};
        final apiBaseUrl = environment['API_BASE_URL']?.toString().trim() ?? '';
        final apiUri = Uri.tryParse(apiBaseUrl);
        if (apiUri == null ||
            apiUri.scheme != 'https' ||
            apiUri.host.isEmpty ||
            apiUri.userInfo.isNotEmpty ||
            apiUri.hasQuery ||
            apiUri.hasFragment ||
            (apiUri.path.isNotEmpty && apiUri.path != '/') ||
            apiUri.host == 'localhost' ||
            apiUri.host.endsWith('.localhost') ||
            apiUri.host.endsWith('.invalid') ||
            apiUri.host == 'example.com' ||
            apiUri.host.endsWith('.example.com') ||
            InternetAddress.tryParse(apiUri.host)?.isLoopback == true) {
          errors.add('API_BASE_URL must be a public HTTPS root URL.');
        }
        if ((environment['MAPTILER_API_KEY']?.toString().trim() ?? '')
            .isEmpty) {
          errors.add('MAPTILER_API_KEY is missing.');
        }
        for (final flag in ['PORTFOLIO_DEMO', 'PERFORMANCE_TEST_BUILD']) {
          if (environment[flag]?.toString().toLowerCase() == 'true') {
            errors.add('$flag must be disabled for Google Play.');
          }
        }
      } on FormatException {
        errors.add('Production environment file is not valid JSON.');
      }
    }
  }

  if (platform == null || platform == 'android') {
    _validateAndroidFirebase(errors);
    _validateAndroidSigning(errors);
  }
  if (platform == null || platform == 'ios') {
    if (!File('ios/Runner/GoogleService-Info.plist').existsSync()) {
      errors.add('iOS Firebase configuration is missing.');
    }
    _validateAppleTeam(errors);
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Release preflight failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 2;
    return;
  }
  stdout.writeln('Release preflight passed.');
}

void _validateAndroidFirebase(List<String> errors) {
  final file = File('android/app/google-services.json');
  if (!file.existsSync()) {
    errors.add('Android Firebase configuration is missing.');
    return;
  }
  try {
    final value = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final clients = value['client'] as List;
    final client = clients.cast<Map<String, dynamic>>().where((client) {
      final info = client['client_info'] as Map<String, dynamic>;
      final android = info['android_client_info'] as Map<String, dynamic>;
      return android['package_name'] == 'com.yallamarket.app.com';
    }).firstOrNull;
    if (client == null) {
      errors.add('Firebase has no client matching the Android application ID.');
      return;
    }
    final oauthClients = client['oauth_client'] as List? ?? const [];
    if (!oauthClients.any((client) => client['client_type'] == 3)) {
      errors.add(
        'Firebase is missing the web OAuth client for Google sign-in.',
      );
    }
  } catch (_) {
    errors.add('Android Firebase configuration is invalid.');
  }
}

void _validateAndroidSigning(List<String> errors) {
  final file = File('android/key.properties');
  if (!file.existsSync()) {
    errors.add('Android upload signing configuration is missing.');
    return;
  }
  final properties = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final separator = line.indexOf('=');
    if (separator <= 0 || line.trimLeft().startsWith('#')) continue;
    properties[line.substring(0, separator).trim()] = line
        .substring(separator + 1)
        .trim();
  }
  for (final key in ['storeFile', 'storePassword', 'keyAlias', 'keyPassword']) {
    if (properties[key]?.isNotEmpty != true) {
      errors.add('Android signing property $key is missing.');
    }
  }
}

void _validateAppleTeam(List<String> errors) {
  final project = File('ios/Runner.xcodeproj/project.pbxproj');
  if (!project.existsSync() ||
      !RegExp(
        r'DEVELOPMENT_TEAM\s*=\s*[A-Z0-9]{10};',
      ).hasMatch(project.readAsStringSync())) {
    errors.add('Select an Apple Development Team in the iOS Runner target.');
  }
}
