#!/usr/bin/env bash
# Generates the Android platform folder and applies project-specific patches.
#
# Two patches are applied on top of `flutter create`:
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
set -euo pipefail

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

python3 tool/patch_android_signing.py
