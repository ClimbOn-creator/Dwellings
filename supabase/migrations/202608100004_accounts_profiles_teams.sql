create extension if not exists citext;

alter table public.membership_applications
  drop constraint if exists membership_applications_applicant_type_check;
alter table public.membership_applications
  add constraint membership_applications_applicant_type_check check (
    applicant_type in (
      'homebuyer', 'investor', 'realtor', 'mortgage_broker',
      'lawyer', 'accountant', 'lender'
    )
  );

alter table public.profiles add column if not exists username citext;
alter table public.profiles add column if not exists full_name text;
alter table public.profiles add column if not exists account_role text not null default 'user';
alter table public.profiles add column if not exists job_title text;
alter table public.profiles add column if not exists company_name text;
alter table public.profiles add column if not exists employment_type text;
alter table public.profiles add column if not exists profile_photo_url text;
alter table public.profiles add column if not exists bio text;

update public.profiles
set full_name = coalesce(nullif(trim(full_name), ''), nullif(trim(display_name), ''))
where full_name is null;

create unique index if not exists profiles_username_unique_idx
  on public.profiles (lower(username::text)) where username is not null;

alter table public.profiles drop constraint if exists profiles_account_role_check;
alter table public.profiles add constraint profiles_account_role_check check (
  account_role in ('user', 'realtor', 'mortgage_broker', 'lawyer', 'accountant', 'lender')
);
alter table public.profiles drop constraint if exists profiles_employment_type_check;
alter table public.profiles add constraint profiles_employment_type_check check (
  employment_type is null or employment_type in ('company', 'self_employed', 'own_practice')
);

create or replace function public.username_available(candidate text)
returns boolean language sql stable security definer set search_path = public as $$
  select candidate ~ '^[A-Za-z0-9_]{3,24}$'
    and not exists (
      select 1 from public.profiles where lower(username::text) = lower(candidate)
    );
$$;
grant execute on function public.username_available(text) to anon, authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (
    id, display_name, full_name, username, account_role, job_title,
    company_name, employment_type
  ) values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    nullif(new.raw_user_meta_data ->> 'username', ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'account_role', ''), 'user'),
    nullif(new.raw_user_meta_data ->> 'job_title', ''),
    nullif(new.raw_user_meta_data ->> 'company_name', ''),
    nullif(new.raw_user_meta_data ->> 'employment_type', '')
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    display_name = excluded.display_name;
  return new;
end;
$$;

create table if not exists public.property_drafts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  draft_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.property_drafts enable row level security;
drop policy if exists "Users manage own property draft" on public.property_drafts;
create policy "Users manage own property draft" on public.property_drafts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.provider_profiles add column if not exists is_example boolean not null default false;
alter table public.provider_profiles add column if not exists photo_index integer;
alter table public.provider_profiles add column if not exists job_title text;
alter table public.provider_profiles drop constraint if exists provider_profiles_provider_type_check;
alter table public.provider_profiles add constraint provider_profiles_provider_type_check check (
  provider_type in ('realtor', 'mortgage_broker', 'lawyer', 'accountant', 'lender')
);
alter table public.sponsored_placements drop constraint if exists sponsored_placements_provider_type_check;
alter table public.sponsored_placements add constraint sponsored_placements_provider_type_check check (
  provider_type in ('realtor', 'mortgage_broker', 'lawyer', 'accountant', 'lender')
);

drop policy if exists "Public can read verified providers" on public.provider_profiles;
create policy "Public can read verified providers"
  on public.provider_profiles for select using (verified = true or is_example = true);

insert into public.provider_profiles (
  id, provider_type, display_name, company_name, job_title, description,
  years_experience, review_score, review_count, verified, is_example, photo_index
) values
  ('10000000-0000-4000-8000-000000000001', 'realtor', 'Claire Bennett', 'Bennett Urban Realty', 'Residential Realtor', 'Buyer representation, relocation and neighbourhood strategy.', 12, 4.9, 86, false, true, 0),
  ('10000000-0000-4000-8000-000000000002', 'realtor', 'Daniel Wu', 'Northline Property Group', 'Commercial Realtor', 'Commercial acquisitions, leasing and investment sales.', 10, 4.8, 71, false, true, 1),
  ('10000000-0000-4000-8000-000000000003', 'mortgage_broker', 'Priya Raman', 'ClearPath Mortgage', 'Mortgage Broker', 'Residential, investor and self-employed borrower financing.', 14, 4.9, 104, false, true, 2),
  ('10000000-0000-4000-8000-000000000004', 'mortgage_broker', 'Evan Mercer', 'Foundation Lending', 'Commercial Mortgage Broker', 'Commercial debt placement and construction financing.', 11, 4.7, 63, false, true, 3),
  ('10000000-0000-4000-8000-000000000005', 'lawyer', 'Naomi Brooks', 'Brooks Property Law', 'Property Lawyer', 'Purchases, sales, refinancing and title review.', 15, 4.9, 92, false, true, 4),
  ('10000000-0000-4000-8000-000000000006', 'lawyer', 'Michael Grant', 'Grant & Shore Legal', 'Commercial Real Estate Lawyer', 'Commercial transactions, leasing and development agreements.', 18, 4.8, 77, false, true, 5),
  ('10000000-0000-4000-8000-000000000007', 'accountant', 'Elena Rossi', 'Rossi Property Tax Advisory', 'Real Estate Accountant', 'Rental property tax planning, reporting and ownership structures.', 13, 4.9, 68, false, true, 6),
  ('10000000-0000-4000-8000-000000000008', 'accountant', 'Omar Haddad', 'Haddad CPA Practice', 'CPA · Real Estate', 'Corporate, partnership and development project accounting.', 16, 4.8, 81, false, true, 7),
  ('10000000-0000-4000-8000-000000000009', 'lender', 'Sarah Mitchell', 'Pacific Community Credit Union', 'Senior Lending Advisor', 'Owner-occupied and rental property lending solutions.', 12, 4.7, 59, false, true, 8),
  ('10000000-0000-4000-8000-000000000010', 'lender', 'Kevin Park', 'Metro Capital', 'Commercial Lending Manager', 'Commercial mortgages and income-property credit.', 14, 4.8, 74, false, true, 9)
on conflict (id) do update set
  display_name = excluded.display_name,
  company_name = excluded.company_name,
  job_title = excluded.job_title,
  description = excluded.description,
  review_score = excluded.review_score,
  review_count = excluded.review_count,
  is_example = true,
  photo_index = excluded.photo_index;

create table if not exists public.user_team_members (
  user_id uuid not null references auth.users(id) on delete cascade,
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, provider_id)
);
alter table public.user_team_members enable row level security;
drop policy if exists "Users manage own selected team" on public.user_team_members;
create policy "Users manage own selected team" on public.user_team_members
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-photos', 'profile-photos', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set public = true, file_size_limit = 5242880;

drop policy if exists "Public profile photos are readable" on storage.objects;
drop policy if exists "Users upload own profile photo" on storage.objects;
drop policy if exists "Users update own profile photo" on storage.objects;
create policy "Public profile photos are readable" on storage.objects
  for select using (bucket_id = 'profile-photos');
create policy "Users upload own profile photo" on storage.objects
  for insert with check (
    bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "Users update own profile photo" on storage.objects
  for update using (
    bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text
  );
