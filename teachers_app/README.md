# Teachers App — فيزياء وكيمياء بكالوريا سوريا

A companion Flutter app for **teachers** to manage classes and monitor student progress on the same Supabase project as the student app in this repo.

## What teachers can do (Phase 1)

- Sign up / sign in (email + password). New signups from this app are tagged with `role: 'teacher'`.
- Create a class with an auto-generated 6-character join code, share the code with students.
- View the roster of students who joined a class with per-student completion %, accuracy %, study minutes, and last-active.
- Drill into any student to see per-topic progress, recent question attempts, and study minutes.
- Sign out.

## Setup

### 1. Database

Open your Supabase dashboard → **SQL Editor** → **New query** → paste the contents of [`../supabase/migrations/0001_teacher_app.sql`](../supabase/migrations/0001_teacher_app.sql) → **Run**. The migration is idempotent.

It adds:
- `public.profiles` (one row per auth user, `role: 'student' | 'teacher'`)
- `public.classes` (teacher-owned classes with unique `join_code`)
- `public.class_members` (links students to classes)
- A `handle_new_user()` trigger that auto-creates a profile row from `raw_user_meta_data.role` on signup
- RLS policies that let teachers read `student_progress`, `question_attempts`, `study_sessions`, and `profiles` only for students in their own classes

### 2. Configure env

```bash
cd teachers_app
cp .env.example .env
# Fill SUPABASE_URL and SUPABASE_ANON_KEY with the same values used by the student app.
```

### 3. Install + run

```bash
cd teachers_app
flutter pub get
flutter create --platforms=android --project-name studysync_syria_teachers --org com.studysync .
flutter run
```

The first `flutter create` generates the Android platform folder. After that you can iterate normally with `flutter run`.

## Architecture notes

- **Same design system** as the student app: Cairo Google Font, gold/champagne palette via `AppTheme` + `AppPalette`, glass widgets (`AmbientBackground`, `AppButton`, `EmptyState`), RTL forced via `Directionality`.
- **No curriculum copy** — the teachers app only needs subject + topic IDs/titles for labels in rosters, so it ships with a small `topic_catalog.dart` instead of duplicating the full lesson content.
- **All RLS lives in the database**, not in client code. The app does not gate features by `role` because Supabase RLS already restricts what each user can read or write.
