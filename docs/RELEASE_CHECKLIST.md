# Yalla Market release checklist

## Automated gates

- `flutter analyze`
- `flutter test`
- `flutter build appbundle --release --dart-define-from-file=env/production.json`
- Verify the APK/AAB signature and record SHA-256 hashes.

## Android

- Keep `android/key.properties` and the upload keystore outside Git.
- Upload the AAB to Google Play Internal Testing first.
- Verify Firebase Messaging and Crashlytics with the production application ID.
- Test Android notification permission, location permission, and offline recovery.

## iOS

- Follow `ios/README_RELEASE.md` on a Mac.
- Add the production Firebase plist and configure APNs.
- Test the IPA on a real iPhone through TestFlight.

## End-to-end customer flow

- Persistent sign-in and force-stop/relaunch.
- Select delivery city and save a valid address.
- Browse products, variants, offers, favorites, and cart updates.
- Preview checkout, create an order, and verify order history.
- Receive foreground, background, and opened push notifications.
- Disable the network and confirm the offline banner clears after recovery.
