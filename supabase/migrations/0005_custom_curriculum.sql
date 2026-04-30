-- Phase 2b: custom curriculum. Teacher-authored lessons + MCQs that
-- appear in the student app alongside the bundled content in
-- `lib/core/constants/curriculum.dart`. Bundled curriculum stays as a
-- fallback when offline / when no DB content exists for a topic.
--
-- Run this once in the Supabase SQL editor (Dashboard → SQL → New query →
-- paste → Run) or via the Management API. It is idempotent; re-running
-- is safe.
--
-- Tables:
--   public.custom_lessons           — one teacher-authored lesson tied
--                                     to a (subject_id, topic_id) pair.
--                                     `topic_id` is nullable so a
--                                     teacher can introduce a brand-new
--                                     topic that isn't in the bundled
--                                     curriculum.
--   public.custom_lesson_questions  — MCQ questions inside a custom
--                                     lesson, mirroring the shape of
--                                     `assignment_questions`.
--
-- v1 design choice (flagged in PR description so the user can flip if
-- desired): custom lessons are visible to ANY authenticated student,
-- not class-scoped. A teacher who publishes content publishes for the
-- entire student body, not just their roster. To scope to class
-- members, add a `class_id` column and mirror the
-- `assignments_student_read` policy from 0002.

-- ─────────────────────── custom_lessons ───────────────────────

create table if not exists public.custom_lessons (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  subject_id text not null,
  topic_id text,
  topic_title text,
  lesson_title text not null,
  body_markdown text not null default '',
  key_ideas jsonb not null default '[]'::jsonb,    -- array of strings
  worked_example_markdown text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists custom_lessons_subject_topic_idx
  on public.custom_lessons(subject_id, topic_id);
create index if not exists custom_lessons_teacher_id_idx
  on public.custom_lessons(teacher_id);

alter table public.custom_lessons enable row level security;

-- Teacher full control over their own lessons.
drop policy if exists "custom_lessons_teacher_all" on public.custom_lessons;
create policy "custom_lessons_teacher_all" on public.custom_lessons
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

-- Any authenticated user may read every lesson (v1 = public reads;
-- see file header for rationale).
drop policy if exists "custom_lessons_authenticated_read"
  on public.custom_lessons;
create policy "custom_lessons_authenticated_read"
  on public.custom_lessons
  for select to authenticated
  using (true);

-- ─────────────────────── custom_lesson_questions ───────────────────────

create table if not exists public.custom_lesson_questions (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null
    references public.custom_lessons(id) on delete cascade,
  position integer not null default 0,
  prompt text not null,
  options jsonb not null,            -- array of strings
  correct_index integer not null,
  explanation text,
  created_at timestamptz not null default now()
);

create index if not exists custom_lesson_questions_lesson_id_idx
  on public.custom_lesson_questions(lesson_id);

alter table public.custom_lesson_questions enable row level security;

-- Teacher full control over questions in their own lessons.
drop policy if exists "custom_lesson_questions_teacher_all"
  on public.custom_lesson_questions;
create policy "custom_lesson_questions_teacher_all"
  on public.custom_lesson_questions
  for all to authenticated
  using (
    lesson_id in (
      select id from public.custom_lessons where teacher_id = auth.uid()
    )
  )
  with check (
    lesson_id in (
      select id from public.custom_lessons where teacher_id = auth.uid()
    )
  );

-- Any authenticated user may read questions for any lesson (mirror the
-- read policy on the parent table so the student app can render the
-- question list under each lesson).
drop policy if exists "custom_lesson_questions_authenticated_read"
  on public.custom_lesson_questions;
create policy "custom_lesson_questions_authenticated_read"
  on public.custom_lesson_questions
  for select to authenticated
  using (true);

-- Bump `updated_at` automatically when a custom lesson row changes.
create or replace function public.custom_lessons_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end$$;

drop trigger if exists custom_lessons_set_updated_at_trg
  on public.custom_lessons;
create trigger custom_lessons_set_updated_at_trg
  before update on public.custom_lessons
  for each row execute function public.custom_lessons_set_updated_at();
