-- ============================================================
-- Enam Trims Ltd — Production Planning System
-- Supabase schema (run once in SQL Editor)
-- ============================================================

-- 1. JOBS TABLE ------------------------------------------------
-- Mirrors the ERP "Job Register" export columns, plus a few
-- planning-only fields that are entered manually inside the app.

create table if not exists jobs (
  id                      bigint generated always as identity primary key,
  job_no                  text unique not null,
  job_type                text default 'JOB',        -- 'JOB' or 'SAMPLE' (auto-detected from job_no prefix)
  job_date                date,
  received_date           date,
  order_no                text,
  order_date              date,
  style_no                text,
  po_no                   text,
  customer                text,
  brand_name              text,
  brand_owner             text,
  product_description     text,
  department              text,
  machine                 text,
  product_type            text,
  production_type         text,                      -- INHOUSE / OUTSOURCE
  lc_no                   text,
  job_status              text,
  production_complete_date date,
  job_complete_date       date,
  edd                     date,
  edd_status              text,
  job_qty                 numeric default 0,
  job_value               numeric default 0,
  raw_status              text,
  entry_user              text,
  view_job_status         text,
  job_card_view           text,
  hold_status             text,                      -- 'Hold' / 'No' / 'Y' / 'N' as it comes from ERP
  hold_date               date,
  hold_reason             text,
  unhold_date             date,
  production_status       text,
  delivered_qty           numeric default 0,
  delivery_status         text,
  booking_no              text,
  order_hold              text,
  raw_name                text,
  raw_unit                text,
  remarks                 text,
  required_qty            numeric default 0,          -- material required but not yet available

  -- Planning-only fields (manual entry, Planning role or Admin)
  committed_edd           date,
  planned_machine         text,
  planned_date            date,
  planning_notes          text,

  -- bookkeeping
  created_at              timestamptz default now(),
  updated_at              timestamptz default now(),
  updated_by              text
);

create index if not exists idx_jobs_job_no on jobs (job_no);
create index if not exists idx_jobs_department on jobs (department);
create index if not exists idx_jobs_hold_status on jobs (hold_status);
create index if not exists idx_jobs_edd on jobs (edd);

-- keep updated_at fresh on every write
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_jobs_updated_at on jobs;
create trigger trg_jobs_updated_at
  before update on jobs
  for each row execute function set_updated_at();


-- 2. USER PROFILES / ROLES --------------------------------------
-- role: 'admin' | 'planning' | 'viewer'
-- New signups default to 'viewer'. Promote the first admin manually
-- (see README "First-time setup").

create table if not exists profiles (
  id          uuid references auth.users on delete cascade primary key,
  email       text,
  full_name   text,
  role        text not null default 'viewer' check (role in ('admin','planning','viewer')),
  -- per-page view/edit overrides, e.g. {"hold":{"view":true,"edit":false}}
  -- set by an Admin from Manage Users. Missing keys fall back to role defaults.
  permissions jsonb not null default '{}'::jsonb,
  created_at  timestamptz default now()
);

-- if this table already existed before "permissions" was added, this adds it safely
alter table profiles add column if not exists permissions jsonb not null default '{}'::jsonb;

-- auto-create a profile row whenever someone signs up
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'viewer');
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();


-- 3. IMPORT LOG (optional but useful for auditing bulk pastes) ---
create table if not exists import_log (
  id            bigint generated always as identity primary key,
  imported_by   text,
  row_count     int,
  created_at    timestamptz default now()
);


-- 4. ROW LEVEL SECURITY -------------------------------------------
alter table jobs enable row level security;
alter table profiles enable row level security;
alter table import_log enable row level security;

-- Everyone signed in can read jobs
drop policy if exists "jobs_select_authenticated" on jobs;
create policy "jobs_select_authenticated" on jobs
  for select using (auth.role() = 'authenticated');

-- Only admin/planning can insert or update jobs
drop policy if exists "jobs_write_admin_planning" on jobs;
create policy "jobs_write_admin_planning" on jobs
  for insert with check (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('admin','planning'))
  );

drop policy if exists "jobs_update_admin_planning" on jobs;
create policy "jobs_update_admin_planning" on jobs
  for update using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('admin','planning'))
  );

-- Only admin can delete jobs
drop policy if exists "jobs_delete_admin" on jobs;
create policy "jobs_delete_admin" on jobs
  for delete using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- Profiles: everyone can read all profiles (needed to show names/roles);
-- only admin can change someone's role.
drop policy if exists "profiles_select_authenticated" on profiles;
create policy "profiles_select_authenticated" on profiles
  for select using (auth.role() = 'authenticated');

drop policy if exists "profiles_update_admin" on profiles;
create policy "profiles_update_admin" on profiles
  for update using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- Import log: admin/planning can write, everyone can read
drop policy if exists "import_log_select" on import_log;
create policy "import_log_select" on import_log
  for select using (auth.role() = 'authenticated');

drop policy if exists "import_log_insert" on import_log;
create policy "import_log_insert" on import_log
  for insert with check (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('admin','planning'))
  );

-- ============================================================
-- Done. Next step: create your first user via Supabase
-- Authentication tab, then in SQL editor run:
--   update profiles set role = 'admin' where email = 'you@company.com';
-- ============================================================
