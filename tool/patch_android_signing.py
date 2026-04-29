#!/usr/bin/env python3
"""Patch the Flutter-generated Android module to use a release signing config.

`flutter create --platforms=android` generates an `android/app/build.gradle.kts`
(or older `.gradle` Groovy file) whose `release` build type re-uses the debug
signing config. That makes release APKs/AABs unpublishable to any app store
because they're signed with the well-known shared debug key.

This script rewrites the generated file in place to:

  1. Load `android/key.properties` (gitignored) into a `keystoreProperties`
     map at the top of the file.
  2. Add a `signingConfigs.release` (or `signingConfigs { release { ... } }`
     for Groovy) block that pulls credentials from `keystoreProperties`.
  3. Switch `buildTypes.release.signingConfig` from the debug config to the
     new release config.

If `android/key.properties` is missing at build time the release config falls
back to debug-style behavior (storeFile = null) so `flutter run` still works
for development; only `flutter build apk --release` / `flutter build appbundle`
require the real keystore.

The script is idempotent: re-running it on an already-patched file is a no-op.
It refuses to patch if it cannot find the expected anchors, so the build
fails loudly rather than silently producing a debug-signed release.
"""
from __future__ import annotations

import sys
from pathlib import Path


KTS_PROPERTIES_BLOCK = """import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

"""

KTS_SIGNING_BLOCK = """    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

"""

GROOVY_PROPERTIES_BLOCK = """def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

"""

GROOVY_SIGNING_BLOCK = """    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

"""


def patch_kotlin_dsl(text: str) -> str:
    if "keystoreProperties" in text:
        return text  # already patched

    # 1. Inject properties loading at the very top, before the first `plugins`
    #    or `android` block.
    anchor = "plugins {"
    if anchor not in text:
        anchor = "android {"
    if anchor not in text:
        raise SystemExit(
            "patch_android_signing: could not find `plugins {` or `android {` "
            "anchor in build.gradle.kts; aborting to avoid corrupting the file."
        )
    text = text.replace(anchor, KTS_PROPERTIES_BLOCK + anchor, 1)

    # 2. Inject signingConfigs block right before `buildTypes {`.
    bt_anchor = "    buildTypes {"
    if bt_anchor not in text:
        raise SystemExit(
            "patch_android_signing: could not find `buildTypes {` anchor in "
            "build.gradle.kts; aborting."
        )
    text = text.replace(bt_anchor, KTS_SIGNING_BLOCK + bt_anchor, 1)

    # 3. Switch the release build type to use the new signing config.
    debug_line = 'signingConfig = signingConfigs.getByName("debug")'
    release_line = 'signingConfig = signingConfigs.getByName("release")'
    if debug_line in text:
        text = text.replace(debug_line, release_line, 1)
    elif release_line not in text:
        raise SystemExit(
            "patch_android_signing: could not find the release signingConfig "
            "line to rewrite; aborting."
        )

    return text


def patch_groovy(text: str) -> str:
    if "keystoreProperties" in text:
        return text

    anchor = "android {"
    if anchor not in text:
        raise SystemExit(
            "patch_android_signing: could not find `android {` anchor in "
            "build.gradle; aborting."
        )
    text = text.replace(anchor, GROOVY_PROPERTIES_BLOCK + anchor, 1)

    bt_anchor = "    buildTypes {"
    if bt_anchor not in text:
        raise SystemExit(
            "patch_android_signing: could not find `buildTypes {` anchor in "
            "build.gradle; aborting."
        )
    text = text.replace(bt_anchor, GROOVY_SIGNING_BLOCK + bt_anchor, 1)

    # Modern Flutter (3.24+) generates `signingConfig = signingConfigs.debug`
    # in Groovy build.gradle. Older Flutter generates the call-style
    # `signingConfig signingConfigs.debug`. Handle both forms, and verify
    # the rewrite via an idempotent post-check.
    replacements = [
        ("signingConfig = signingConfigs.debug",
         "signingConfig = signingConfigs.release"),
        ("signingConfig signingConfigs.debug",
         "signingConfig signingConfigs.release"),
    ]
    for old, new in replacements:
        if old in text:
            text = text.replace(old, new, 1)
            break
    else:
        if ("signingConfig = signingConfigs.release" not in text
                and "signingConfig signingConfigs.release" not in text):
            raise SystemExit(
                "patch_android_signing: could not find the release "
                "signingConfig line to rewrite; aborting."
            )

    return text


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    kts = repo_root / "android" / "app" / "build.gradle.kts"
    groovy = repo_root / "android" / "app" / "build.gradle"

    if kts.exists():
        target = kts
        original = target.read_text()
        patched = patch_kotlin_dsl(original)
    elif groovy.exists():
        target = groovy
        original = target.read_text()
        patched = patch_groovy(original)
    else:
        raise SystemExit(
            "patch_android_signing: neither android/app/build.gradle.kts nor "
            "android/app/build.gradle exists. Run `flutter create` first."
        )

    if patched == original:
        print(f"patch_android_signing: {target.relative_to(repo_root)} already patched, skipping.")
        return 0

    target.write_text(patched)
    print(f"patch_android_signing: patched {target.relative_to(repo_root)} with release signing config.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
