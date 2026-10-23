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

## Editing display text

All translation text lives in `lib/core/localization/`:

- `app_texts_ar.dart`: Arabic text, grouped by screen and section.
- `app_texts_en.dart`: English text with the same constant names and sections.
- `app_text_catalog.dart`: references that connect existing translation keys to
  the named constants in both languages.
- `app_translations.dart`: locale selection and the existing `context.tr` API.
- `app_language_controller.dart`: language selection and persistence.

Edit the named constant in the appropriate section, such as `CommonTexts.retry`
or `AuthTexts.invalidCredentials`, to change the displayed text. Keep its name
unchanged; the compatibility catalog references that constant directly. Both
language files use the same names, so their order does not need to match. Count
and region formatting helpers are beside their section's text.

To add new text, add the same constant name to both language files, then register
its Arabic and English references in `app_text_catalog.dart`. Its phrase key is
the original English string passed to `context.tr`. Existing translations and
`context.translations` getters keep their current API.

Check both catalogs after editing:

```bash
dart run tool/check_translations.dart
flutter test test/core/localization
```

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

The application expects the REST API under `API_BASE_URL/api/v1`.

## Environment configuration

| Variable | Required | Purpose |
| --- | --- | --- |
| `API_BASE_URL` | Backend and production builds | HTTPS root URL of the backend; the app adds `/api/v1` |
| `MAPTILER_API_KEY` | Map-enabled and production builds | Restricted client key used by MapTiler |
| `PORTFOLIO_DEMO` | No | Allows a release-mode portfolio build to use demo data |

Templates are available for development, staging, and production in `env/`.
Keep `*.local.json`, signing material, and deployment-specific Firebase files
out of version control.

## Shared links

Product links include the selected variant in `?variant=<id>`. Old product,
offer and store links continue to work. The landing page shows a preview and
an explicit app-open button, so a device without the test app can read it.
Store download buttons remain hidden until the backend's store URLs are set.

Android's verified-link host comes from the build's `API_BASE_URL`. Before an
iOS build against a different backend, regenerate its Associated Domains host:

```bash
python tool/configure_shared_links.py env/production.local.json
```

The iOS release workflow runs the same step using its `API_BASE_URL` environment
variable. Enable Associated Domains in the Apple App ID/provisioning profile.
On the backend, configure `ANDROID_APP_LINK_FINGERPRINTS` for the certificates
that sign installed builds and `IOS_APP_LINK_APP_IDS` for the Apple application
identifier. Their public association documents are served at
`/.well-known/assetlinks.json` and `/.well-known/apple-app-site-association`.
These files must be accessible over HTTPS on the same API host without a redirect.

Before store publication, these settings can remain empty and the explicit
`yallamarket://` open button supports installed test builds. To verify direct
HTTPS opening before publication, configure the test build's signing certificate
and Apple application identifier. After publication, use the Play App Signing
certificate for Play installs and set the backend's `ANDROID_APP_STORE_URL` and
`IOS_APP_STORE_URL` to the real listings. Sharing a URL does not install the app
or preserve a selection through a fresh installation.

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

Run the release preflight with `--platform=ios`, then build and sign the app
on a Mac with Xcode.

- Minimum supported iOS version: **15.0**.
- Supply `ios/Runner/GoogleService-Info.plist` for `com.yallamarket.app`.
- Select the Runner signing team and configure provisioning with Push
  Notifications, Remote notifications, Keychain Sharing, Sign in with Apple,
  and the configured Associated Domains capability enabled.
- Upload the matching APNs key in Firebase and enable the Apple, Google, and
  Facebook sign-in providers in their respective consoles.
- Facebook Limited Login uses a per-request SHA-256 nonce and an ID token;
  Android classic login continues to use the access token.

Verify a fresh installation on a real iPhone before TestFlight: social login
and reauthentication, remembered login after a restart, notification permissions
and foreground/background pushes, location and photo permissions, image saving,
sharing, and checkout. Windows tests do not validate native iOS builds.

Archive the matching debug symbols before running `flutter clean`; obfuscated
Crashlytics traces require them.
