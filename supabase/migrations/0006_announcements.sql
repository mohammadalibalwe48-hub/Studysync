-- Phase 3: per-class announcements that a teacher posts to their class
-- and students enrolled in that class can read.
--
-- Apply via the Supabase Management API:
--   curl -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
--     -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
--     -H "Content-Type: application/json" \
--     --data @/tmp/payload.json
-- The file is idempotent; re-running is safe.
--
-- Tables:
--   public.class_announcements — one row per posted announcement.
--   public.announcement_reads  — one row per (announcement, student)
--                                marking that the student has seen it.

-- ─────────────────────── class_announcements ───────────────────────

create table if not exists public.class_announcements (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  teacher_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists class_announcements_class_id_created_at_idx
  on public.class_announcements(class_id, created_at desc);
create index if not exists class_announcements_teacher_id_idx
  on public.class_announcements(teacher_id);

alter table public.class_announcements enable row level security;

-- Teacher full control over their own announcements.
drop policy if exists "class_announcements_teacher_all"
  on public.class_announcements;
create policy "class_announcements_teacher_all"
  on public.class_announcements
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

-- Students enrolled in the class can read its announcements.
-- (Mirrors `assignments_student_read` from migration 0002.)
drop policy if exists "class_announcements_student_read"
  on public.class_announcements;
create policy "class_announcements_student_read"
  on public.class_announcements
  for select to authenticated
  using (
    class_id in (
      select class_id from public.class_members
      where student_id = auth.uid()
    )
  );

-- ─────────────────────── announcement_reads ───────────────────────

create table if not exists public.announcement_reads (
  announcement_id uuid not null
    references public.class_announcements(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (announcement_id, student_id)
);

create index if not exists announcement_reads_student_id_idx
  on public.announcement_reads(student_id);

alter table public.announcement_reads enable row level security;

-- Students can manage their own read markers (insert/select/delete).
drop policy if exists "announcement_reads_student_self"
  on public.announcement_reads;
create policy "announcement_reads_student_self"
  on public.announcement_reads
  for all to authenticated
  using (student_id = auth.uid())
  with check (student_id = auth.uid());

-- Teacher SELECT on read markers for their own announcements (used to
-- compute "seen by N/M students" + drill-down list).
drop policy if exists "announcement_reads_teacher_read"
  on public.announcement_reads;
create policy "announcement_reads_teacher_read"
  on public.announcement_reads
  for select to authenticated
  using (
    announcement_id in (
      select id from public.class_announcements
      where teacher_id = auth.uid()
    )
  );
