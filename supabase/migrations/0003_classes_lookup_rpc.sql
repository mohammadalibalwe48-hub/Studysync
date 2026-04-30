-- Hotfix: tighten RLS on `public.classes`.
--
-- Previous behavior (in 0001_teacher_app.sql):
--   policy "classes_lookup_by_code" used `using (true)` for SELECT, which
--   exposed every row of `public.classes` (including `join_code`) to every
--   authenticated user. Any signed-in account could enumerate join codes
--   and join any class, defeating the shared-secret model.
--
-- This migration:
--   1. Drops the over-broad SELECT policy. Teachers retain full access via
--      `classes_owner_all`. Students can no longer SELECT directly.
--   2. Adds a SECURITY DEFINER RPC `lookup_class_by_code(code text)` that
--      returns ONLY the (id, name) of the matching class. Because it is
--      SECURITY DEFINER it bypasses RLS and runs with the function owner's
--      privileges; we lock it down by:
--         - Marking it STABLE.
--         - Granting EXECUTE only to authenticated.
--         - Always uppercasing the input and using exact match — there is
--           no LIKE/wildcard, no listing, and the function returns at most
--           one row.
--   3. Sets a stable `search_path` on the function to prevent search-path
--      hijacking (Supabase linter best practice).
--
-- Run once in the Supabase SQL editor. Idempotent; safe to re-run.

drop policy if exists "classes_lookup_by_code" on public.classes;

create or replace function public.lookup_class_by_code(code text)
returns table (id uuid, name text)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select c.id, c.name
  from public.classes c
  where c.join_code = upper(coalesce(code, ''))
  limit 1;
$$;

revoke all on function public.lookup_class_by_code(text) from public;
grant execute on function public.lookup_class_by_code(text) to authenticated;
