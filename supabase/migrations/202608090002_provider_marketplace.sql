create table if not exists public.service_regions (
  id uuid primary key default gen_random_uuid(),
  city text not null,
  region text not null,
  country_code text not null check (char_length(country_code) = 2),
  normalized_city text generated always as (lower(trim(city))) stored,
  created_at timestamptz not null default now(),
  unique (normalized_city, region, country_code)
);

create table if not exists public.provider_profiles (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete set null,
  provider_type text not null check (provider_type in ('realtor', 'mortgage_broker', 'lawyer', 'lender')),
  display_name text not null,
  company_name text not null,
  description text not null default '',
  phone text,
  email text,
  website_url text,
  license_number text,
  license_region text,
  years_experience integer check (years_experience is null or years_experience >= 0),
  review_score numeric(3,2) check (review_score is null or review_score between 0 and 5),
  review_count integer not null default 0 check (review_count >= 0),
  verified boolean not null default false,
  accepting_leads boolean not null default true,
  logo_object_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.provider_regions (
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  region_id uuid not null references public.service_regions(id) on delete cascade,
  service_notes text,
  primary key (provider_id, region_id)
);

create table if not exists public.lender_rates (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  region_id uuid not null references public.service_regions(id) on delete cascade,
  mortgage_type text not null,
  term_months integer not null check (term_months > 0),
  interest_rate numeric(7,4) not null check (interest_rate >= 0),
  apr numeric(7,4) check (apr is null or apr >= 0),
  insured boolean,
  loan_to_value_max numeric(6,3),
  qualification_notes text,
  source_url text,
  effective_at timestamptz not null,
  expires_at timestamptz,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.sponsored_placements (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  region_id uuid not null references public.service_regions(id) on delete cascade,
  provider_type text not null check (provider_type in ('realtor', 'mortgage_broker', 'lawyer', 'lender')),
  placement_priority integer not null default 100 check (placement_priority >= 0),
  disclosure_label text not null default 'Sponsored',
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create table if not exists public.lead_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  provider_id uuid not null references public.provider_profiles(id) on delete restrict,
  region_id uuid references public.service_regions(id) on delete set null,
  property_analysis_id uuid references public.property_analyses(id) on delete set null,
  requester_name text not null,
  requester_email text not null,
  requester_phone text,
  property_summary text,
  consent_to_contact boolean not null default false,
  status text not null default 'new' check (status in ('new', 'accepted', 'contacted', 'closed', 'declined')),
  created_at timestamptz not null default now()
);

create index if not exists provider_profiles_type_verified_idx
  on public.provider_profiles(provider_type, verified);
create index if not exists provider_regions_region_idx
  on public.provider_regions(region_id, provider_id);
create index if not exists lender_rates_region_effective_idx
  on public.lender_rates(region_id, effective_at desc);
create index if not exists sponsored_placements_region_active_idx
  on public.sponsored_placements(region_id, provider_type, active, ends_at);
create index if not exists lead_requests_provider_created_idx
  on public.lead_requests(provider_id, created_at desc);

alter table public.service_regions enable row level security;
alter table public.provider_profiles enable row level security;
alter table public.provider_regions enable row level security;
alter table public.lender_rates enable row level security;
alter table public.sponsored_placements enable row level security;
alter table public.lead_requests enable row level security;

create policy "Public can read service regions"
  on public.service_regions for select using (true);
create policy "Public can read verified providers"
  on public.provider_profiles for select using (verified = true);
create policy "Public can read verified provider regions"
  on public.provider_regions for select using (
    exists (
      select 1 from public.provider_profiles p
      where p.id = provider_id and p.verified = true
    )
  );
create policy "Public can read current verified lender rates"
  on public.lender_rates for select using (
    effective_at <= now()
    and (expires_at is null or expires_at > now())
    and exists (
      select 1 from public.provider_profiles p
      where p.id = provider_id and p.verified = true
    )
  );
create policy "Public can read active sponsorship disclosures"
  on public.sponsored_placements for select using (
    active = true and starts_at <= now() and ends_at > now()
  );
create policy "Users can create consented lead requests"
  on public.lead_requests for insert with check (
    consent_to_contact = true and (user_id is null or user_id = auth.uid())
  );
create policy "Users can read own lead requests"
  on public.lead_requests for select using (user_id = auth.uid());

comment on table public.sponsored_placements is
  'Paid placements. Clients must always render disclosure_label and must not describe placement as an organic best-provider ranking.';
comment on table public.lender_rates is
  'Rate records require an effective date and should be independently verified before being presented as current.';
