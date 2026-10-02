# Mobile release checks

The manually triggered `Mobile release checks` workflow builds a signed Android
App Bundle and compiles the iOS app without Apple signing. Configure these
repository secrets before running it:

| Secret | Value |
| --- | --- |
| `API_BASE_URL` | Production HTTPS API URL. |
| `MAPTILER_API_KEY` | MapTiler client key restricted to this application. |
| `ANDROID_KEYSTORE_BASE64` | Base64 encoding of the existing production keystore. |
| `ANDROID_KEY_ALIAS` | Signing alias in that keystore. |
| `ANDROID_KEY_PASSWORD` | Password of the signing key. |
| `ANDROID_STORE_PASSWORD` | Password of the keystore. |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | Base64 encoding of the Firebase iOS configuration for `com.yallamarket.app`. |

Use the existing production signing key for updates. Keep the keystore and its
passwords in a secure backup. The workflow writes signing files only in its
temporary checkout and removes them after the build. Successful Android bundles
are retained as workflow artifacts for 14 days.

Crashlytics mapping upload is enabled by default. For a verification build where
external upload should be skipped, set the repository variable
`SKIP_CRASHLYTICS_MAPPING_UPLOAD` to `true`; restore it to `false` for release.

For local builds, run tests and analysis before the release build, then use
`flutter build appbundle --release --dart-define-from-file=env/production.local.json`.
Do not run Flutter commands against the same checkout concurrently. A release
build needs native plugin registration regenerated after tests; omitting pub
with `--no-pub` can preserve development-only plugin registration.

The unsigned iOS build does not produce an App Store release. Publishing still
requires an Apple team, signing certificates/profiles, App Store Connect setup,
and validation on an iPhone or TestFlight.
