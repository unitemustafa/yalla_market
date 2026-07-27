# Yalla Market iOS release handoff

The iOS project is prepared for bundle identifier `com.yallamarket.app`, iOS
15+, Firebase Messaging, foreground-only location access, profile-photo
library access, and APNs entitlements. The Podfile disables the unused
background-location permission for `geolocator_apple`.

On a Mac with Xcode and an Apple Developer account:

1. Verify the deployment-specific `GoogleService-Info.plist` exists at
   `ios/Runner/GoogleService-Info.plist`. The Runner target already references
   it, and it must belong to the Firebase iOS app `com.yallamarket.app`.
2. Put the protected MapTiler client key in `env/production.json` as
   `MAPTILER_API_KEY`. Set `GEOAPIFY_API_KEY` only in the deployed backend.
3. Run `plutil -lint ios/Runner/Info.plist`.
4. Run `flutter pub get`, then `cd ios && pod install --repo-update`.
5. Open `ios/Runner.xcworkspace` in Xcode.
6. Select the Apple team and confirm the bundle identifier.
7. Enable Push Notifications and Background Modes > Remote notifications.
   Do not enable background location.
8. Configure the APNs key in Firebase Console.
9. Build with
   `flutter build ipa --release --dart-define-from-file=env/production.json`.
10. Upload the archive to TestFlight and test sign-in persistence, both
    location-permission paths, disabled GPS, map search, pin selection,
    profile-photo selection, notifications, checkout, and order history on a
    real iPhone.

Never commit the Apple signing certificates, provisioning profiles, APNs key,
or production `GoogleService-Info.plist`.
