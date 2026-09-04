-- Business-for-sale sourcing board, privacy-safe conversion to the existing
-- Member Studio review flow, and deal-change notifications for saved deals.

-- Keep this migration safe to run against databases where the marketplace
-- enhancement migrations were not applied in sequence. These fields/tables
-- are also created by 202609010019 and 202609010021.
alter table public.member_deal_opportunities
  add column if not exists public_details jsonb not null default '{}'::jsonb,
  add column if not exists last_reposted_at timestamptz,
  add column if not exists repost_count integer not null default 0;

alter table public.deal_rooms
  add column if not exists deal_kind text not null default 'residential',
  add column if not exists current_stage text not null default 'discovery';

create table if not exists public.member_saved_deals (
  user_id uuid not null references auth.users(id) on delete cascade,
  opportunity_id uuid not null references public.member_deal_opportunities(id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (user_id, opportunity_id)
);

alter table public.member_saved_deals enable row level security;
drop policy if exists "Members manage own saved deals" on public.member_saved_deals;
create policy "Members manage own saved deals"
  on public.member_saved_deals for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create table if not exists public.business_sale_bulletins (
  id uuid primary key default gen_random_uuid(),
  created_by_user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 3 and 180),
  industry text not null default '',
  region text not null default '',
  asking_price_band text not null default 'Contact seller',
  summary text not null check (char_length(trim(summary)) between 20 and 2000),
  source_label text not null default '',
  source_url text not null default '',
  status text not null default 'active' check (status in ('active', 'converted', 'archived')),
  converted_opportunity_id uuid references public.member_deal_opportunities(id) on delete set null,
  posted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists business_sale_bulletins_active_posted_idx
  on public.business_sale_bulletins(status, posted_at desc);

alter table public.business_sale_bulletins enable row level security;

create or replace function public.browse_business_sale_bulletins()
returns table (
  id uuid, title text, industry text, region text, asking_price_band text,
  summary text, source_label text, source_url text, posted_at timestamptz,
  converted_opportunity_id uuid, can_convert boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return query
  select bulletin.id, bulletin.title, bulletin.industry, bulletin.region,
         bulletin.asking_price_band, bulletin.summary, bulletin.source_label,
         bulletin.source_url, bulletin.posted_at,
         bulletin.converted_opportunity_id,
         public.is_affinity_admin() and bulletin.converted_opportunity_id is null
  from public.business_sale_bulletins bulletin
  where bulletin.status in ('active', 'converted')
  order by bulletin.posted_at desc;
end;
$$;

grant execute on function public.browse_business_sale_bulletins() to anon, authenticated;

create or replace function public.create_business_sale_bulletin(
  business_title text,
  business_industry text,
  business_region text,
  business_asking_price_band text,
  business_summary text,
  business_source_label text default '',
  business_source_url text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare bulletin_id uuid;
begin
  if not public.is_affinity_admin() then raise exception 'Affinity administrator access required'; end if;
  if char_length(trim(business_title)) not between 3 and 180 then
    raise exception 'A business title is required';
  end if;
  if char_length(trim(business_summary)) not between 20 and 2000 then
    raise exception 'The bulletin summary must be between 20 and 2000 characters';
  end if;
  if trim(coalesce(business_source_url, '')) <> '' and
     trim(business_source_url) !~* '^https?://' then
    raise exception 'The source link must start with http:// or https://';
  end if;
  insert into public.business_sale_bulletins(
    created_by_user_id, title, industry, region, asking_price_band,
    summary, source_label, source_url
  ) values (
    auth.uid(), trim(business_title), trim(business_industry),
    trim(business_region), coalesce(nullif(trim(business_asking_price_band), ''), 'Contact seller'),
    trim(business_summary), trim(coalesce(business_source_label, '')),
    trim(coalesce(business_source_url, ''))
  ) returning id into bulletin_id;
  return bulletin_id;
end;
$$;

grant execute on function public.create_business_sale_bulletin(text, text, text, text, text, text, text) to authenticated;

create or replace function public.create_anonymous_deal_from_bulletin(
  target_bulletin_id uuid,
  anonymous_headline text,
  anonymous_summary text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  bulletin public.business_sale_bulletins;
  assessment_id uuid;
  room_id uuid;
  opportunity_id uuid;
begin
  if not public.is_affinity_admin() then raise exception 'Affinity administrator access required'; end if;
  select * into bulletin from public.business_sale_bulletins candidate
  where candidate.id = target_bulletin_id for update;
  if bulletin.id is null then raise exception 'Bulletin post not found'; end if;
  if bulletin.converted_opportunity_id is not null then
    return bulletin.converted_opportunity_id;
  end if;
  if char_length(trim(anonymous_headline)) not between 8 and 180 then
    raise exception 'The anonymous headline must be between 8 and 180 characters';
  end if;
  if char_length(trim(anonymous_summary)) not between 40 and 2000 then
    raise exception 'The anonymous summary must be between 40 and 2000 characters';
  end if;
  if lower(trim(anonymous_headline)) = lower(trim(bulletin.title)) or
     lower(anonymous_summary) like '%' || lower(trim(bulletin.title)) || '%' then
    raise exception 'Remove the business name from the anonymous copy';
  end if;

  insert into public.business_assessments(
    user_id, business_name, industry, location, inputs
  ) values (
    auth.uid(), bulletin.title, bulletin.industry, bulletin.region,
    jsonb_build_object(
      'source', 'business_sale_bulletin',
      'bulletin_id', bulletin.id,
      'source_label', bulletin.source_label,
      'source_url', bulletin.source_url,
      'asking_price_band', bulletin.asking_price_band,
      'source_summary', bulletin.summary
    )
  ) returning id into assessment_id;

  insert into public.deal_rooms(
    user_id, title, city, timeline, goals, status, transaction_type,
    business_assessment_id, deal_kind, current_stage, property_snapshot
  ) values (
    auth.uid(), bulletin.title, bulletin.region, '',
    'Evaluate a sourced business-for-sale opportunity', 'draft', 'business',
    assessment_id, 'business', 'discovery',
    jsonb_build_object('deal_details', bulletin.summary, 'source', 'business_sale_bulletin')
  ) returning id into room_id;

  insert into public.member_deal_opportunities(
    deal_room_id, owner_user_id, buyer_contact_email, headline, industry,
    region, summary, stage, purchase_price_band, capital_required_band,
    score_label, status, review_notes, updated_at
  ) values (
    room_id, auth.uid(), coalesce(auth.jwt() ->> 'email', ''),
    trim(anonymous_headline), bulletin.industry, bulletin.region,
    trim(anonymous_summary), 'Affinity review', bulletin.asking_price_band,
    'To be discussed', 'Under review', 'reviewing',
    'Created from business sale bulletin ' || bulletin.id::text, now()
  ) returning id into opportunity_id;

  update public.business_sale_bulletins
  set status = 'converted', converted_opportunity_id = opportunity_id, updated_at = now()
  where id = bulletin.id;

  return opportunity_id;
end;
$$;

grant execute on function public.create_anonymous_deal_from_bulletin(uuid, text, text) to authenticated;

create or replace function public.audit_member_studio_opportunity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare follower record;
begin
  if tg_op = 'INSERT' then
    insert into public.affinity_audit_events(actor_user_id, event_type, entity_type, entity_id, metadata)
    values (auth.uid(), 'deal_submitted', 'opportunity', new.id, jsonb_build_object('status', new.status));
    perform public.create_affinity_notification(
      new.owner_user_id, 'deal', 'Affinity received your deal',
      'Your opportunity is private and waiting for Affinity review.',
      'member-studio', 'opportunity', new.id
    );
    perform public.create_affinity_notification(
      administrator.user_id, 'review', 'A deal is waiting for review',
      'A new private deal is ready in the Affinity Review Desk.',
      'review-desk', 'opportunity', new.id
    ) from public.affinity_admins administrator
      where administrator.user_id <> new.owner_user_id;
  elsif old.status is distinct from new.status then
    insert into public.affinity_audit_events(actor_user_id, event_type, entity_type, entity_id, metadata)
    values (auth.uid(), 'deal_status_changed', 'opportunity', new.id,
      jsonb_build_object('from', old.status, 'to', new.status));
    perform public.create_affinity_notification(
      new.owner_user_id, 'deal',
      case new.status
        when 'published' then 'Your opportunity is live'
        when 'needs_information' then 'Affinity needs more information'
        when 'approved' then 'Your opportunity passed review'
        when 'declined' then 'Your opportunity review is complete'
        else 'Your opportunity was updated'
      end,
      case new.status
        when 'published' then 'Verified professionals can now review the anonymous brief and submit private pitches.'
        when 'needs_information' then 'Open your Member Studio response centre for the latest review status.'
        when 'approved' then 'Affinity has approved the anonymous brief for the Member Studio.'
        when 'declined' then 'Open Member Studio to review the current status.'
        else 'Open Member Studio to see the latest status.'
      end,
      'member-studio', 'opportunity', new.id
    );
  elsif old.headline is distinct from new.headline
     or old.summary is distinct from new.summary
     or old.industry is distinct from new.industry
     or old.region is distinct from new.region
     or old.stage is distinct from new.stage
     or old.purchase_price_band is distinct from new.purchase_price_band
     or old.capital_required_band is distinct from new.capital_required_band
     or old.public_details is distinct from new.public_details
     or old.support_needed is distinct from new.support_needed
     or old.affinity_score is distinct from new.affinity_score
     or old.last_reposted_at is distinct from new.last_reposted_at then
    insert into public.affinity_audit_events(actor_user_id, event_type, entity_type, entity_id, metadata)
    values (auth.uid(), 'deal_content_updated', 'opportunity', new.id,
      jsonb_build_object('status', new.status));
    perform public.create_affinity_notification(
      new.owner_user_id, 'deal', 'Your opportunity was updated',
      coalesce(nullif(new.headline, ''), 'Your anonymous deal') || ' has new information in Member Studio.',
      'member-studio', 'opportunity', new.id
    );
  end if;

  if tg_op = 'UPDATE' then
    if new.status = 'published' and old.status = 'published' and (
       old.headline is distinct from new.headline
       or old.summary is distinct from new.summary
       or old.industry is distinct from new.industry
       or old.region is distinct from new.region
       or old.stage is distinct from new.stage
       or old.purchase_price_band is distinct from new.purchase_price_band
       or old.capital_required_band is distinct from new.capital_required_band
       or old.public_details is distinct from new.public_details
       or old.support_needed is distinct from new.support_needed
       or old.affinity_score is distinct from new.affinity_score
       or old.last_reposted_at is distinct from new.last_reposted_at
    ) then
      for follower in
        select saved.user_id from public.member_saved_deals saved
        where saved.opportunity_id = new.id and saved.user_id <> new.owner_user_id
      loop
        perform public.create_affinity_notification(
          follower.user_id, 'deal', 'A saved deal was updated',
          coalesce(nullif(new.headline, ''), 'An anonymous opportunity') || ' has new information.',
          'member-studio', 'opportunity', new.id
        );
      end loop;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists affinity_opportunity_audit_trigger on public.member_deal_opportunities;
create trigger affinity_opportunity_audit_trigger
after insert or update of status, headline, summary, industry, region, stage,
  purchase_price_band, capital_required_band, public_details, support_needed,
  affinity_score, last_reposted_at
on public.member_deal_opportunities
for each row execute function public.audit_member_studio_opportunity();

comment on table public.business_sale_bulletins is
  'Member bulletin board of sourced businesses for sale. Conversion creates a private Deal Room and a separate anonymous review draft.';
