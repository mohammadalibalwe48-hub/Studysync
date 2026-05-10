#!/usr/bin/env python3
"""Patch the Flutter-generated Android module to enable core library desugaring.

`flutter_local_notifications` (v17+) and several other plugins require Android
core library desugaring to be enabled on the host app. Without it, a release
build fails with:

    Dependency ':flutter_local_notifications' requires core library desugaring
    to be enabled for :app.

This script rewrites `android/app/build.gradle.kts` (or the older Groovy
`build.gradle`) in place to:

  1. Add `isCoreLibraryDesugaringEnabled = true` (or `coreLibraryDesugaringEnabled true`
     for Groovy) inside the existing `compileOptions { ... }` block.
  2. Append a top-level `dependencies { coreLibraryDesugaring("...") }` block
     at the end of the file pulling in `com.android.tools:desugar_jdk_libs`.

The script is idempotent: re-running it on an already-patched file is a no-op.
It refuses to patch if it cannot find the expected anchors, so the build
fails loudly rather than silently dropping the patch.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


# Pinned to the version the Flutter team currently recommends. Bump together
# with the project's compileSdk/minSdk if newer behavior is needed.
DESUGAR_LIBS_VERSION = "2.1.4"

KTS_DESUGAR_FLAG = "isCoreLibraryDesugaringEnabled = true"
KTS_DEPS_BLOCK = f"""
dependencies {{
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:{DESUGAR_LIBS_VERSION}")
}}
"""

GROOVY_DESUGAR_FLAG = "coreLibraryDesugaringEnabled true"
GROOVY_DEPS_BLOCK = f"""
dependencies {{
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:{DESUGAR_LIBS_VERSION}'
}}
"""


def patch_kotlin_dsl(text: str) -> str:
    if "isCoreLibraryDesugaringEnabled" in text and "coreLibraryDesugaring(" in text:
        return text  # already patched

    # 1. Add the flag inside compileOptions { ... }.
    if "isCoreLibraryDesugaringEnabled" not in text:
        anchor = "    compileOptions {\n"
        if anchor not in text:
            raise SystemExit(
                "patch_android_desugaring: could not find `compileOptions {` "
                "anchor in build.gradle.kts; aborting to avoid corrupting the file."
            )
        text = text.replace(
            anchor,
            f"{anchor}        {KTS_DESUGAR_FLAG}\n",
            1,
        )

    # 2. Append the dependencies block if not already present.
    if "coreLibraryDesugaring(" not in text:
        # Make sure we end with a newline before appending.
        if not text.endswith("\n"):
            text += "\n"
        text += KTS_DEPS_BLOCK

    return text


def patch_groovy(text: str) -> str:
    if "coreLibraryDesugaringEnabled" in text and "coreLibraryDesugaring " in text:
        return text  # already patched

    if "coreLibraryDesugaringEnabled" not in text:
        anchor = "    compileOptions {\n"
        if anchor not in text:
            raise SystemExit(
                "patch_android_desugaring: could not find `compileOptions {` "
                "anchor in build.gradle; aborting."
            )
        text = text.replace(
            anchor,
            f"{anchor}        {GROOVY_DESUGAR_FLAG}\n",
            1,
        )

    if "coreLibraryDesugaring " not in text:
        if not text.endswith("\n"):
            text += "\n"
        text += GROOVY_DEPS_BLOCK

    return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help=(
            "Path to the Flutter project root containing `android/app/`. "
            "Defaults to the parent of the directory holding this script. "
            "Pass an explicit path when invoking from a sub-app like "
            "`teachers_app/`."
        ),
    )
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
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
            "patch_android_desugaring: neither android/app/build.gradle.kts nor "
            "android/app/build.gradle exists. Run `flutter create` first."
        )

    if patched == original:
        print(f"patch_android_desugaring: {target.relative_to(repo_root)} already patched, skipping.")
        return 0

    target.write_text(patched)
    print(f"patch_android_desugaring: patched {target.relative_to(repo_root)} with core library desugaring.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
