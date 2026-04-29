#!/usr/bin/env bash
# Generates the Android platform folder and applies project-specific patches.
#
# Patches applied on top of `flutter create`:
#
#   1. INTERNET permission. `flutter create` only adds
#      `android.permission.INTERNET` to the debug/profile manifests, not the
#      main one. Release APKs use the main manifest only, so without this
#      patch a release build cannot make any network calls (Supabase, etc.)
#      and fails with "Failed host lookup: ... errno = 7".
#
#   2. Release signing config. The generated build.gradle re-uses the debug
#      signing config for release, which means release APKs are signed with
#      the well-known shared debug key — unpublishable to any app store.
#      `tool/patch_android_signing.py` rewrites the file to load
#      `android/key.properties` (gitignored) and use a real release keystore.
#      See README.md for how to create the keystore and `key.properties`.
#
#   3. App display name. `flutter create` sets `android:label` to the
#      project name (`studysync_syria`), which is the internal package name
#      and not user-facing. Replace it with the public app name so the
#      home-screen icon caption is correct.
#
#   4. Launcher icon. `flutter_launcher_icons` generates the mipmap PNGs
#      from `assets/icon/app_icon.png` so the home-screen icon matches the
#      brand instead of the default Flutter icon.
set -euo pipefail

APP_LABEL="Educational Steps Platform"

cd "$(dirname "$0")/.."

flutter create \
  --platforms=android \
  --project-name studysync_syria \
  --org com.studysync \
  .

manifest="android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.INTERNET' "$manifest"; then
  # Insert the <uses-permission> as the first child of <manifest>.
  sed -i 's|<manifest \(.*\)>|<manifest \1>\n    <uses-permission android:name="android.permission.INTERNET"/>|' "$manifest"
  echo "Added INTERNET permission to $manifest"
fi

# Replace the default `android:label="studysync_syria"` with the public app
# name. Using `|` as the sed delimiter so spaces in $APP_LABEL are fine.
if grep -q 'android:label="studysync_syria"' "$manifest"; then
  sed -i "s|android:label=\"studysync_syria\"|android:label=\"${APP_LABEL}\"|" "$manifest"
  echo "Set android:label=\"${APP_LABEL}\" in $manifest"
fi

python3 tool/patch_android_signing.py

# Generate launcher icons from assets/icon/app_icon.png. Requires
# `flutter_launcher_icons` to be in dev_dependencies (see pubspec.yaml).
flutter pub get
dart run flutter_launcher_icons
