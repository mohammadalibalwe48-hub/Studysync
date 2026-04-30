-- Phase 2a: custom assignments / quizzes that a teacher creates and
-- assigns to one of their classes, and that students in that class can
-- take and submit.
--
-- Run this once in the Supabase SQL editor (Dashboard → SQL → New query →
-- paste → Run). It is idempotent; re-running is safe.
--
-- Tables:
--   public.assignments           — quiz "container", owned by a teacher
--                                  and assigned to one of their classes.
--   public.assignment_questions  — MCQ questions inside an assignment.
--   public.assignment_submissions — one row per (assignment, student)
--                                  capturing the score and submission
--                                  timestamp. Per-question answers are
--                                  stored as JSONB in `answers`.

-- ─────────────────────── assignments ───────────────────────

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  teacher_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  subject_id text,
  due_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists assignments_class_id_idx
  on public.assignments(class_id);
create index if not exists assignments_teacher_id_idx
  on public.assignments(teacher_id);

alter table public.assignments enable row level security;

-- Teacher full control over their own assignments.
drop policy if exists "assignments_teacher_all" on public.assignments;
create policy "assignments_teacher_all" on public.assignments
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

-- Students enrolled in the class can read its assignments.
drop policy if exists "assignments_student_read" on public.assignments;
create policy "assignments_student_read" on public.assignments
  for select to authenticated
  using (
    class_id in (
      select class_id from public.class_members
      where student_id = auth.uid()
    )
  );

-- ─────────────────────── assignment_questions ───────────────────────

create table if not exists public.assignment_questions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null
    references public.assignments(id) on delete cascade,
  position integer not null default 0,
  prompt text not null,
  options jsonb not null,            -- array of strings
  correct_index integer not null,
  explanation text,
  created_at timestamptz not null default now()
);

create index if not exists assignment_questions_assignment_id_idx
  on public.assignment_questions(assignment_id);

alter table public.assignment_questions enable row level security;

-- Teacher full control over questions in their own assignments.
drop policy if exists "assignment_questions_teacher_all"
  on public.assignment_questions;
create policy "assignment_questions_teacher_all"
  on public.assignment_questions
  for all to authenticated
  using (
    assignment_id in (
      select id from public.assignments where teacher_id = auth.uid()
    )
  )
  with check (
    assignment_id in (
      select id from public.assignments where teacher_id = auth.uid()
    )
  );

-- Students in the class can read questions of assignments they have
-- access to.
drop policy if exists "assignment_questions_student_read"
  on public.assignment_questions;
create policy "assignment_questions_student_read"
  on public.assignment_questions
  for select to authenticated
  using (
    assignment_id in (
      select a.id
      from public.assignments a
      join public.class_members cm on cm.class_id = a.class_id
      where cm.student_id = auth.uid()
    )
  );

-- ─────────────────────── assignment_submissions ───────────────────────

create table if not exists public.assignment_submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null
    references public.assignments(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  score integer not null default 0,
  total integer not null default 0,
  answers jsonb not null default '[]'::jsonb,
  submitted_at timestamptz not null default now(),
  unique (assignment_id, student_id)
);

create index if not exists assignment_submissions_assignment_idx
  on public.assignment_submissions(assignment_id);
create index if not exists assignment_submissions_student_idx
  on public.assignment_submissions(student_id);

alter table public.assignment_submissions enable row level security;

-- Students manage their own submissions.
drop policy if exists "assignment_submissions_student_self"
  on public.assignment_submissions;
create policy "assignment_submissions_student_self"
  on public.assignment_submissions
  for all to authenticated
  using (student_id = auth.uid())
  with check (student_id = auth.uid());

-- Teachers can read submissions for their own assignments.
drop policy if exists "assignment_submissions_teacher_read"
  on public.assignment_submissions;
create policy "assignment_submissions_teacher_read"
  on public.assignment_submissions
  for select to authenticated
  using (
    assignment_id in (
      select id from public.assignments where teacher_id = auth.uid()
    )
  );
