-- Creator access, traffic-aware marketplace discovery, search, and reposting.

insert into public.affinity_admins(user_id, role)
select account.id, 'owner'
from auth.users account
where lower(account.email) in ('rw0882308@gmail.com', 'dfisch5@gmail.com')
on conflict (user_id) do update set role = 'owner';

update public.provider_profiles provider
set verified = true,
    membership_tier = 'featured',
    membership_status = 'active',
    onboarding_status = 'verified',
    accepting_leads = true,
    is_example = false,
    service_markets = array['Victoria, BC'],
    updated_at = now()
from auth.users account
where account.id = provider.owner_user_id
  and lower(account.email) in ('rw0882308@gmail.com', 'dfisch5@gmail.com');

insert into public.provider_profiles(
  owner_user_id, provider_type, display_name, company_name, job_title,
  description, email, verified, accepting_leads, is_example, membership_tier,
  membership_status, onboarding_status, service_markets, specialties
)
select account.id, 'industry_advisor',
       coalesce(
         nullif(account.raw_user_meta_data ->> 'full_name', ''),
         nullif(account.raw_user_meta_data ->> 'name', ''),
         split_part(account.email, '@', 1)
       ),
       'Affinity', 'Affinity Creator',
       'Affinity creator and marketplace operator.', account.email, true, true, false,
       'featured', 'active', 'verified', array['Victoria, BC'], '{}'
from auth.users account
where lower(account.email) in ('rw0882308@gmail.com', 'dfisch5@gmail.com')
  and not exists (
    select 1 from public.provider_profiles provider
    where provider.owner_user_id = account.id
  );

insert into public.affinity_member_preferences(
  provider_id, specialties, regions, minimum_affinity_score,
  email_notifications, updated_at
)
select provider.id, coalesce(provider.specialties, '{}'), array['Victoria, BC'],
       0, true, now()
from public.provider_profiles provider
join auth.users account on account.id = provider.owner_user_id
where lower(account.email) in ('rw0882308@gmail.com', 'dfisch5@gmail.com')
on conflict (provider_id) do update
set regions = array['Victoria, BC'],
    minimum_affinity_score = 0,
    updated_at = now();

alter table public.member_deal_opportunities
  add column if not exists last_reposted_at timestamptz,
  add column if not exists repost_count integer not null default 0
    check (repost_count >= 0);

create table if not exists public.member_deal_engagements (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references public.member_deal_opportunities(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null check (event_type in ('impression', 'open', 'save', 'pitch')),
  created_at timestamptz not null default now()
);

create table if not exists public.member_saved_deals (
  user_id uuid not null references auth.users(id) on delete cascade,
  opportunity_id uuid not null references public.member_deal_opportunities(id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (user_id, opportunity_id)
);

create index if not exists member_deal_engagements_opportunity_created_idx
  on public.member_deal_engagements(opportunity_id, created_at desc);
create index if not exists member_deal_opportunities_repost_idx
  on public.member_deal_opportunities(status, last_reposted_at desc, published_at desc);

alter table public.member_deal_engagements enable row level security;
alter table public.member_saved_deals enable row level security;

drop policy if exists "Members manage own saved deals" on public.member_saved_deals;
create policy "Members manage own saved deals"
  on public.member_saved_deals for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function public.record_member_deal_engagement(
  target_opportunity_id uuid,
  target_event_type text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then return; end if;
  if target_event_type not in ('impression', 'open', 'save', 'pitch') then
    raise exception 'Invalid deal engagement';
  end if;
  if not exists (
    select 1 from public.member_deal_opportunities opportunity
    where opportunity.id = target_opportunity_id and opportunity.status = 'published'
  ) then return; end if;
  if target_event_type in ('impression', 'open') and exists (
    select 1 from public.member_deal_engagements engagement
    where engagement.opportunity_id = target_opportunity_id
      and engagement.user_id = auth.uid()
      and engagement.event_type = target_event_type
      and engagement.created_at >= current_date
  ) then return; end if;
  insert into public.member_deal_engagements(opportunity_id, user_id, event_type)
  values (target_opportunity_id, auth.uid(), target_event_type);
end;
$$;

grant execute on function public.record_member_deal_engagement(uuid, text) to authenticated;

create or replace function public.repost_member_deal(target_opportunity_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare selected public.member_deal_opportunities;
begin
  select * into selected from public.member_deal_opportunities opportunity
  where opportunity.id = target_opportunity_id
    and opportunity.owner_user_id = auth.uid()
    and opportunity.status = 'published';
  if selected.id is null then raise exception 'Published deal not found or access denied'; end if;
  if greatest(selected.published_at, coalesce(selected.last_reposted_at, '-infinity'::timestamptz))
      > now() - interval '30 days' then
    raise exception 'A deal can be reposted once it has been live for 30 days';
  end if;
  update public.member_deal_opportunities
  set last_reposted_at = now(), repost_count = repost_count + 1, updated_at = now()
  where id = selected.id;
  perform public.create_affinity_notification(
    selected.owner_user_id, 'deal', 'Your deal was reposted',
    selected.headline || ' is back at the top of the member marketplace.',
    'member-studio', 'opportunity', selected.id
  );
end;
$$;

grant execute on function public.repost_member_deal(uuid) to authenticated;

drop function if exists public.browse_member_marketplace_v2(text);
create function public.browse_member_marketplace_v2(search_text text default '')
returns table (
  id uuid, headline text, industry text, region text, summary text,
  public_details jsonb, stage text, deal_type text, purchase_price_band text,
  capital_required_band text, affinity_score integer, score_label text,
  support_needed text[], published_at timestamptz, match_score integer,
  match_reason text, match_components jsonb, can_contact boolean,
  is_recommended boolean, team_members jsonb, traffic_count bigint,
  is_owner boolean, can_repost boolean, last_reposted_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  provider_id uuid;
  creator_access boolean := public.is_affinity_admin();
begin
  select provider.id into provider_id
  from public.provider_profiles provider
  where provider.owner_user_id = auth.uid()
  order by provider.verified desc, provider.created_at
  limit 1;

  if provider_id is null and not creator_access then
    raise exception 'A verified Affinity member is required';
  end if;

  return query
  with engagement_counts as (
    select engagement.opportunity_id, count(*)::bigint as traffic
    from public.member_deal_engagements engagement
    where engagement.created_at >= now() - interval '90 days'
    group by engagement.opportunity_id
  ), feed as (
    select base.*,
           opportunity.owner_user_id,
           opportunity.last_reposted_at,
           coalesce(counts.traffic, 0)::bigint as traffic,
           greatest(
             opportunity.published_at,
             coalesce(opportunity.last_reposted_at, '-infinity'::timestamptz)
           ) as marketplace_date
    from public.affinity_member_deal_feed(provider_id) base
    join public.member_deal_opportunities opportunity on opportunity.id = base.id
    left join engagement_counts counts on counts.opportunity_id = base.id
  )
  select feed.id, feed.headline, feed.industry, feed.region, feed.summary,
         feed.public_details, feed.stage, feed.deal_type, feed.purchase_price_band,
         feed.capital_required_band, feed.affinity_score, feed.score_label,
         feed.support_needed, feed.published_at, feed.match_score,
         feed.match_reason, feed.match_components, feed.can_contact,
         case when creator_access
           then lower(feed.region) like '%victoria%'
           else feed.is_recommended end,
         feed.team_members, feed.traffic,
         feed.owner_user_id = auth.uid(),
         feed.owner_user_id = auth.uid()
           and feed.marketplace_date <= now() - interval '30 days',
         feed.last_reposted_at
  from feed
  where (
      feed.marketplace_date >= date_trunc('month', now())
      or feed.traffic >= 20
      or feed.owner_user_id = auth.uid()
    )
    and (
      trim(coalesce(search_text, '')) = ''
      or lower(
        feed.headline || ' ' || feed.industry || ' ' || feed.region || ' ' ||
        feed.summary || ' ' || feed.stage || ' ' || feed.deal_type
      ) like '%' || lower(trim(search_text)) || '%'
    )
  order by feed.marketplace_date desc, feed.traffic desc, feed.published_at desc
  limit 80;
end;
$$;

grant execute on function public.browse_member_marketplace_v2(text) to authenticated;
