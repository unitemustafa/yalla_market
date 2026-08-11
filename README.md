# Yalla Market

Production Flutter marketplace application. Android and iOS are the supported
release targets. Web and desktop builds are useful for development, but push
notifications and every native capability are guaranteed only on mobile.

## First-time setup

1. Install Flutter `3.41.6` and the matching Android/iOS toolchains.
2. Run `flutter pub get`.
3. Copy an environment template to a local ignored file and fill its values:

   ```powershell
   Copy-Item env/development.example.json env/development.local.json
   ```

4. Start against the configured backend:

   ```bash
   flutter run --dart-define-from-file=env/development.local.json
   ```

Debug builds without `API_BASE_URL` use local demo repositories. Release builds
fail closed when the backend URL is absent or insecure. The REST API is expected
under `/api/v1`; its wire contract is in
[`docs/api-contract.md`](docs/api-contract.md).

## Project map

```text
lib/
  core/                 feature-neutral infrastructure and shared UI primitives
  features/<feature>/
    data/               API, persistence, DTOs, repository implementations
    domain/             entities, repository contracts, use cases
    presentation/       Cubits, state, views, feature widgets
  main.dart             process entry point
  yalla_market_app.dart application shell and cross-feature coordination
```

Dependencies flow from presentation to domain to data contracts. Cubits call use
cases, repositories own data access, and demo/remote selection happens in DI.
See [`ARCHITECTURE.md`](ARCHITECTURE.md) before changing a feature and
[`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request.

## Daily verification

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart coverage/lcov.info 64
flutter build apk --debug
```

The coverage floor protects the current baseline; new and changed domain, data,
and Cubit code should normally be covered at 80% or better.

## Release

Copy `android/key.properties.example` to `android/key.properties` and point it
at the upload keystore. Never commit the real signing file, Firebase plist, or a
local runtime configuration.

```bash
dart run tool/release_preflight.dart env/production.local.json --platform=android
flutter build appbundle --release --obfuscate \
  --split-debug-info=build/debug-symbols/android \
  --dart-define-from-file=env/production.local.json
```

Use `--platform=ios` before an App Store archive and follow
`ios/README_RELEASE.md`. Archive the matching debug symbols before running
`flutter clean`; obfuscated Crashlytics traces require them.
