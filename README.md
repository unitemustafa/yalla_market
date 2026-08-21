<div align="center">
  <img src="assets/logos/yallamarket_home_logo.png" alt="Yalla Market logo" width="180">

  # Yalla Market

  A production-ready Flutter marketplace for discovering stores, browsing
  products and offers, and completing the customer shopping journey.
</div>

Yalla Market is built primarily for Android and iOS. Web and desktop builds are
useful during development, but push notifications and other native capabilities
are supported and release-tested only on mobile.

## Features

- Product, category, brand, store, and promotional-offer discovery
- Search, wishlists, cart management, checkout, and order history
- Authentication, email verification, password recovery, and secure sessions
- Delivery-city selection, saved addresses, geolocation, and MapTiler maps
- Arabic and English localization with right-to-left layout support
- System, light, and dark appearance modes
- Deep links, Firebase push notifications, and Crashlytics reporting
- Offline-aware networking with local demo repositories for development

## Tech stack

- **Flutter and Dart** for the application and shared mobile codebase
- **Cubit / flutter_bloc** for presentation state management
- **get_it** for dependency injection
- **Dio** for REST API communication and token refresh
- **Firebase** for Cloud Messaging and Crashlytics
- **flutter_map and MapTiler** for maps and location-based flows
- **Shared Preferences and secure storage** for settings and session data

## Requirements

- Flutter `3.41.6` on the stable channel
- The Android SDK and an Android emulator or physical device
- Xcode, CocoaPods, and an Apple Developer setup for iOS builds

The project declares Dart SDK `^3.11.4`; the required Dart version is included
with the pinned Flutter SDK.

## Getting started

Install the project dependencies from the repository root:

```bash
flutter pub get
```

### Run in demo mode

For the quickest local setup, start a debug build without an API URL:

```bash
flutter run
```

Debug builds without `API_BASE_URL` automatically use the bundled demo
repositories. The seeded demo account is:

```text
Email: m@example.com
Password: Password123!
```

### Run with a backend

Copy the development environment template to an ignored local file:

```bash
cp env/development.example.json env/development.local.json
```

On PowerShell, use:

```powershell
Copy-Item env/development.example.json env/development.local.json
```

Fill in the local values, then run:

```bash
flutter run --dart-define-from-file=env/development.local.json
```

The application expects the REST API under `API_BASE_URL/api/v1`. See the
[API contract](docs/api-contract.md) for the required endpoints, payloads, and
response envelopes.

## Environment configuration

| Variable | Required | Purpose |
| --- | --- | --- |
| `API_BASE_URL` | Backend and production builds | HTTPS root URL of the backend; the app adds `/api/v1` |
| `MAPTILER_API_KEY` | Map-enabled and production builds | Restricted client key used by MapTiler |
| `PORTFOLIO_DEMO` | No | Allows a release-mode portfolio build to use demo data |

Templates are available for development, staging, and production in `env/`.
Keep `*.local.json`, signing material, and deployment-specific Firebase files
out of version control.

## Project structure

```text
lib/
  app/                   application coordination and dependency registration
  core/                  feature-neutral infrastructure and shared UI
  features/<feature>/
    data/                API clients, DTOs, persistence, and repositories
    domain/              entities, repository contracts, and use cases
    presentation/        Cubits, state, views, and feature widgets
  main.dart              process entry point
  yalla_market_app.dart  application shell
```

The application follows a feature-first, layered architecture:

```text
Widget -> Cubit -> Use case -> Repository contract <- Repository implementation
```

Read [ARCHITECTURE.md](ARCHITECTURE.md) before changing a feature and
[CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Quality checks

Run the same checks enforced by CI:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
dart run tool/check_source_size.dart
flutter test --coverage --reporter expanded
dart run tool/check_coverage.dart coverage/lcov.info 64
flutter build apk --debug
```

The repository-wide line-coverage floor is 64%. New or changed domain, data,
and Cubit code should normally maintain at least 80% coverage.

## Release builds

Release builds require valid HTTPS backend configuration and a MapTiler key,
unless they are explicitly built as a portfolio demo.

### Android

Copy `android/key.properties.example` to `android/key.properties` and configure
the upload keystore. Then run the preflight check and build the app bundle:

```bash
dart run tool/release_preflight.dart env/production.local.json --platform=android
flutter build appbundle --release --obfuscate \
  --split-debug-info=build/debug-symbols/android \
  --dart-define-from-file=env/production.local.json
```

### iOS

Run the release preflight with `--platform=ios`, then follow the
[iOS release guide](ios/README_RELEASE.md) on a Mac with Xcode.

Archive the matching debug symbols before running `flutter clean`; obfuscated
Crashlytics traces require them. Complete the
[release checklist](docs/RELEASE_CHECKLIST.md) before publishing either mobile
build.

## Documentation

- [Architecture](ARCHITECTURE.md)
- [Contributing guide](CONTRIBUTING.md)
- [API contract](docs/api-contract.md)
- [Release checklist](docs/RELEASE_CHECKLIST.md)
- [iOS release guide](ios/README_RELEASE.md)
