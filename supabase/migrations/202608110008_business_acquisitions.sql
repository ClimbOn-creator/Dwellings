create table if not exists public.business_assessments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_name text not null default 'Confidential opportunity',
  industry text not null default '',
  location text not null default '',
  inputs jsonb not null default '{}'::jsonb,
  results jsonb not null default '{}'::jsonb,
  model_version text not null default 'acquisition-iq-0.1',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists business_assessments_user_created_idx
  on public.business_assessments(user_id, created_at desc);

alter table public.business_assessments enable row level security;
drop policy if exists "Users manage own business assessments"
  on public.business_assessments;
create policy "Users manage own business assessments"
  on public.business_assessments for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

alter table public.deal_rooms
  add column if not exists transaction_type text not null default 'property',
  add column if not exists business_assessment_id uuid
    references public.business_assessments(id) on delete set null;

alter table public.deal_rooms
  drop constraint if exists deal_rooms_transaction_type_check;
alter table public.deal_rooms
  add constraint deal_rooms_transaction_type_check
  check (transaction_type in ('property', 'business'));

create index if not exists deal_rooms_business_assessment_idx
  on public.deal_rooms(business_assessment_id)
  where business_assessment_id is not null;

comment on table public.business_assessments is
  'Educational initial screening for business acquisitions. Results are not a formal valuation, quality-of-earnings report, legal opinion or financing commitment.';

-- Business acquisition workspaces intentionally cannot accept document metadata
-- until the dedicated vault includes malware scanning, MFA step-up, immutable
-- access logs, expiring downloads and document watermarking.
drop policy if exists "Participants upload deal room documents"
  on public.deal_room_documents;
drop policy if exists "Participants upload property room documents"
  on public.deal_room_documents;
create policy "Participants upload property room documents"
  on public.deal_room_documents for insert
  with check (
    public.can_access_deal_room(deal_room_id)
    and uploaded_by = auth.uid()
    and exists (
      select 1 from public.deal_rooms room
      where room.id = deal_room_id
        and room.transaction_type = 'property'
    )
  );
