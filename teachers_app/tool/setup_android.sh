#!/usr/bin/env bash
# Generates the Android platform folder for the teachers companion app and
# applies the same project-specific patches as the student app's
# `tool/setup_android.sh`. See that file for the rationale behind each patch.
#
# Patches applied on top of `flutter create`:
#
#   1. INTERNET permission (release manifest).
#   2. Release signing config (`../tool/patch_android_signing.py`,
#      reused via `--repo-root`).
#   3. App display name (`android:label` set to the public name).
#
# The teachers app does NOT need the core library desugaring patch because
# its `pubspec.yaml` does not depend on `flutter_local_notifications` or any
# other plugin that requires desugaring. If you ever add such a dependency,
# also call `python3 ../tool/patch_android_desugaring.py --repo-root .` here.
set -euo pipefail

APP_LABEL="Educational Steps Teachers"

# Resolve paths up front so the script can be invoked from anywhere.
script_dir="$(cd "$(dirname "$0")" && pwd)"
teachers_root="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$teachers_root/.." && pwd)"

cd "$teachers_root"

flutter create \
  --platforms=android \
  --project-name studysync_syria_teachers \
  --org com.studysync \
  .

manifest="android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.INTERNET' "$manifest"; then
  sed -i 's|<manifest \(.*\)>|<manifest \1>\n    <uses-permission android:name="android.permission.INTERNET"/>|' "$manifest"
  echo "Added INTERNET permission to $manifest"
fi

if grep -q 'android:label="studysync_syria_teachers"' "$manifest"; then
  sed -i "s|android:label=\"studysync_syria_teachers\"|android:label=\"${APP_LABEL}\"|" "$manifest"
  echo "Set android:label=\"${APP_LABEL}\" in $manifest"
fi

# Reuse the shared signing patch from the repo root, scoped to the
# teachers_app/ directory via `--repo-root`.
python3 "$repo_root/tool/patch_android_signing.py" --repo-root "$teachers_root"

flutter pub get
