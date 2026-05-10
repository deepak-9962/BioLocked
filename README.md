# Bio-Locked Productivity Engine

A strict, non-AI productivity app that uses physical phone state, checkpoints, and habit mechanics to enforce deep work.

## Core Features

- Energy Check-In: choose session path based on your current energy.
- Physical Lock: lifting the device during a session triggers an alarm and penalty logic.
- Lock Levels:
  - Soft: longer grace, more flexibility.
  - Standard: balanced strictness.
  - Hard: shortest grace, no emergency breaks.
- Emergency Break with Penalty:
  - Daily limits based on lock level.
  - Cooldown after each use.
  - Session ends as failed and applies streak penalty.
- Recurring Focus Schedules:
  - Create weekday/time plans.
  - Local notifications remind you to start planned focus blocks.
- Weekly Analytics:
  - Focus time, success rate, failed sessions, pickup interruptions, best/toughest hour.
- Focus Presets:
  - Study Sprint, Deep Work, Workout Lock, Sleep Wind-down.
- Recovery and Micro-Wins modes for low-energy days.

## Setup

### Prerequisites

- Flutter SDK
- Android Studio / Xcode (for platform builds)
- Physical device for best sensor and camera behavior

### Optional Backend

Supabase is still initialized in app startup for session logging support.

1. Create a Supabase project.
2. Open `lib/main.dart`.
3. Replace placeholder values for URL and anon key.

If Supabase is not configured, the app still runs locally.

### Supabase progress sync (stats/history/level)

The app now syncs progress data to Supabase in addition to local secure storage.
On signed-in app launch, existing local stats/history/level data is backfilled to Supabase.

Create this table in your Supabase SQL editor:

```sql
create table if not exists public.user_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  stats_json jsonb,
  history_json jsonb,
  level_json jsonb,
  updated_at timestamptz default now()
);

alter table public.user_progress enable row level security;

create policy "Users can read own progress"
  on public.user_progress
  for select
  using (auth.uid() = user_id);

create policy "Users can upsert own progress"
  on public.user_progress
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

## Running

```bash
flutter pub get
flutter run
```

## Architecture

- State management: flutter_riverpod
- Local persistence: flutter_secure_storage
- Notifications: flutter_local_notifications
- Sensors: sensors_plus
- Audio and alarm: flutter_tts, audioplayers
- Camera checkpoints: camera
