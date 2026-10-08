# Facebook Login

Facebook replaces the Apple button on the login screen and uses the existing
social authentication use case, Firebase credential exchange, and backend flow.

## Native SDK configuration

Use the App ID and **Client Token** from the same Meta app. The Meta **App Secret**
belongs only in Firebase Authentication's Facebook provider settings. Never put
the App Secret in the app, runtime defines, or source control.

- Android: copy `android/facebook.properties.example` to
  `android/facebook.properties` and populate both values. Alternatively provide
  `FACEBOOK_APP_ID` and `FACEBOOK_CLIENT_TOKEN` as build environment variables.
- iOS: copy `ios/Flutter/Facebook.xcconfig.example` to
  `ios/Flutter/Facebook.xcconfig` and populate both values before building.

Both local configuration files are ignored by Git. Android checks the configuration
before compiling and generates SDK resources without printing their values.
Facebook automatic app events and advertising ID collection are disabled because
this integration is used for authentication.

## Meta and Firebase

1. Configure Facebook Login with `public_profile` and `email` only.
2. Add the Android platform with package `com.yallamarket.app` and class
   `com.yallamarket.app.MainActivity`. Register the key hash of every certificate
   used to sign installed builds, including Google Play's app signing certificate.
   The upload certificate alone is insufficient when Play App Signing is used.
3. Add the iOS platform with bundle identifier `com.yallamarket.app` before iOS
   testing; this cannot be validated on Windows.
4. Add the exact Firebase OAuth redirect URI to Meta's valid OAuth redirect URIs:
   `https://yalla-market-bf2f6.firebaseapp.com/__/auth/handler`.
5. Enable Facebook in the matching Firebase project's Authentication providers,
   using that Meta App ID and App Secret.

An unpublished Meta app is for accounts with an app role, not general customers.
Complete the requirements shown by Meta before publishing, including privacy and
data deletion information, business verification, and app review where required.
Verify a signed Android build on a real device before release, including cancel,
success, account linking, and a subsequent login. Keep Google sign-in available.

## Accounts without a Facebook email

Facebook may authenticate an account without providing an email. The matching
backend update returns profile completion with an empty email in that case.
The app asks for a valid address and uses the existing email OTP verification
flow before creating an account or issuing session tokens. A manually entered
address never inherits the provider's email verification status. If the address
belongs to an existing account, its password is required before linking.
Subsequent logins use the verified Firebase identity even if Facebook still
provides no email. Deploy the backend update alongside this app change.

The pre-login dialog asks only for email when it is missing. When the provider
already supplied an unverified email, the app sends the verification code
directly. Signup uses `defer_profile: true`; names, username, phone, and city are
completed inside the account, like Google sign-in. Apply backend migration
`accounts.0019_deferred_social_profile` before installing this app version.

References: [plugin setup](https://facebook.meedu.app/docs/intro/),
[Firebase integration](https://firebase.google.com/docs/auth/flutter/federated-auth).
