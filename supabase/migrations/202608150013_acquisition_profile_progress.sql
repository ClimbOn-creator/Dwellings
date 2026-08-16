alter table public.profiles
  add column if not exists acquisition_foundation jsonb not null default '{}'::jsonb;

alter table public.profiles
  add column if not exists acquisition_completed_modules text[] not null default '{}'::text[];

comment on column public.profiles.acquisition_foundation is
  'Account-backed Blueprint, Readiness, and Deal Screen draft for the four-step acquisition path.';

comment on column public.profiles.acquisition_completed_modules is
  'Acquisition path modules explicitly saved by the user.';
