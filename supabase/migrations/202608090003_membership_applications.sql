create table if not exists public.membership_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  applicant_type text not null check (
    applicant_type in ('homebuyer', 'investor', 'realtor', 'mortgage_broker', 'lawyer', 'lender')
  ),
  full_name text not null,
  email text not null,
  phone text,
  company_name text,
  license_number text,
  license_region text,
  specialties text[] not null default '{}',
  service_markets text[] not null default '{}',
  looking_city text,
  looking_province text,
  property_types text[] not null default '{}',
  purchase_timeline text,
  financing_help boolean not null default false,
  sponsorship_interest boolean not null default false,
  notes text,
  consent_to_contact boolean not null default false,
  status text not null default 'submitted' check (
    status in ('submitted', 'reviewing', 'approved', 'declined')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(trim(full_name)) > 1),
  check (position('@' in email) > 1)
);

create index if not exists membership_applications_user_created_idx
  on public.membership_applications(user_id, created_at desc);
create index if not exists membership_applications_status_type_idx
  on public.membership_applications(status, applicant_type, created_at desc);

alter table public.membership_applications enable row level security;

drop policy if exists "Anyone can submit a consented membership application"
  on public.membership_applications;
drop policy if exists "Users can read own membership applications"
  on public.membership_applications;

create policy "Anyone can submit a consented membership application"
  on public.membership_applications for insert with check (
    consent_to_contact = true and (user_id is null or user_id = auth.uid())
  );
create policy "Users can read own membership applications"
  on public.membership_applications for select using (user_id = auth.uid());

comment on table public.membership_applications is
  'Applications from buyers, investors and Canadian property professionals. Sponsorship interest never grants verification or ranking automatically.';
