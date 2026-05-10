-- Phase 4: real-time per-class chat + live quiz sessions.
--
-- Adds three tables that power the in-class chat, the
-- "teacher is online" presence indicator, and the teacher-pushed
-- in-class live quizzes.
--
-- All three are wired into the `supabase_realtime` publication so
-- the apps can subscribe with `onPostgresChanges`.
--
-- Apply via the Supabase Management API:
--   curl -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
--     -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
--     -H "Content-Type: application/json" \
--     --data @/tmp/payload.json
--
-- The file is idempotent; re-running is safe.
--
-- Tables:
--   public.class_messages       — one row per chat message (teacher or
--                                 student), bidirectional.
--   public.live_quiz_sessions   — one row per teacher-pushed live quiz
--                                 prompt (a single question with up to
--                                 6 options + a marked correct index).
--   public.live_quiz_responses  — one row per (session, student)
--                                 answer, used to compute live tallies.
--
-- "Teacher is online" presence is handled via Supabase Realtime
-- *Presence* (channel-based, ephemeral), not a table — see the Flutter
-- side for the channel `class:<id>:presence` implementation.

-- ───────────────────────── helpers ─────────────────────────

create or replace function public._is_teacher_of_class(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.classes c
    where c.id = p_class_id and c.teacher_id = auth.uid()
  );
$$;

create or replace function public._is_member_of_class(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.class_members m
    where m.class_id = p_class_id and m.student_id = auth.uid()
  );
$$;

-- ───────────────────────── class_messages ─────────────────────────

create table if not exists public.class_messages (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  sender_role text not null check (sender_role in ('student', 'teacher')),
  body text not null check (length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index if not exists class_messages_class_id_created_at_idx
  on public.class_messages(class_id, created_at desc);
create index if not exists class_messages_sender_id_idx
  on public.class_messages(sender_id);

alter table public.class_messages enable row level security;
-- Realtime needs full row payloads on UPDATE/DELETE; default is fine
-- for INSERT-only flows but we still set REPLICA IDENTITY FULL so
-- moderation/edits in the future just work.
alter table public.class_messages replica identity full;

-- A teacher who owns the class can SELECT/INSERT/DELETE their messages.
drop policy if exists "class_messages_teacher_rw" on public.class_messages;
create policy "class_messages_teacher_rw"
  on public.class_messages
  for all to authenticated
  using (public._is_teacher_of_class(class_id))
  with check (
    public._is_teacher_of_class(class_id)
    and sender_id = auth.uid()
    and sender_role = 'teacher'
  );

-- A student in the class can SELECT all messages.
drop policy if exists "class_messages_student_read"
  on public.class_messages;
create policy "class_messages_student_read"
  on public.class_messages
  for select to authenticated
  using (public._is_member_of_class(class_id));

-- A student in the class can INSERT their own messages.
drop policy if exists "class_messages_student_send"
  on public.class_messages;
create policy "class_messages_student_send"
  on public.class_messages
  for insert to authenticated
  with check (
    public._is_member_of_class(class_id)
    and sender_id = auth.uid()
    and sender_role = 'student'
  );

-- A student can DELETE only their own message (so they can retract a
-- typo). They cannot delete the teacher's or other students' messages.
drop policy if exists "class_messages_student_delete_own"
  on public.class_messages;
create policy "class_messages_student_delete_own"
  on public.class_messages
  for delete to authenticated
  using (sender_id = auth.uid() and sender_role = 'student');

-- ─────────────────────── live_quiz_sessions ───────────────────────

create table if not exists public.live_quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  teacher_id uuid not null references auth.users(id) on delete cascade,
  prompt text not null check (length(prompt) between 1 and 500),
  options jsonb not null,
  correct_index integer not null check (correct_index between 0 and 5),
  status text not null
    check (status in ('open', 'closed'))
    default 'open',
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create index if not exists live_quiz_sessions_class_started_idx
  on public.live_quiz_sessions(class_id, started_at desc);
create index if not exists live_quiz_sessions_open_idx
  on public.live_quiz_sessions(class_id) where status = 'open';

alter table public.live_quiz_sessions enable row level security;
alter table public.live_quiz_sessions replica identity full;

-- Validate the options array shape: must be an array of 2..6 strings.
create or replace function public._validate_quiz_options()
returns trigger
language plpgsql
as $$
begin
  if jsonb_typeof(new.options) <> 'array' then
    raise exception 'options must be a JSON array of strings';
  end if;
  if jsonb_array_length(new.options) < 2
     or jsonb_array_length(new.options) > 6 then
    raise exception 'options must contain between 2 and 6 entries';
  end if;
  if new.correct_index >= jsonb_array_length(new.options) then
    raise exception 'correct_index out of range';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_quiz_options
  on public.live_quiz_sessions;
create trigger trg_validate_quiz_options
  before insert or update on public.live_quiz_sessions
  for each row execute function public._validate_quiz_options();

-- Teacher full control over their own sessions.
drop policy if exists "live_quiz_sessions_teacher_all"
  on public.live_quiz_sessions;
create policy "live_quiz_sessions_teacher_all"
  on public.live_quiz_sessions
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (
    teacher_id = auth.uid()
    and public._is_teacher_of_class(class_id)
  );

-- Students enrolled in the class can see sessions for that class.
drop policy if exists "live_quiz_sessions_student_read"
  on public.live_quiz_sessions;
create policy "live_quiz_sessions_student_read"
  on public.live_quiz_sessions
  for select to authenticated
  using (public._is_member_of_class(class_id));

-- ─────────────────────── live_quiz_responses ───────────────────────

create table if not exists public.live_quiz_responses (
  session_id uuid not null
    references public.live_quiz_sessions(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  choice_index integer not null check (choice_index between 0 and 5),
  is_correct boolean not null,
  answered_at timestamptz not null default now(),
  primary key (session_id, student_id)
);

create index if not exists live_quiz_responses_session_idx
  on public.live_quiz_responses(session_id);

alter table public.live_quiz_responses enable row level security;
alter table public.live_quiz_responses replica identity full;

-- Trigger: stamp is_correct based on the parent session's correct_index
-- and reject choices outside the option range. This way the client does
-- not have to be trusted to compute correctness.
create or replace function public._stamp_quiz_response_correctness()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_correct integer;
  v_options jsonb;
  v_status text;
begin
  select correct_index, options, status
    into v_correct, v_options, v_status
  from public.live_quiz_sessions where id = new.session_id;

  if v_correct is null then
    raise exception 'live quiz session not found';
  end if;
  if v_status <> 'open' then
    raise exception 'live quiz session is closed';
  end if;
  if new.choice_index >= jsonb_array_length(v_options) then
    raise exception 'choice_index out of range';
  end if;

  new.is_correct := (new.choice_index = v_correct);
  return new;
end;
$$;

drop trigger if exists trg_stamp_quiz_response_correctness
  on public.live_quiz_responses;
create trigger trg_stamp_quiz_response_correctness
  before insert on public.live_quiz_responses
  for each row execute function public._stamp_quiz_response_correctness();

-- A student can INSERT their own response.
drop policy if exists "live_quiz_responses_student_insert"
  on public.live_quiz_responses;
create policy "live_quiz_responses_student_insert"
  on public.live_quiz_responses
  for insert to authenticated
  with check (
    student_id = auth.uid()
    and exists (
      select 1 from public.live_quiz_sessions s
      where s.id = session_id
        and public._is_member_of_class(s.class_id)
    )
  );

-- A student can SELECT their own response (so the UI can render it).
drop policy if exists "live_quiz_responses_student_read_own"
  on public.live_quiz_responses;
create policy "live_quiz_responses_student_read_own"
  on public.live_quiz_responses
  for select to authenticated
  using (student_id = auth.uid());

-- The session's owning teacher can SELECT all responses (for the live
-- tally view).
drop policy if exists "live_quiz_responses_teacher_read"
  on public.live_quiz_responses;
create policy "live_quiz_responses_teacher_read"
  on public.live_quiz_responses
  for select to authenticated
  using (
    session_id in (
      select id from public.live_quiz_sessions
      where teacher_id = auth.uid()
    )
  );

-- ─────────────────────── realtime publication ───────────────────────

-- Add the new tables to the `supabase_realtime` publication so the
-- Flutter clients can subscribe via `onPostgresChanges`. Wrapped in a
-- DO block so re-running the migration after the publication already
-- contains the table is a no-op.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'class_messages'
  ) then
    execute 'alter publication supabase_realtime add table public.class_messages';
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'live_quiz_sessions'
  ) then
    execute 'alter publication supabase_realtime add table public.live_quiz_sessions';
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'live_quiz_responses'
  ) then
    execute 'alter publication supabase_realtime add table public.live_quiz_responses';
  end if;
end $$;
