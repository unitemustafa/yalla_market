# Yalla Market

Production-oriented Flutter marketplace app with official Android and iOS
support. Web, Windows, macOS, and Linux builds run without Firebase Messaging;
push notifications are enabled only on Android and iOS.

## Runtime configuration

The app expects a REST backend under `/api/v1`. Pass the API origin at build or
run time:

```bash
flutter run --dart-define=API_BASE_URL=https://yalla-backend-ecjct.ondigitalocean.app
flutter build appbundle --dart-define-from-file=env/production.json
```

Debug builds without `API_BASE_URL` use local demo repositories so the UI can be
developed before the backend is available. Release builds require
`API_BASE_URL`.

## API response shape

The full backend contract is documented in
[`docs/api-contract.md`](docs/api-contract.md).

Successful responses should return either a direct JSON payload or:

```json
{ "data": {} }
```

Errors should return:

```json
{ "message": "Human readable error", "code": "ERROR_CODE", "fields": {} }
```

## Android release signing

Copy `android/key.properties.example` to `android/key.properties` and point it
at your upload keystore before release builds. The example file is safe to keep
in source control; the real `android/key.properties` must stay private.

## Verification

```bash
flutter analyze
flutter test --coverage
flutter build apk --release --dart-define-from-file=env/production.json
```
