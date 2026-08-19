-- Privacy-first Member Studio deal marketplace.
-- Raw assessments and buyer identity remain in private tables. Professionals
-- browse only the deliberately sanitized fields returned by RPC functions.

create table if not exists public.member_deal_opportunities (
  id uuid primary key default gen_random_uuid(),
  deal_room_id uuid not null unique references public.deal_rooms(id) on delete cascade,
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  buyer_contact_email text not null default '',
  headline text not null default '',
  industry text not null default '',
  region text not null default '',
  summary text not null default '',
  stage text not null default 'Affinity review',
  purchase_price_band text not null default 'Private',
  capital_required_band text not null default 'To be discussed',
  affinity_score integer check (affinity_score between 0 and 100),
  score_label text not null default 'Under review',
  support_needed text[] not null default '{}',
  status text not null default 'submitted' check (
    status in ('submitted', 'reviewing', 'needs_information', 'approved', 'published', 'paused', 'closed', 'declined')
  ),
  review_notes text not null default '',
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  published_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.member_deal_pitches (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references public.member_deal_opportunities(id) on delete cascade,
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  provider_name text not null,
  company_name text not null default '',
  provider_type text not null default 'Professional',
  pitch text not null check (char_length(pitch) between 30 and 420),
  offer_summary text not null default '' check (char_length(offer_summary) <= 120),
  contact_email text not null check (char_length(contact_email) between 5 and 254),
  status text not null default 'submitted' check (
    status in ('submitted', 'accepted', 'declined', 'withdrawn')
  ),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  unique (opportunity_id, provider_id)
);

create index if not exists member_deal_opportunities_feed_idx
  on public.member_deal_opportunities(status, published_at desc);
create index if not exists member_deal_pitches_provider_idx
  on public.member_deal_pitches(provider_id, created_at desc);
create index if not exists member_deal_pitches_opportunity_idx
  on public.member_deal_pitches(opportunity_id, created_at desc);

alter table public.member_deal_opportunities enable row level security;
alter table public.member_deal_pitches enable row level security;

drop policy if exists "Buyers read own Member Studio submissions"
  on public.member_deal_opportunities;
create policy "Buyers read own Member Studio submissions"
  on public.member_deal_opportunities for select
  using (owner_user_id = auth.uid());

drop policy if exists "Professionals read own Member Studio pitches"
  on public.member_deal_pitches;
create policy "Professionals read own Member Studio pitches"
  on public.member_deal_pitches for select
  using (
    exists (
      select 1 from public.provider_profiles provider
      where provider.id = provider_id and provider.owner_user_id = auth.uid()
    )
  );

drop policy if exists "Buyers read responses to own Member Studio deals"
  on public.member_deal_pitches;
create policy "Buyers read responses to own Member Studio deals"
  on public.member_deal_pitches for select
  using (
    exists (
      select 1 from public.member_deal_opportunities opportunity
      where opportunity.id = opportunity_id
        and opportunity.owner_user_id = auth.uid()
    )
  );

create or replace function public.is_active_affinity_member()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.provider_profiles provider
    where provider.owner_user_id = auth.uid()
      and provider.verified = true
      and provider.membership_status in ('active', 'trialing')
      and provider.membership_tier in ('professional', 'featured')
      and provider.onboarding_status = 'verified'
  );
$$;

grant execute on function public.is_active_affinity_member() to authenticated;

create or replace function public.browse_member_deals()
returns table (
  id uuid,
  headline text,
  industry text,
  region text,
  summary text,
  stage text,
  purchase_price_band text,
  capital_required_band text,
  affinity_score integer,
  score_label text,
  support_needed text[],
  published_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_active_affinity_member() then
    raise exception 'A verified Affinity member is required';
  end if;
  return query
  select opportunity.id,
         opportunity.headline,
         opportunity.industry,
         opportunity.region,
         opportunity.summary,
         opportunity.stage,
         opportunity.purchase_price_band,
         opportunity.capital_required_band,
         opportunity.affinity_score,
         opportunity.score_label,
         opportunity.support_needed,
         opportunity.published_at
  from public.member_deal_opportunities opportunity
  where opportunity.status = 'published'
  order by opportunity.published_at desc;
end;
$$;

grant execute on function public.browse_member_deals() to authenticated;

create or replace function public.submit_deal_to_member_studio(
  target_deal_room_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  room public.deal_rooms;
  opportunity_id uuid;
begin
  select * into room
  from public.deal_rooms candidate
  where candidate.id = target_deal_room_id
    and candidate.user_id = auth.uid()
    and candidate.transaction_type = 'business';

  if room.id is null then
    raise exception 'Business deal not found or access denied';
  end if;

  insert into public.member_deal_opportunities (
    deal_room_id,
    owner_user_id,
    buyer_contact_email,
    region,
    stage,
    status,
    updated_at
  ) values (
    room.id,
    auth.uid(),
    coalesce(auth.jwt() ->> 'email', ''),
    room.city,
    room.current_stage,
    'submitted',
    now()
  )
  on conflict (deal_room_id) do update
    set status = case
          when member_deal_opportunities.status in ('published', 'approved')
            then member_deal_opportunities.status
          else 'submitted'
        end,
        submitted_at = now(),
        updated_at = now()
  returning id into opportunity_id;

  return opportunity_id;
end;
$$;

grant execute on function public.submit_deal_to_member_studio(uuid)
  to authenticated;

create or replace function public.submit_member_deal_pitch(
  target_opportunity_id uuid,
  pitch_text text,
  offer_text text,
  reply_email text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  provider public.provider_profiles;
  pitch_id uuid;
begin
  if not public.is_active_affinity_member() then
    raise exception 'A verified Affinity member is required';
  end if;
  if char_length(trim(pitch_text)) not between 30 and 420 then
    raise exception 'Pitch must be between 30 and 420 characters';
  end if;
  if char_length(trim(offer_text)) > 120 then
    raise exception 'Offer summary is too long';
  end if;
  if position('@' in reply_email) < 2 then
    raise exception 'A valid reply email is required';
  end if;
  if not exists (
    select 1 from public.member_deal_opportunities opportunity
    where opportunity.id = target_opportunity_id
      and opportunity.status = 'published'
  ) then
    raise exception 'Opportunity is not available';
  end if;

  select * into provider
  from public.provider_profiles candidate
  where candidate.owner_user_id = auth.uid()
    and candidate.verified = true
    and candidate.membership_status in ('active', 'trialing')
  limit 1;

  insert into public.member_deal_pitches (
    opportunity_id,
    provider_id,
    provider_name,
    company_name,
    provider_type,
    pitch,
    offer_summary,
    contact_email
  ) values (
    target_opportunity_id,
    provider.id,
    coalesce(nullif(provider.display_name, ''), 'Affinity member'),
    coalesce(provider.company_name, ''),
    coalesce(nullif(provider.job_title, ''), 'Professional'),
    trim(pitch_text),
    trim(offer_text),
    lower(trim(reply_email))
  )
  returning id into pitch_id;

  return pitch_id;
end;
$$;

grant execute on function public.submit_member_deal_pitch(uuid, text, text, text)
  to authenticated;

create or replace function public.load_my_member_deal_pitches()
returns table (
  id uuid,
  opportunity_id uuid,
  opportunity_headline text,
  provider_name text,
  company_name text,
  provider_type text,
  pitch text,
  offer_summary text,
  contact_email text,
  status text,
  created_at timestamptz,
  buyer_contact_email text
)
language sql
stable
security definer
set search_path = public
as $$
  select response.id,
         response.opportunity_id,
         opportunity.headline,
         response.provider_name,
         response.company_name,
         response.provider_type,
         response.pitch,
         response.offer_summary,
         response.contact_email,
         response.status,
         response.created_at,
         case when response.status = 'accepted'
           then opportunity.buyer_contact_email else '' end
  from public.member_deal_pitches response
  join public.member_deal_opportunities opportunity
    on opportunity.id = response.opportunity_id
  join public.provider_profiles provider on provider.id = response.provider_id
  where provider.owner_user_id = auth.uid()
  order by response.created_at desc;
$$;

grant execute on function public.load_my_member_deal_pitches() to authenticated;

create or replace function public.load_my_member_deal_responses()
returns table (
  id uuid,
  opportunity_id uuid,
  opportunity_headline text,
  provider_name text,
  company_name text,
  provider_type text,
  pitch text,
  offer_summary text,
  contact_email text,
  status text,
  created_at timestamptz,
  buyer_contact_email text
)
language sql
stable
security definer
set search_path = public
as $$
  select response.id,
         response.opportunity_id,
         opportunity.headline,
         response.provider_name,
         response.company_name,
         response.provider_type,
         response.pitch,
         response.offer_summary,
         response.contact_email,
         response.status,
         response.created_at,
         ''::text
  from public.member_deal_pitches response
  join public.member_deal_opportunities opportunity
    on opportunity.id = response.opportunity_id
  where opportunity.owner_user_id = auth.uid()
  order by response.created_at desc;
$$;

grant execute on function public.load_my_member_deal_responses() to authenticated;

create or replace function public.respond_to_member_deal_pitch(
  target_pitch_id uuid,
  response_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if response_status not in ('accepted', 'declined') then
    raise exception 'Invalid pitch response';
  end if;

  update public.member_deal_pitches response
  set status = response_status,
      responded_at = now()
  where response.id = target_pitch_id
    and exists (
      select 1 from public.member_deal_opportunities opportunity
      where opportunity.id = response.opportunity_id
        and opportunity.owner_user_id = auth.uid()
    );

  if not found then
    raise exception 'Pitch not found or access denied';
  end if;
end;
$$;

grant execute on function public.respond_to_member_deal_pitch(uuid, text)
  to authenticated;

comment on table public.member_deal_opportunities is
  'Staff-curated anonymous summaries derived from private buyer Deal Rooms. Never expose owner_user_id, buyer_contact_email, deal_room_id, or raw assessment data to members.';
comment on table public.member_deal_pitches is
  'Short professional pitches. Buyer contact is released through a security-definer RPC only after the buyer accepts.';
