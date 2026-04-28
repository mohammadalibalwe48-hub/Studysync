#!/usr/bin/env bash
# Generates the Android platform folder and applies project-specific patches.
#
# `flutter create` only adds `android.permission.INTERNET` to the
# debug/profile manifests, not the main one. Release APKs use the main
# manifest only, so without this patch a release build cannot make any
# network calls (Supabase, etc.) and fails with
# "Failed host lookup: ... errno = 7".
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
