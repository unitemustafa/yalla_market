# Yalla Market release checklist

## Automated gates

- Confirm the workflow for the release commit is green before distributing it.
- Increase both the app version and build number above the last distributed
  Android/iOS build.
- `flutter analyze`
- `flutter test`
- `flutter build appbundle --release --dart-define-from-file=env/production.local.json`
- Verify the APK/AAB signature and record SHA-256 hashes.

## Backend compatibility

- Deploy the matching backend release and run all pending migrations before
  distributing the mobile build.
- Confirm `GET /api/v1/locations/shipping-companies/` returns the active
  companies configured for the customer's service city.
- Confirm order preview returns `multi_market_fee_rate` and
  `multi_market_fee` for a cart containing two shops.

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
- Select a configured shipping company, create the order, and verify the saved
  company in order history.
- Preview a two-shop checkout and verify the second-shop fee appears in the
  summary, grand total, created order, and order history.
- Receive foreground, background, and opened push notifications.
- Disable the network and confirm the offline banner clears after recovery.
