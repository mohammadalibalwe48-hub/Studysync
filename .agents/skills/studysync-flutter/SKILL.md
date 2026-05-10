---
name: studysync-flutter
description: Reference for working in the Studysync Flutter app — verified build/test commands, Supabase env setup, design-system tokens, and visual-testing gotchas (Cairo font load, browser cache after rebuilds).
---

# Studysync Flutter — working notes

## Toolchain

- **Flutter 3.27.4** (`stable`). Newer Flutter breaks the repo (CardThemeData rename, `Color.withValues()` API). Don't bump unless you also fix the affected files.
- Flutter SDK lives at `$HOME/flutter`. Put `$HOME/flutter/bin` on `PATH`.
- The blueprint pins this version and runs `flutter precache --web` so web builds don't re-download artifacts on each session.

## Verified commands (run from repo root)

```
flutter pub get             # install deps
flutter analyze lib         # lint; only info-level deprecations expected (217 issues, all preexisting)
flutter build web --release # builds to build/web/, ~150s on first run
cd build/web && python3 -m http.server 8088   # serve the static build for visual testing
```

Do NOT use `flutter run -d web-server` for testing — it injects dev-mode noise and is slower. Always test against the production-mode `build/web` output.

## Supabase setup

The app reads two values via `flutter_dotenv` from a `.env` at the repo root:

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

Note: keys are `SUPABASE_URL` (not `SUPABASE_PROJECT_URL` despite what the env-var secrets are named). The `.env` file is bundled into `build/web/assets/.env` at build time because of:

```yaml
flutter:
  assets:
    - .env
```

In Devin sessions, the secrets `SUPABASE_PROJECT_URL` and `SUPABASE_ANON_KEY` exist as env vars — the `.env` at the repo root maps them to the names the app reads.

## Auth flow for testing

- Initial route: `/login`.
- Sign up at `/signup` with any fresh email + 6+ char password. Supabase does NOT require email confirmation on this project, so signup returns a session immediately and you land on `/home`.
- To get back to `/login` from an authenticated session: tap the **حساب** (account) tab in the floating bottom nav (leftmost in RTL layout), scroll to **تسجيل الخروج** at the bottom of the settings list, tap it.

## Design system tokens

Centralised in `lib/app/theme.dart`:

- `AppRadii`: `xs=10, sm=14, md=18, lg=22, xl=28, sheet=32, pill=999`
- `AppSpacing`: `xxs=4, xs=8, sm=12, md=16, lg=20, xl=24, xxl=32, screenH=20`
- `AppMotion`: `micro=160ms, short=220ms, medium=360ms, long=520ms`; curves `standard=easeOutCubic`, `emphasised=easeOutQuint`
- Colors / gradients on `AppPalette.of(context)`: `primary` (indigo), `accent` (sunset orange), `goldGradient`, `goldGlow`, `indigoGradient`, `indigoGlow`, `cardShadow`, etc.

Reusable widgets in `lib/core/widgets/`:

- `AppButton` — solid indigo CTA, the legacy default. Use for secondary actions.
- `OrangePillButton` — sunset-orange pill, the **hero CTA** style. Pass `expand: true, height: 52` for full-width auth-form usage.
- `DashedActionButton` — dashed-outline orange pill for empty-state "+ Create" actions.
- `EmptyState(card: true, ...)` — wraps the empty state in a white card with hairline + soft shadow.
- `GlassBottomNav` — floating white nav with rounded top corners (`AppRadii.xl`) and an indigo-tinted top shadow.

When in doubt, match the reference: hero CTAs are orange, brand surface CTAs are indigo, empty-state CTAs are dashed-orange.

## Visual-testing gotchas

1. **Browser cache after rebuild.** `flutter build web` produces new hashed asset bundles, but `python3 -m http.server` returns stale `main.dart.js` from the browser cache. After every rebuild, do a Ctrl+Shift+R hard-refresh — a normal navigation/reload may still serve the old bundle.
2. **Cairo font flash.** The Cairo font is loaded via `google_fonts` and downloads on first render. The first screenshot after a hard-refresh will show Arabic text as boxes for ~2-3 seconds. Always wait 3+ seconds after navigation before taking a screenshot.
3. **RTL layout.** The app is fully right-to-left. The home tab is on the right of the bottom nav, account on the left — this is correct, not flipped.
4. **No CI configured.** The repo has zero CI workflows. `git pr_checks` will return 0 passed / 0 failed — that's the repo's state, not a test failure.
5. **`flutter analyze lib` exits non-zero** because of preexisting `info`-level deprecation lints (217 issues, all `withOpacity → withValues`). Filter for `error`/`warning` lines only when checking your own changes.

## Layout for screenshots

The screen is 1024×768. The app uses responsive layout so wider viewports stretch cards horizontally — fine for desktop demos, but if you want screenshots that match the mobile-style master reference, prefer Chrome's responsive mode at ~414×896 (open DevTools → device toolbar). Otherwise capture the 1024×768 desktop layout and note it in your report.
