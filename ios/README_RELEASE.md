# Yalla Market iOS release handoff

The iOS project is prepared for bundle identifier `com.yallamarket.app`, iOS
15+, Firebase Messaging, profile-photo library access, and APNs entitlements.

On a Mac with Xcode and an Apple Developer account:

1. Verify the deployment-specific `GoogleService-Info.plist` exists at
   `ios/Runner/GoogleService-Info.plist`. The Runner target already references
   it, and it must belong to the Firebase iOS app `com.yallamarket.app`.
2. Run `flutter pub get`, then `cd ios && pod install`.
3. Open `ios/Runner.xcworkspace` in Xcode.
4. Select the Apple team and confirm the bundle identifier.
5. Enable Push Notifications and Background Modes > Remote notifications.
6. Configure the APNs key in Firebase Console.
7. Build with `flutter build ipa --release --dart-define-from-file=env/production.json`.
8. Test sign-in persistence, location permission, profile photo selection,
   notifications, checkout, and order history on a real iPhone through TestFlight.

Never commit the Apple signing certificates, provisioning profiles, APNs key,
or production `GoogleService-Info.plist`.
