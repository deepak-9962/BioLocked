-- Bio-Locked shared account schema.
-- Run this in the Supabase SQL editor before using the web dashboard.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  task_name text not null default '',
  planned_duration integer not null default 0,
  duration_minutes integer not null default 0,
  energy_level integer not null default 50,
  status text not null default 'in_progress' check (status in ('in_progress', 'completed', 'failed')),
  failure_reason text,
  interruptions integer not null default 0,
  emergency_breaks integer not null default 0,
  lock_level text not null default 'standard' check (lock_level in ('soft', 'standard', 'hard')),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.focus_presets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  task_name text not null default '',
  duration_minutes integer not null default 45,
  destruction_mode boolean not null default false,
  lock_level text not null default 'standard',
  icon text not null default '⚡',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.micro_wins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  category text not null,
  logged_at timestamptz not null default now()
);

create table if not exists public.user_stats (
  user_id uuid primary key references auth.users(id) on delete cascade,
  total_sessions integer not null default 0,
  total_minutes integer not null default 0,
  current_streak integer not null default 0,
  longest_streak integer not null default 0,
  perfect_sessions integer not null default 0,
  last_session_date timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.coins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance integer not null default 0,
  total_earned integer not null default 0,
  total_spent integer not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.notification_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.focus_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  hour integer not null,
  minute integer not null,
  duration_minutes integer not null,
  days integer[] not null default array[1, 2, 3, 4, 5],
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.sessions enable row level security;
alter table public.focus_presets enable row level security;
alter table public.micro_wins enable row level security;
alter table public.user_stats enable row level security;
alter table public.coins enable row level security;
alter table public.app_settings enable row level security;
alter table public.notification_settings enable row level security;
alter table public.focus_schedules enable row level security;

create policy "profiles are owned by user" on public.profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "sessions are owned by user" on public.sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "focus presets are owned by user" on public.focus_presets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "micro wins are owned by user" on public.micro_wins
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "stats are owned by user" on public.user_stats
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "coins are owned by user" on public.coins
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "app settings are owned by user" on public.app_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "notification settings are owned by user" on public.notification_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "focus schedules are owned by user" on public.focus_schedules
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
