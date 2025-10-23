-- Ejecuta este script en la consola SQL de tu proyecto Supabase.

create extension if not exists pgcrypto;

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  type text not null,
  severity text not null check (severity in ('BAJA','MEDIA','ALTA','CRITICA')),
  status text not null check (status in ('ABIERTO','CERRADO')) default 'ABIERTO',
  description text,
  photo_url text,
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  created_at timestamptz not null default now(),
  closed_at timestamptz
);

create index if not exists idx_reports_lat_lng on public.reports (lat, lng);
create index if not exists idx_reports_status on public.reports (status);
create index if not exists idx_reports_severity on public.reports (severity);
create index if not exists idx_reports_created_at on public.reports (created_at desc);

alter table public.reports enable row level security;

drop policy if exists "reports_select_public" on public.reports;
create policy "reports_select_public"
on public.reports for select
using (true);

drop policy if exists "reports_insert_owner" on public.reports;
create policy "reports_insert_owner"
on public.reports for insert
with check (auth.uid() = user_id);

drop policy if exists "reports_update_owner" on public.reports;
create policy "reports_update_owner"
on public.reports for update
using (auth.uid() = user_id);

drop policy if exists "reports_delete_owner" on public.reports;
create policy "reports_delete_owner"
on public.reports for delete
using (auth.uid() = user_id);
