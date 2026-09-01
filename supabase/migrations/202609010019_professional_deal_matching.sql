-- Explainable professional-to-deal matching and deal-specific role exclusivity.
-- Public feed functions still return privacy-reviewed fields only.

create or replace function public.affinity_profession_keywords(provider_type text)
returns text[]
language sql
immutable
set search_path = public
as $$
  select case provider_type
    when 'realtor' then array['realtor', 'real estate', 'property search', 'property broker']
    when 'mortgage_broker' then array['mortgage broker', 'mortgage', 'residential financing']
    when 'lawyer' then array['property lawyer', 'real estate lawyer', 'legal', 'lawyer']
    when 'accountant' then array['accountant', 'accounting', 'financial diligence']
    when 'lender' then array['lender', 'bank', 'financing', 'debt']
    when 'business_broker' then array['business broker', 'deal sourcing', 'business search', 'broker']
    when 'ma_lawyer' then array['m&a lawyer', 'm & a lawyer', 'transaction lawyer', 'legal', 'lawyer']
    when 'quality_of_earnings' then array['quality of earnings', 'qoe', 'financial diligence', 'accountant']
    when 'commercial_lender' then array['commercial lender', 'acquisition finance', 'financing', 'lender', 'debt']
    when 'tax_advisor' then array['tax adviser', 'tax advisor', 'tax', 'purchase price allocation']
    when 'insurance_advisor' then array['insurance adviser', 'insurance advisor', 'insurance', 'risk coverage']
    when 'human_resources' then array['human resources', 'hr adviser', 'hr advisor', 'employment', 'workforce']
    when 'cybersecurity' then array['cybersecurity', 'cyber security', 'technology risk', 'privacy']
    when 'industry_advisor' then array['industry adviser', 'industry advisor', 'commercial diligence', 'operating adviser']
    when 'wealth_manager' then array['wealth manager', 'wealth adviser', 'liquidity planning', 'wealth']
    else array[replace(coalesce(provider_type, 'professional'), '_', ' ')]
  end;
$$;

create or replace function public.affinity_profession_matches(
  provider_type text,
  support_needed text[],
  industry text,
  deal_type text
)
returns boolean
language sql
immutable
set search_path = public
as $$
  select exists (
    select 1
    from unnest(public.affinity_profession_keywords(provider_type)) keyword
    where lower(
      array_to_string(coalesce(support_needed, '{}'), ' ') || ' ' ||
      coalesce(industry, '') || ' ' || coalesce(deal_type, '')
    ) like '%' || lower(keyword) || '%'
  );
$$;

create or replace function public.affinity_location_score(
  member_regions text[],
  deal_region text
)
returns integer
language plpgsql
immutable
set search_path = public
as $$
declare
  wanted text;
  wanted_lower text;
  deal_lower text := lower(coalesce(deal_region, ''));
begin
  if coalesce(cardinality(member_regions), 0) = 0 then return 8; end if;
  foreach wanted in array member_regions loop
    wanted_lower := lower(trim(wanted));
    if wanted_lower = '' then continue; end if;
    if deal_lower like '%' || wanted_lower || '%'
       or wanted_lower like '%' || deal_lower || '%' then return 20; end if;
    if (wanted_lower like '%vancouver%' and
        (deal_lower like '%lower mainland%' or deal_lower like '%metro vancouver%'))
       or (deal_lower like '%vancouver%' and
        (wanted_lower like '%lower mainland%' or wanted_lower like '%metro vancouver%'))
       or (wanted_lower like '%victoria%' and deal_lower like '%vancouver island%')
       or (deal_lower like '%victoria%' and wanted_lower like '%vancouver island%')
       or (wanted_lower like '%toronto%' and deal_lower like '%greater toronto%')
       or (deal_lower like '%toronto%' and wanted_lower like '%greater toronto%') then
      return 20;
    end if;
    if ((wanted_lower like '%british columbia%' or wanted_lower ~ '(^|,| )bc($|,| )') and
        (deal_lower like '%british columbia%' or deal_lower ~ '(^|,| )bc($|,| )'))
       or ((wanted_lower like '%alberta%' or wanted_lower ~ '(^|,| )ab($|,| )') and
        (deal_lower like '%alberta%' or deal_lower ~ '(^|,| )ab($|,| )'))
       or ((wanted_lower like '%ontario%' or wanted_lower ~ '(^|,| )on($|,| )') and
        (deal_lower like '%ontario%' or deal_lower ~ '(^|,| )on($|,| )')) then
      return 12;
    end if;
  end loop;
  return 0;
end;
$$;

create or replace function public.affinity_deal_type_score(
  provider_type text,
  deal_type text,
  profession_match boolean
)
returns integer
language sql
immutable
set search_path = public
as $$
  select case
    when lower(coalesce(deal_type, '')) = 'business' and provider_type in (
      'business_broker', 'ma_lawyer', 'quality_of_earnings',
      'commercial_lender', 'tax_advisor', 'insurance_advisor',
      'human_resources', 'cybersecurity', 'industry_advisor', 'wealth_manager'
    ) then 10
    when lower(coalesce(deal_type, '')) in ('residential', 'commercial') and provider_type in (
      'realtor', 'mortgage_broker', 'lawyer', 'accountant', 'lender',
      'insurance_advisor', 'wealth_manager'
    ) then 10
    when profession_match then 8
    else 2
  end;
$$;

create or replace function public.affinity_background_score(
  specialties text[],
  background text,
  job_title text,
  industry text,
  summary text,
  support_needed text[]
)
returns integer
language sql
immutable
set search_path = public
as $$
  select least(20, count(distinct lower(term)) * 4)::integer
  from unnest(
    coalesce(specialties, '{}') ||
    regexp_split_to_array(coalesce(background, '') || ' ' || coalesce(job_title, ''), E'[^A-Za-z0-9&]+')
  ) term
  where char_length(trim(term)) >= 4
    and lower(
      coalesce(industry, '') || ' ' || coalesce(summary, '') || ' ' ||
      array_to_string(coalesce(support_needed, '{}'), ' ')
    ) like '%' || lower(trim(term)) || '%';
$$;

create or replace function public.affinity_member_deal_feed(target_provider_id uuid)
returns table (
  id uuid,
  headline text,
  industry text,
  region text,
  summary text,
  stage text,
  deal_type text,
  purchase_price_band text,
  capital_required_band text,
  affinity_score integer,
  score_label text,
  support_needed text[],
  published_at timestamptz,
  match_score integer,
  match_reason text,
  match_components jsonb,
  can_contact boolean,
  is_recommended boolean,
  team_members jsonb
)
language sql
stable
security definer
set search_path = public
as $$
  with member_context as (
    select provider.*,
           coalesce(preference.specialties, provider.specialties, '{}') as match_specialties,
           coalesce(preference.regions, provider.service_markets, '{}') as match_regions,
           coalesce(preference.minimum_affinity_score, 0) as minimum_score
    from public.provider_profiles provider
    left join public.affinity_member_preferences preference
      on preference.provider_id = provider.id
    where provider.id = target_provider_id
  ), scored as (
    select opportunity.*,
           room.deal_kind,
           context.provider_type,
           context.minimum_score,
           public.affinity_profession_matches(
             context.provider_type, opportunity.support_needed,
             opportunity.industry, room.deal_kind
           ) as profession_match,
           public.affinity_location_score(context.match_regions, opportunity.region) as location_points,
           public.affinity_background_score(
             context.match_specialties, context.description, context.job_title,
             opportunity.industry, opportunity.summary, opportunity.support_needed
           ) as background_points,
           public.affinity_deal_type_score(
             context.provider_type, room.deal_kind,
             public.affinity_profession_matches(
               context.provider_type, opportunity.support_needed,
               opportunity.industry, room.deal_kind
             )
           ) as deal_type_points,
           round(
             greatest(1, least(99, coalesce(opportunity.affinity_score, 1))) * 20.0 / 99.0
           )::integer as deal_quality_points,
           least(5,
             case when coalesce(context.years_experience, 0) >= 10 then 3
                  when coalesce(context.years_experience, 0) >= 5 then 2
                  when coalesce(context.years_experience, 0) > 0 then 1 else 0 end +
             case when coalesce(context.review_score, 0) >= 4.5 then 2
                  when coalesce(context.review_score, 0) > 0 then 1 else 0 end
           )::integer as member_profile_points,
           exists (
             select 1
             from public.deal_room_members member
             join public.provider_profiles teammate on teammate.id = member.provider_id
             where member.deal_room_id = opportunity.deal_room_id
               and member.status = 'accepted'
               and teammate.provider_type = context.provider_type
               and teammate.id <> context.id
           ) as role_taken,
           coalesce((
             select jsonb_agg(
               jsonb_build_object(
                 'provider_id', teammate.id,
                 'name', teammate.display_name,
                 'company', teammate.company_name,
                 'provider_type', teammate.provider_type,
                 'job_title', teammate.job_title,
                 'photo_index', teammate.photo_index,
                 'photo_url', teammate.logo_object_key
               ) order by teammate.provider_type, teammate.display_name
             )
             from public.deal_room_members member
             join public.provider_profiles teammate on teammate.id = member.provider_id
             where member.deal_room_id = opportunity.deal_room_id
               and member.status = 'accepted'
           ), '[]'::jsonb) as safe_team
    from public.member_deal_opportunities opportunity
    join public.deal_rooms room on room.id = opportunity.deal_room_id
    left join member_context context on true
    where opportunity.status = 'published'
  )
  select scored.id,
         scored.headline,
         scored.industry,
         scored.region,
         scored.summary,
         scored.stage,
         coalesce(scored.deal_kind, 'business'),
         scored.purchase_price_band,
         scored.capital_required_band,
         scored.affinity_score,
         scored.score_label,
         scored.support_needed,
         scored.published_at,
         case when target_provider_id is null then
                greatest(1, least(99, coalesce(scored.affinity_score, 1)))
              when scored.role_taken then 1
              else greatest(1, least(99,
                (case when scored.profession_match then 25
                      when coalesce(cardinality(scored.support_needed), 0) = 0 then 8 else 0 end) +
                scored.location_points + scored.background_points +
                scored.deal_type_points + scored.deal_quality_points +
                scored.member_profile_points
              ))::integer end,
         case when target_provider_id is null then 'Affinity creator review access'
              when scored.role_taken then 'Your professional role is already filled on this deal'
              else concat_ws(' · ',
                case when scored.profession_match then 'your profession is requested'
                     else 'adjacent professional fit' end,
                case when scored.location_points = 20 then 'strong location match'
                     when scored.location_points = 12 then 'same province'
                     when scored.location_points = 0 then 'outside your selected region'
                     else 'add a location for sharper matching' end,
                case when scored.background_points >= 12 then 'background strongly aligns'
                     when scored.background_points > 0 then 'some background overlap'
                     else 'no background overlap yet' end,
                'deal quality ' || greatest(1, least(99, coalesce(scored.affinity_score, 1)))::text || '/99'
              ) end,
         case when target_provider_id is null then jsonb_build_object(
                'deal_quality', greatest(1, least(99, coalesce(scored.affinity_score, 1)))
              )
              else jsonb_build_object(
                'profession', case when scored.profession_match then 25
                  when coalesce(cardinality(scored.support_needed), 0) = 0 then 8 else 0 end,
                'location', scored.location_points,
                'background', scored.background_points,
                'deal_type', scored.deal_type_points,
                'deal_quality', scored.deal_quality_points,
                'member_profile', scored.member_profile_points
              ) end,
         target_provider_id is not null and not scored.role_taken,
         target_provider_id is null or (
           not scored.role_taken and
           coalesce(scored.affinity_score, 0) >= coalesce(scored.minimum_score, 0)
         ),
         scored.safe_team
  from scored
  order by scored.published_at desc;
$$;

revoke all on function public.affinity_member_deal_feed(uuid) from public, anon, authenticated;

drop function if exists public.browse_member_deals();
create function public.browse_member_deals()
returns table (
  id uuid, headline text, industry text, region text, summary text, stage text,
  deal_type text, purchase_price_band text, capital_required_band text,
  affinity_score integer, score_label text, support_needed text[], published_at timestamptz,
  match_score integer, match_reason text, match_components jsonb, can_contact boolean,
  is_recommended boolean, team_members jsonb
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare provider_id uuid;
begin
  if not public.is_active_affinity_member() then
    raise exception 'A verified Affinity member is required';
  end if;
  select provider.id into provider_id from public.provider_profiles provider
  where provider.owner_user_id = auth.uid() and provider.verified = true limit 1;
  return query select * from public.affinity_member_deal_feed(provider_id);
end;
$$;
grant execute on function public.browse_member_deals() to authenticated;

drop function if exists public.browse_matched_member_deals();
create function public.browse_matched_member_deals()
returns table (
  id uuid, headline text, industry text, region text, summary text, stage text,
  deal_type text, purchase_price_band text, capital_required_band text,
  affinity_score integer, score_label text, support_needed text[], published_at timestamptz,
  match_score integer, match_reason text, match_components jsonb, can_contact boolean,
  is_recommended boolean, team_members jsonb
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare provider_id uuid;
begin
  if not public.is_active_affinity_member() then
    raise exception 'A verified Affinity member is required';
  end if;
  select provider.id into provider_id from public.provider_profiles provider
  where provider.owner_user_id = auth.uid() and provider.verified = true limit 1;
  return query select * from public.affinity_member_deal_feed(provider_id);
end;
$$;
grant execute on function public.browse_matched_member_deals() to authenticated;

drop function if exists public.browse_admin_member_deals();
create function public.browse_admin_member_deals()
returns table (
  id uuid, headline text, industry text, region text, summary text, stage text,
  deal_type text, purchase_price_band text, capital_required_band text,
  affinity_score integer, score_label text, support_needed text[], published_at timestamptz,
  match_score integer, match_reason text, match_components jsonb, can_contact boolean,
  is_recommended boolean, team_members jsonb
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare provider_id uuid;
begin
  if not public.is_affinity_admin() then
    raise exception 'Affinity administrator access required';
  end if;
  select provider.id into provider_id from public.provider_profiles provider
  where provider.owner_user_id = auth.uid() and provider.is_example = false limit 1;
  return query select * from public.affinity_member_deal_feed(provider_id);
end;
$$;
grant execute on function public.browse_admin_member_deals() to authenticated;

create or replace function public.enforce_deal_profession_exclusivity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare member_role text;
begin
  if new.status <> 'accepted' then return new; end if;
  select provider_type into member_role from public.provider_profiles where id = new.provider_id;
  perform pg_advisory_xact_lock(hashtextextended(new.deal_room_id::text || ':' || member_role, 0));
  if exists (
    select 1 from public.deal_room_members existing
    join public.provider_profiles provider on provider.id = existing.provider_id
    where existing.deal_room_id = new.deal_room_id
      and existing.status = 'accepted'
      and provider.provider_type = member_role
      and existing.provider_id <> new.provider_id
  ) then
    raise exception 'This professional role is already filled for this deal';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_deal_profession_exclusivity_trigger on public.deal_room_members;
create trigger enforce_deal_profession_exclusivity_trigger
before insert or update of provider_id, deal_room_id, status on public.deal_room_members
for each row execute function public.enforce_deal_profession_exclusivity();

-- Accepted marketplace pitches from before this migration become visible
-- Deal Room team memberships. Keep an existing accepted professional when a
-- role is already occupied.
insert into public.deal_room_members (
  deal_room_id, provider_id, invited_by, status, access_level, responded_at
)
select distinct on (opportunity.deal_room_id, provider.provider_type)
       opportunity.deal_room_id,
       provider.id,
       opportunity.owner_user_id,
       'accepted',
       'summary',
       coalesce(pitch.responded_at, pitch.created_at)
from public.member_deal_pitches pitch
join public.member_deal_opportunities opportunity on opportunity.id = pitch.opportunity_id
join public.provider_profiles provider on provider.id = pitch.provider_id
where pitch.status = 'accepted'
  and not exists (
    select 1 from public.deal_room_members existing
    join public.provider_profiles teammate on teammate.id = existing.provider_id
    where existing.deal_room_id = opportunity.deal_room_id
      and existing.status = 'accepted'
      and teammate.provider_type = provider.provider_type
  )
order by opportunity.deal_room_id, provider.provider_type,
         coalesce(pitch.responded_at, pitch.created_at)
on conflict (deal_room_id, provider_id) do update set
  status = 'accepted', responded_at = excluded.responded_at;

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
  opportunity public.member_deal_opportunities;
  pitch_id uuid;
begin
  if not public.is_active_affinity_member() then raise exception 'A verified Affinity member is required'; end if;
  if char_length(trim(pitch_text)) not between 30 and 420 then raise exception 'Pitch must be between 30 and 420 characters'; end if;
  if char_length(trim(offer_text)) > 120 then raise exception 'Offer summary is too long'; end if;
  if position('@' in reply_email) < 2 then raise exception 'A valid reply email is required'; end if;

  select * into opportunity from public.member_deal_opportunities candidate
  where candidate.id = target_opportunity_id and candidate.status = 'published';
  if opportunity.id is null then raise exception 'Opportunity is not available'; end if;

  select * into provider from public.provider_profiles candidate
  where candidate.owner_user_id = auth.uid() and candidate.verified = true
    and candidate.membership_status in ('active', 'trialing') limit 1;

  perform pg_advisory_xact_lock(hashtextextended(opportunity.deal_room_id::text || ':' || provider.provider_type, 0));
  if exists (
    select 1 from public.deal_room_members member
    join public.provider_profiles teammate on teammate.id = member.provider_id
    where member.deal_room_id = opportunity.deal_room_id
      and member.status = 'accepted'
      and teammate.provider_type = provider.provider_type
      and teammate.id <> provider.id
  ) then
    raise exception 'This deal already has a % on its team', replace(provider.provider_type, '_', ' ');
  end if;

  insert into public.member_deal_pitches (
    opportunity_id, provider_id, provider_name, company_name,
    provider_type, pitch, offer_summary, contact_email
  ) values (
    target_opportunity_id, provider.id,
    coalesce(nullif(provider.display_name, ''), 'Affinity member'),
    coalesce(provider.company_name, ''),
    provider.provider_type,
    trim(pitch_text), trim(offer_text), lower(trim(reply_email))
  ) returning id into pitch_id;
  return pitch_id;
end;
$$;
grant execute on function public.submit_member_deal_pitch(uuid, text, text, text) to authenticated;

create or replace function public.respond_to_member_deal_pitch(
  target_pitch_id uuid,
  response_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_pitch public.member_deal_pitches;
  selected_opportunity public.member_deal_opportunities;
  selected_provider public.provider_profiles;
begin
  if response_status not in ('shortlisted', 'accepted', 'declined') then raise exception 'Invalid pitch response'; end if;
  select * into selected_pitch from public.member_deal_pitches where id = target_pitch_id;
  select * into selected_opportunity from public.member_deal_opportunities
    where id = selected_pitch.opportunity_id and owner_user_id = auth.uid();
  if selected_opportunity.id is null then raise exception 'Pitch not found or access denied'; end if;

  if response_status = 'accepted' then
    select * into selected_provider from public.provider_profiles where id = selected_pitch.provider_id;
    perform pg_advisory_xact_lock(hashtextextended(
      selected_opportunity.deal_room_id::text || ':' || selected_provider.provider_type, 0
    ));
    if exists (
      select 1 from public.deal_room_members member
      join public.provider_profiles teammate on teammate.id = member.provider_id
      where member.deal_room_id = selected_opportunity.deal_room_id
        and member.status = 'accepted'
        and teammate.provider_type = selected_provider.provider_type
        and teammate.id <> selected_provider.id
    ) then
      raise exception 'This professional role is already filled for this deal';
    end if;
    insert into public.deal_room_members (
      deal_room_id, provider_id, invited_by, status, access_level, responded_at
    ) values (
      selected_opportunity.deal_room_id, selected_provider.id, auth.uid(),
      'accepted', 'summary', now()
    )
    on conflict (deal_room_id, provider_id) do update set
      status = 'accepted', responded_at = now();
  end if;

  update public.member_deal_pitches
  set status = response_status,
      responded_at = case when response_status in ('accepted', 'declined') then now() else responded_at end
  where id = target_pitch_id;
end;
$$;
grant execute on function public.respond_to_member_deal_pitch(uuid, text) to authenticated;

comment on function public.affinity_member_deal_feed(uuid) is
  'Central privacy-safe deal feed. Scores profession need, deal type, member background, specialties, and location; returns accepted team members only.';
