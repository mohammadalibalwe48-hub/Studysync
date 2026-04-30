-- Teacher-app foundation: roles, classes, class membership.
--
-- Run this once in the Supabase SQL editor (Dashboard → SQL → New query →
-- paste → Run). It is idempotent; re-running is safe.
--
-- Tables:
--   public.profiles       — one row per auth user, with a 'student' or
--                           'teacher' role.
--   public.classes        — a teacher-owned class with a 6-char join code.
--   public.class_members  — links students to classes.
--
-- RLS:
--   - Teachers can read student_progress / question_attempts /
--     study_sessions ONLY for students who joined one of their classes.
--   - Students keep their existing read/write access to their own rows.

-- ─────────────────────── profiles ───────────────────────

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null check (role in ('student', 'teacher')) default 'student',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_self_select" on public.profiles;
create policy "profiles_self_select" on public.profiles
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "profiles_self_upsert" on public.profiles;
create policy "profiles_self_upsert" on public.profiles
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "profiles_self_update" on public.profiles;
create policy "profiles_self_update" on public.profiles
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ─────────────────────── classes ───────────────────────

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  join_code text unique not null,
  created_at timestamptz not null default now()
);

create index if not exists classes_teacher_id_idx on public.classes(teacher_id);

alter table public.classes enable row level security;

drop policy if exists "classes_teacher_all" on public.classes;
create policy "classes_teacher_all" on public.classes
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

-- Students may look up a class by its join code (read-only) so they can
-- preview the class name before joining. Membership creation is handled
-- through `class_members` with its own check.
drop policy if exists "classes_lookup_by_code" on public.classes;
create policy "classes_lookup_by_code" on public.classes
  for select to authenticated
  using (true);

-- ─────────────────────── class_members ───────────────────────

create table if not exists public.class_members (
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (class_id, student_id)
);

create index if not exists class_members_student_idx
  on public.class_members(student_id);

alter table public.class_members enable row level security;

-- A student can join a class for themselves.
drop policy if exists "class_members_self_join" on public.class_members;
create policy "class_members_self_join" on public.class_members
  for insert to authenticated
  with check (student_id = auth.uid());

-- A student can read / leave their own memberships.
drop policy if exists "class_members_self_read" on public.class_members;
create policy "class_members_self_read" on public.class_members
  for select to authenticated
  using (
    student_id = auth.uid()
    or class_id in (
      select id from public.classes where teacher_id = auth.uid()
    )
  );

drop policy if exists "class_members_self_delete" on public.class_members;
create policy "class_members_self_delete" on public.class_members
  for delete to authenticated
  using (
    student_id = auth.uid()
    or class_id in (
      select id from public.classes where teacher_id = auth.uid()
    )
  );

-- ─────────────────────── teacher access to student rows ───────────────────────

-- Teachers can read student_progress for students in their classes.
drop policy if exists "student_progress_teacher_read" on public.student_progress;
create policy "student_progress_teacher_read" on public.student_progress
  for select to authenticated
  using (
    user_id in (
      select cm.student_id
      from public.class_members cm
      join public.classes c on c.id = cm.class_id
      where c.teacher_id = auth.uid()
    )
  );

-- Teachers can read question_attempts for students in their classes.
drop policy if exists "question_attempts_teacher_read" on public.question_attempts;
create policy "question_attempts_teacher_read" on public.question_attempts
  for select to authenticated
  using (
    user_id in (
      select cm.student_id
      from public.class_members cm
      join public.classes c on c.id = cm.class_id
      where c.teacher_id = auth.uid()
    )
  );

-- Teachers can read study_sessions for students in their classes.
drop policy if exists "study_sessions_teacher_read" on public.study_sessions;
create policy "study_sessions_teacher_read" on public.study_sessions
  for select to authenticated
  using (
    user_id in (
      select cm.student_id
      from public.class_members cm
      join public.classes c on c.id = cm.class_id
      where c.teacher_id = auth.uid()
    )
  );

-- Teachers can read the profiles of students in their classes (for full
-- names in the roster).
drop policy if exists "profiles_teacher_read_class_students" on public.profiles;
create policy "profiles_teacher_read_class_students" on public.profiles
  for select to authenticated
  using (
    user_id in (
      select cm.student_id
      from public.class_members cm
      join public.classes c on c.id = cm.class_id
      where c.teacher_id = auth.uid()
    )
  );

-- ─────────────────────── helpers ───────────────────────

-- Auto-create a profiles row on signup. The role is set from the signup
-- metadata (`role: 'teacher' | 'student'`); defaults to 'student'.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  signup_role text;
begin
  signup_role := coalesce(new.raw_user_meta_data ->> 'role', 'student');
  if signup_role not in ('student', 'teacher') then
    signup_role := 'student';
  end if;
  insert into public.profiles (user_id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', null),
    signup_role
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
