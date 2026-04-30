-- The repo previously had a `public.profiles` table with columns
-- (id uuid, email text, display_name text, created_at, updated_at).
--
-- The teacher-app feature in 0001_teacher_app.sql assumed the schema
-- (user_id uuid PK, full_name text, role text). When 0001 was applied
-- against an existing database, the `create table if not exists` was a
-- no-op and every later statement failed with `column "user_id" does not
-- exist`.
--
-- This migration brings the existing `profiles` table into the new
-- shape, idempotently. After it succeeds, 0001 / 0002 / 0003 can be
-- re-run safely on top.
--
-- Run once in the Supabase SQL editor (or via Management API). Safe to
-- re-run.

do $$
begin
  -- Rename `id` → `user_id` if needed.
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'id'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'user_id'
  ) then
    alter table public.profiles rename column id to user_id;
  end if;

  -- Add `full_name` if missing; backfill from `display_name` if present.
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'full_name'
  ) then
    alter table public.profiles add column full_name text;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'display_name'
  ) then
    update public.profiles
       set full_name = coalesce(full_name, display_name);
  end if;

  -- Add `role` column with default 'student' if missing.
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'role'
  ) then
    alter table public.profiles
      add column role text not null default 'student';
  end if;

  -- Ensure the role check constraint exists.
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'profiles'
      and constraint_name = 'profiles_role_check'
  ) then
    alter table public.profiles
      add constraint profiles_role_check
      check (role in ('student', 'teacher'));
  end if;

  -- Make sure `user_id` is the primary key.
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'profiles'
      and constraint_type = 'PRIMARY KEY'
  ) then
    alter table public.profiles
      add constraint profiles_pkey primary key (user_id);
  end if;

  -- Make sure user_id references auth.users(id) on delete cascade.
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'profiles'
      and constraint_name = 'profiles_user_id_fkey'
  ) then
    alter table public.profiles
      add constraint profiles_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end$$;
