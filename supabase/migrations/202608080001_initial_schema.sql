create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.property_analyses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  address_label text not null,
  decision_mode text not null check (decision_mode in ('home', 'invest')),
  location_profile jsonb not null default '{}'::jsonb,
  property_inputs jsonb not null default '{}'::jsonb,
  model_output jsonb not null default '{}'::jsonb,
  model_version text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists property_analyses_user_created_idx
  on public.property_analyses(user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.property_analyses enable row level security;

create policy "Users can read own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "Users can create own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can read own analyses" on public.property_analyses for select using (auth.uid() = user_id);
create policy "Users can create own analyses" on public.property_analyses for insert with check (auth.uid() = user_id);
create policy "Users can update own analyses" on public.property_analyses for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own analyses" on public.property_analyses for delete using (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();
