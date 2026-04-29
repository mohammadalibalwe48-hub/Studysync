# Educational Steps Platform

(Internal package name: `studysync_syria` — the on-device app name is
"Educational Steps Platform". Internal class names and imports keep the
historical name for stability.)

A Flutter mobile study app for Syrian 12th grade students preparing for
university entrance exams.

This repo currently contains a **minimal auth shell** with a refreshed
design. Lessons, subjects, topics, questions, and progress tracking have
been removed for now and will be reintroduced in a future iteration.

## Features

- Login & signup screens (Supabase Auth)
- `AuthService` backed by Supabase, exposed as a `ChangeNotifier`
- Home screen with a welcome hero and "more features coming soon" placeholder
- Profile screen with sign-out
- Auth-aware `GoRouter` redirect

## Tech stack

- Flutter (Material 3, Android-first)
- Dart (strongly typed, no `dynamic`)
- [`go_router`](https://pub.dev/packages/go_router) for navigation
- [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) for auth
- `flutter_dotenv`, `shared_preferences`

## Project layout

```
lib/
  main.dart
  app/
    app.dart        # MaterialApp.router + theming
    router.dart     # GoRouter routes & auth-aware redirect
  features/
    auth/           # login, signup, AuthService
    home/           # home_screen (welcome + coming-soon placeholder)
    profile/        # profile_screen + sign out
  core/
    supabase/       # supabase_client.dart
    widgets/        # app_button.dart
```

## Routes

| Path        | Screen                |
| ----------- | --------------------- |
| `/login`    | Login                 |
| `/signup`   | Signup                |
| `/home`     | Home                  |
| `/profile`  | Profile / sign out    |

The router redirects unauthenticated users to `/login` and authenticated users
away from the auth screens, using `AuthService.instance` as the
`refreshListenable`.

## Running locally

```bash
flutter pub get
flutter analyze
flutter run
```

To produce a release APK:

```bash
flutter build apk --release
```

## Notes

- `AuthService` is backed by Supabase Auth. Its public surface
  (`login`, `signup`, `signOut`, `currentUserEmail`, `isAuthenticated`,
  `ChangeNotifier`) is consumed directly by the auth screens and the
  `GoRouter` `refreshListenable`.
- No platform folders (`android/`, `ios/`, …) are committed — generate them
  locally before running on a device. Use:

  ```bash
  bash tool/setup_android.sh
  ```

  This wraps `flutter create --platforms=android --project-name studysync_syria
  --org com.studysync .` and also adds
  `<uses-permission android:name="android.permission.INTERNET"/>` to
  `android/app/src/main/AndroidManifest.xml`. Without that permission a
  `flutter build apk --release` produces an APK that cannot make any
  network calls (Supabase requests fail with "Failed host lookup
  ... errno = 7"), because `flutter create` only adds INTERNET to the
  debug/profile manifests.

  The setup script also runs `tool/patch_android_signing.py`, which
  rewrites `android/app/build.gradle.kts` to use a release signing config
  loaded from `android/key.properties` instead of the debug keystore.

## Release signing (for publishing to Play Store / sideloading updates)

`flutter create` configures the `release` build to re-use the **debug**
keystore, which is a shared key bundled with the Android SDK. Release builds
signed that way are rejected by Play Store and can never be updated reliably.
This repo's `tool/setup_android.sh` patches the generated Gradle config to
sign with a real upload keystore loaded from `android/key.properties`
(gitignored).

To set this up the first time:

1. Generate the keystore once (any machine with a JDK):

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Back up the resulting `.jks` file and the passwords in two places (e.g.
   a password manager and a private cloud folder). **If you lose them you
   can never publish updates to your app on Play Store.**

2. Copy `tool/key.properties.example` to `android/key.properties` and fill
   in the real values:

   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

   `android/key.properties` and `*.jks` are gitignored — never commit them.

3. Build:

   ```bash
   flutter build appbundle --release   # for Play Store
   flutter build apk --release         # for direct sideload
   ```

   Output: `build/app/outputs/bundle/release/app-release.aab` and
   `build/app/outputs/flutter-apk/app-release.apk`.

If `android/key.properties` is missing the `release` build still completes
(with `storeFile = null`) so `flutter run` works for development; only
`flutter build apk --release` / `flutter build appbundle` actually need
the real keystore.
