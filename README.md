# StudySync Syria

A Flutter mobile study app for Syrian 12th grade students preparing for physics
and chemistry university entrance exams.

This repo currently contains the **frontend-only scaffold**. The Supabase
backend will be added later — for now, auth and data are local/static so the
UI flows can be developed and reviewed independently.

## Features (frontend scaffold)

- Login & signup screens with form validation
- Temporary in-memory auth (`AuthService`) ready to be swapped for Supabase
- Home screen with streak badge and Physics / Chemistry subject cards
- Topic list per subject with static curriculum data
- Topic detail screen with lesson content + practice questions and worked
  solutions
- Progress screen with placeholder stats and an `fl_chart` bar chart
- Profile screen with sign-out

## Tech stack

- Flutter (Material 3, Android-first)
- Dart (strongly typed, no `dynamic`)
- [`go_router`](https://pub.dev/packages/go_router) for navigation
- [`fl_chart`](https://pub.dev/packages/fl_chart) for the progress chart
- `flutter_dotenv`, `shared_preferences` (declared, not yet used)

## Project layout

```
lib/
  main.dart
  app/
    app.dart        # MaterialApp.router + theming
    router.dart     # GoRouter routes & auth-aware redirect
  features/
    auth/           # login, signup, AuthService
    home/           # home_screen
    subjects/       # topic_list_screen
    topics/         # topic_detail_screen, lesson_view
    progress/       # progress_screen (fl_chart placeholder)
    profile/        # profile_screen + sign out
  core/
    models/         # subject, topic, question, student_progress, study_session
    constants/      # curriculum.dart (static lessons + questions)
    widgets/        # app_button, subject_card, topic_card, question_card,
                    # progress_bar, streak_badge
```

## Routes

| Path                    | Screen                |
| ----------------------- | --------------------- |
| `/login`                | Login                 |
| `/signup`               | Signup                |
| `/home`                 | Home                  |
| `/subjects/:subjectId`  | Topic list (per subject) |
| `/topics/:topicId`      | Topic detail (lesson + questions) |
| `/progress`             | Progress dashboard    |
| `/profile`              | Profile / sign out    |

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

- `AuthService` is intentionally minimal and in-memory. Its public surface
  (`login`, `signup`, `signOut`, `currentUserEmail`, `isAuthenticated`,
  `ChangeNotifier`) mirrors what a Supabase-backed implementation will expose,
  so swapping it out later only changes one file.
- Curriculum data lives in `lib/core/constants/curriculum.dart`. Once Supabase
  is wired up, this file will be used as a fallback / seed.
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
