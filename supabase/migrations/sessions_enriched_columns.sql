-- Optional columns for SessionLogger.logSessionEnd enrichment.
-- Apply only if your `sessions` table already exists with matching structure.
-- Primary key `id` must be UUID and match the client-generated session id from the app.

alter table public.sessions
  add column if not exists elapsed_minutes integer,
  add column if not exists planned_duration_snapshot integer,
  add column if not exists interruptions integer,
  add column if not exists emergency_breaks integer,
  add column if not exists lock_level text,
  add column if not exists energy_level_end integer,
  add column if not exists task_name_final text;

comment on column public.sessions.elapsed_minutes is 'Actual focused minutes when session ended';
comment on column public.sessions.planned_duration_snapshot is 'Planned tunnel length (minutes) at end';
