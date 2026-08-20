-- Affinity Review Desk, member administration, and a correction to the
-- Member Studio pitch insert from migration 202608180014.

create table if not exists public.affinity_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'reviewer' check (role in ('reviewer', 'owner')),
  created_at timestamptz not null default now()
);

alter table public.affinity_admins enable row level security;

create or replace function public.is_affinity_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.affinity_admins administrator
    where administrator.user_id = auth.uid()
  );
$$;

grant execute on function public.is_affinity_admin() to authenticated;

create or replace function public.load_affinity_review_queue()
returns table (
  id uuid,
  status text,
  submitted_at timestamptz,
  updated_at timestamptz,
  buyer_email text,
  deal_title text,
  region text,
  current_stage text,
  purchase_price numeric,
  business_name text,
  industry text,
  assessment_inputs jsonb,
  assessment_results jsonb,
  headline text,
  summary text,
  purchase_price_band text,
  capital_required_band text,
  affinity_score integer,
  score_label text,
  support_needed text[],
  review_notes text,
  pitch_count bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_affinity_admin() then
    raise exception 'Affinity administrator access required';
  end if;

  return query
  select opportunity.id,
         opportunity.status,
         opportunity.submitted_at,
         opportunity.updated_at,
         opportunity.buyer_contact_email,
         room.title,
         coalesce(nullif(opportunity.region, ''), room.city),
         room.current_stage,
         room.purchase_price,
         coalesce(assessment.business_name, room.title),
         coalesce(nullif(opportunity.industry, ''), assessment.industry, ''),
         coalesce(assessment.inputs, room.property_snapshot, '{}'::jsonb),
         coalesce(assessment.results, room.risk_snapshot, '{}'::jsonb),
         opportunity.headline,
         opportunity.summary,
         opportunity.purchase_price_band,
         opportunity.capital_required_band,
         opportunity.affinity_score,
         opportunity.score_label,
         opportunity.support_needed,
         opportunity.review_notes,
         count(response.id)
  from public.member_deal_opportunities opportunity
  join public.deal_rooms room on room.id = opportunity.deal_room_id
  left join public.business_assessments assessment
    on assessment.id = room.business_assessment_id
  left join public.member_deal_pitches response
    on response.opportunity_id = opportunity.id
  group by opportunity.id,
           room.id,
           assessment.id
  order by case opportunity.status
      when 'submitted' then 0
      when 'reviewing' then 1
      when 'needs_information' then 2
      when 'approved' then 3
      when 'published' then 4
      else 5
    end,
    opportunity.submitted_at desc;
end;
$$;

grant execute on function public.load_affinity_review_queue() to authenticated;

create or replace function public.review_member_deal_opportunity(
  target_opportunity_id uuid,
  review_status text,
  public_headline text,
  public_industry text,
  public_region text,
  public_summary text,
  public_stage text,
  public_purchase_price_band text,
  public_capital_required_band text,
  public_affinity_score integer,
  public_score_label text,
  public_support_needed text[],
  private_review_notes text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_affinity_admin() then
    raise exception 'Affinity administrator access required';
  end if;
  if review_status not in (
    'reviewing', 'needs_information', 'approved', 'published', 'paused', 'closed', 'declined'
  ) then
    raise exception 'Invalid review status';
  end if;
  if public_affinity_score is not null and
      (public_affinity_score < 0 or public_affinity_score > 100) then
    raise exception 'Affinity score must be between 0 and 100';
  end if;
  if review_status = 'published' and (
    char_length(trim(public_headline)) < 8 or
    char_length(trim(public_summary)) < 40 or
    public_affinity_score is null
  ) then
    raise exception 'A headline, safe summary, and score are required to publish';
  end if;

  update public.member_deal_opportunities opportunity
  set status = review_status,
      headline = trim(public_headline),
      industry = trim(public_industry),
      region = trim(public_region),
      summary = trim(public_summary),
      stage = trim(public_stage),
      purchase_price_band = trim(public_purchase_price_band),
      capital_required_band = trim(public_capital_required_band),
      affinity_score = public_affinity_score,
      score_label = trim(public_score_label),
      support_needed = coalesce(public_support_needed, '{}'),
      review_notes = trim(private_review_notes),
      reviewed_at = now(),
      published_at = case
        when review_status = 'published'
          then coalesce(opportunity.published_at, now())
        else opportunity.published_at
      end,
      updated_at = now()
  where opportunity.id = target_opportunity_id;

  if not found then
    raise exception 'Opportunity not found';
  end if;
end;
$$;

grant execute on function public.review_member_deal_opportunity(
  uuid, text, text, text, text, text, text, text, text, integer, text, text[], text
) to authenticated;

create or replace function public.load_affinity_member_accounts()
returns table (
  id uuid,
  display_name text,
  company_name text,
  email text,
  provider_type text,
  verified boolean,
  membership_tier text,
  membership_status text,
  onboarding_status text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_affinity_admin() then
    raise exception 'Affinity administrator access required';
  end if;
  return query
  select provider.id,
         provider.display_name,
         provider.company_name,
         provider.email,
         provider.provider_type,
         provider.verified,
         provider.membership_tier,
         provider.membership_status,
         provider.onboarding_status,
         provider.created_at
  from public.provider_profiles provider
  where provider.owner_user_id is not null and provider.is_example = false
  order by case provider.onboarding_status
      when 'submitted' then 0
      when 'reviewing' then 1
      when 'needs_information' then 2
      when 'verified' then 3
      else 4
    end,
    provider.created_at desc;
end;
$$;

grant execute on function public.load_affinity_member_accounts() to authenticated;

create or replace function public.set_affinity_member_access(
  target_provider_id uuid,
  access_verified boolean,
  access_tier text,
  access_membership_status text,
  access_onboarding_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_affinity_admin() then
    raise exception 'Affinity administrator access required';
  end if;
  if access_tier not in ('free', 'professional', 'featured') then
    raise exception 'Invalid membership tier';
  end if;
  if access_membership_status not in ('active', 'trialing', 'past_due', 'cancelled') then
    raise exception 'Invalid membership status';
  end if;
  if access_onboarding_status not in (
    'draft', 'submitted', 'reviewing', 'needs_information', 'verified', 'declined', 'suspended'
  ) then
    raise exception 'Invalid onboarding status';
  end if;

  update public.provider_profiles provider
  set verified = access_verified,
      membership_tier = access_tier,
      membership_status = access_membership_status,
      onboarding_status = access_onboarding_status,
      verification_notes = case
        when access_verified then 'Approved in Affinity Review Desk'
        else provider.verification_notes
      end
  where provider.id = target_provider_id;

  if not found then
    raise exception 'Professional profile not found';
  end if;
end;
$$;

grant execute on function public.set_affinity_member_access(uuid, boolean, text, text, text)
  to authenticated;

-- Corrected pitch function: the original version had an extra opportunity ID
-- in the VALUES list. Replacing it is safe whether or not it has been called.
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

comment on table public.affinity_admins is
  'Explicit allow-list for the private Affinity Review Desk. Add the first owner only through the Supabase SQL editor or service-role administration.';
