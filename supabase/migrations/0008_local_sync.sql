-- Local-only data → Supabase sync.
--
-- Until now three pieces of student data lived only on the device
-- (`SharedPreferences`):
--
--   • Bookmarked practice questions  (BookmarksService)
--   • Markdown study notes per topic (NotesService)
--   • Daily study-goal preference    (StudyGoalService)
--
-- This file moves them to Supabase so they sync across devices the same
-- way `student_progress` and `study_sessions` already do. The Flutter
-- services keep a local cache for offline use, but the source of truth
-- is now the database.
--
-- It also adds a SECURITY DEFINER RPC `leaderboard_top` so the
-- leaderboard screen (which previously rendered hard-coded mock rows)
-- can query an aggregate top-N over the last 7 days while RLS still
-- prevents students from reading anyone else's raw `study_sessions`.
--
-- Idempotent: rerunning is safe.

-- ─────────────────── bookmarked_questions ───────────────────

create table if not exists public.bookmarked_questions (
  user_id     uuid not null references auth.users(id) on delete cascade,
  question_id text not null,
  created_at  timestamptz not null default now(),
  primary key (user_id, question_id)
);

create index if not exists bookmarked_questions_user_idx
  on public.bookmarked_questions(user_id, created_at desc);

alter table public.bookmarked_questions enable row level security;

drop policy if exists "bookmarked_questions_self_select"
  on public.bookmarked_questions;
create policy "bookmarked_questions_self_select"
  on public.bookmarked_questions
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "bookmarked_questions_self_insert"
  on public.bookmarked_questions;
create policy "bookmarked_questions_self_insert"
  on public.bookmarked_questions
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "bookmarked_questions_self_delete"
  on public.bookmarked_questions;
create policy "bookmarked_questions_self_delete"
  on public.bookmarked_questions
  for delete to authenticated
  using (user_id = auth.uid());

-- ─────────────────── study_notes ───────────────────

create table if not exists public.study_notes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  topic_id    text not null,
  title       text not null default '',
  body        text not null default '',
  updated_at  timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

create index if not exists study_notes_user_topic_idx
  on public.study_notes(user_id, topic_id, updated_at desc);

alter table public.study_notes enable row level security;

drop policy if exists "study_notes_self_select" on public.study_notes;
create policy "study_notes_self_select" on public.study_notes
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "study_notes_self_insert" on public.study_notes;
create policy "study_notes_self_insert" on public.study_notes
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "study_notes_self_update" on public.study_notes;
create policy "study_notes_self_update" on public.study_notes
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "study_notes_self_delete" on public.study_notes;
create policy "study_notes_self_delete" on public.study_notes
  for delete to authenticated
  using (user_id = auth.uid());

-- ─────────────────── student_preferences ───────────────────

create table if not exists public.student_preferences (
  user_id              uuid primary key
                       references auth.users(id) on delete cascade,
  daily_goal_minutes   int not null default 60
                       check (daily_goal_minutes between 15 and 480),
  theme_mode           text not null default 'system'
                       check (theme_mode in ('system', 'light', 'dark')),
  notification_prefs   jsonb not null default '{}'::jsonb,
  updated_at           timestamptz not null default now()
);

alter table public.student_preferences enable row level security;

drop policy if exists "student_preferences_self_select"
  on public.student_preferences;
create policy "student_preferences_self_select"
  on public.student_preferences
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "student_preferences_self_upsert"
  on public.student_preferences;
create policy "student_preferences_self_upsert"
  on public.student_preferences
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "student_preferences_self_update"
  on public.student_preferences;
create policy "student_preferences_self_update"
  on public.student_preferences
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ─────────────────── leaderboard RPC ───────────────────
--
-- Sums the last 7 days of study_sessions per user and returns the top N
-- rows. Runs as the function owner so it bypasses RLS for the
-- aggregation step, but the result set never includes raw rows — only
-- the per-user totals + a non-PII display name.
--
-- Display name is `profiles.full_name` when set; otherwise we fall back
-- to a stable, anonymous "طالب####" tag derived from the user id, so
-- emails are never leaked.

create or replace function public.leaderboard_top(_limit int default 20)
returns table (
  user_id        uuid,
  display_name   text,
  study_minutes  int,
  is_self        boolean
)
language sql
security definer
set search_path = public
as $$
  with totals as (
    select
      ss.user_id,
      coalesce(sum(ss.duration_minutes), 0)::int as minutes
    from public.study_sessions ss
    where ss.created_at > now() - interval '7 days'
    group by ss.user_id
  )
  select
    t.user_id,
    case
      when coalesce(nullif(p.full_name, ''), null) is not null
        then p.full_name
      else 'طالب ' || substring(t.user_id::text, 1, 4)
    end as display_name,
    t.minutes as study_minutes,
    (t.user_id = auth.uid()) as is_self
  from totals t
  left join public.profiles p on p.user_id = t.user_id
  where t.minutes > 0
  order by t.minutes desc, t.user_id
  limit greatest(_limit, 1);
$$;

revoke all on function public.leaderboard_top(int) from public;
grant execute on function public.leaderboard_top(int) to authenticated;
