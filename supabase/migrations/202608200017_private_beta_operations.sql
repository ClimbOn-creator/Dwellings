-- Private beta operating system: professional matching, notifications,
-- buyer pitch decisions, audit history, and admin performance metrics.

create table if not exists public.affinity_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  notification_type text not null default 'update',
  title text not null check (char_length(title) between 3 and 160),
  message text not null default '' check (char_length(message) <= 1200),
  action_module text not null default 'member-studio',
  entity_type text not null default '',
  entity_id uuid,
  read_at timestamptz,
  email_status text not null default 'pending' check (email_status in ('pending', 'sent', 'failed', 'disabled')),
  email_attempted_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists affinity_notifications_user_created_idx
  on public.affinity_notifications(user_id, created_at desc);
create index if not exists affinity_notifications_email_idx
  on public.affinity_notifications(email_status, created_at)
  where email_status = 'pending';

alter table public.affinity_notifications enable row level security;
drop policy if exists "Members read own Affinity notifications" on public.affinity_notifications;
drop policy if exists "Members update own Affinity notifications" on public.affinity_notifications;
create policy "Members read own Affinity notifications"
  on public.affinity_notifications for select using (user_id = auth.uid());
create policy "Members update own Affinity notifications"
  on public.affinity_notifications for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create table if not exists public.affinity_member_preferences (
  provider_id uuid primary key references public.provider_profiles(id) on delete cascade,
  specialties text[] not null default '{}',
  regions text[] not null default '{}',
  minimum_affinity_score integer not null default 0 check (minimum_affinity_score between 0 and 100),
  email_notifications boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.affinity_member_preferences enable row level security;
drop policy if exists "Professionals read own Affinity preferences" on public.affinity_member_preferences;
drop policy if exists "Professionals create own Affinity preferences" on public.affinity_member_preferences;
drop policy if exists "Professionals update own Affinity preferences" on public.affinity_member_preferences;
create policy "Professionals read own Affinity preferences"
  on public.affinity_member_preferences for select using (
    exists (select 1 from public.provider_profiles p where p.id = provider_id and p.owner_user_id = auth.uid())
  );
create policy "Professionals create own Affinity preferences"
  on public.affinity_member_preferences for insert with check (
    exists (select 1 from public.provider_profiles p where p.id = provider_id and p.owner_user_id = auth.uid())
  );
create policy "Professionals update own Affinity preferences"
  on public.affinity_member_preferences for update
  using (exists (select 1 from public.provider_profiles p where p.id = provider_id and p.owner_user_id = auth.uid()))
  with check (exists (select 1 from public.provider_profiles p where p.id = provider_id and p.owner_user_id = auth.uid()));

create table if not exists public.affinity_audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists affinity_audit_events_created_idx
  on public.affinity_audit_events(created_at desc);
alter table public.affinity_audit_events enable row level security;

create or replace function public.create_affinity_notification(
  target_user_id uuid,
  target_type text,
  target_title text,
  target_message text,
  target_action_module text,
  target_entity_type text,
  target_entity_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  wants_email boolean := true;
begin
  if target_user_id is null then return; end if;
  select coalesce(preference.email_notifications, true) into wants_email
  from public.provider_profiles provider
  left join public.affinity_member_preferences preference on preference.provider_id = provider.id
  where provider.owner_user_id = target_user_id
  limit 1;

  insert into public.affinity_notifications (
    user_id, notification_type, title, message, action_module,
    entity_type, entity_id, email_status
  ) values (
    target_user_id, target_type, target_title, target_message,
    target_action_module, target_entity_type, target_entity_id,
    case when coalesce(wants_email, true) then 'pending' else 'disabled' end
  );
end;
$$;

revoke all on function public.create_affinity_notification(uuid, text, text, text, text, text, uuid) from public, anon, authenticated;

create or replace function public.audit_member_studio_opportunity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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
      'A buyer submitted a private assessment to the Affinity Review Desk.',
      'review-desk', 'opportunity', new.id
    )
    from public.affinity_admins administrator;
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
  end if;
  return new;
end;
$$;

drop trigger if exists affinity_opportunity_audit_trigger on public.member_deal_opportunities;
create trigger affinity_opportunity_audit_trigger
after insert or update of status on public.member_deal_opportunities
for each row execute function public.audit_member_studio_opportunity();

alter table public.member_deal_pitches drop constraint if exists member_deal_pitches_status_check;
alter table public.member_deal_pitches add constraint member_deal_pitches_status_check
  check (status in ('submitted', 'shortlisted', 'accepted', 'declined', 'withdrawn'));

create or replace function public.audit_member_studio_pitch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  buyer_id uuid;
  professional_id uuid;
begin
  select owner_user_id into buyer_id from public.member_deal_opportunities where id = new.opportunity_id;
  select owner_user_id into professional_id from public.provider_profiles where id = new.provider_id;
  if tg_op = 'INSERT' then
    insert into public.affinity_audit_events(actor_user_id, event_type, entity_type, entity_id, metadata)
    values (auth.uid(), 'pitch_submitted', 'pitch', new.id, jsonb_build_object('opportunity_id', new.opportunity_id));
    perform public.create_affinity_notification(
      buyer_id, 'pitch', 'A professional pitched your opportunity',
      new.provider_name || case when new.company_name = '' then '' else ' from ' || new.company_name end || ' sent a private proposal.',
      'member-studio', 'pitch', new.id
    );
  elsif old.status is distinct from new.status then
    insert into public.affinity_audit_events(actor_user_id, event_type, entity_type, entity_id, metadata)
    values (auth.uid(), 'pitch_status_changed', 'pitch', new.id,
      jsonb_build_object('from', old.status, 'to', new.status, 'opportunity_id', new.opportunity_id));
    perform public.create_affinity_notification(
      professional_id, 'pitch',
      case new.status
        when 'shortlisted' then 'Your pitch was shortlisted'
        when 'accepted' then 'Your pitch was accepted'
        when 'declined' then 'The buyer closed this pitch'
        else 'Your pitch was updated'
      end,
      case new.status
        when 'accepted' then 'The buyer chose to connect. Their contact information is now available in My pitches.'
        when 'shortlisted' then 'The anonymous buyer is comparing your proposal with the next step in mind.'
        else 'Open Member Studio for the current decision.'
      end,
      'member-studio', 'pitch', new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists affinity_pitch_audit_trigger on public.member_deal_pitches;
create trigger affinity_pitch_audit_trigger
after insert or update of status on public.member_deal_pitches
for each row execute function public.audit_member_studio_pitch();

create or replace function public.audit_affinity_member_access()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.verified is distinct from new.verified
     or old.onboarding_status is distinct from new.onboarding_status
     or old.membership_status is distinct from new.membership_status then
    insert into public.affinity_audit_events(actor_user_id, event_type, entity_type, entity_id, metadata)
    values (auth.uid(), 'member_access_changed', 'provider', new.id,
      jsonb_build_object(
        'verified', new.verified,
        'onboarding_status', new.onboarding_status,
        'membership_status', new.membership_status,
        'membership_tier', new.membership_tier
      ));
    perform public.create_affinity_notification(
      new.owner_user_id, 'membership',
      case when new.verified then 'Your Affinity profile is verified'
           when new.onboarding_status = 'needs_information' then 'Affinity needs profile information'
           when new.onboarding_status = 'suspended' then 'Your Member Studio access changed'
           else 'Your professional application was updated' end,
      case when new.verified then 'Your professional profile can now appear in the directory and pitch matched opportunities.'
           else 'Open your Affinity profile for the latest membership status.' end,
      'profile', 'provider', new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists affinity_member_access_audit_trigger on public.provider_profiles;
create trigger affinity_member_access_audit_trigger
after update of verified, onboarding_status, membership_status on public.provider_profiles
for each row execute function public.audit_affinity_member_access();

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
  if response_status not in ('shortlisted', 'accepted', 'declined') then
    raise exception 'Invalid pitch response';
  end if;
  update public.member_deal_pitches response
  set status = response_status,
      responded_at = case when response_status in ('accepted', 'declined') then now() else response.responded_at end
  where response.id = target_pitch_id
    and exists (
      select 1 from public.member_deal_opportunities opportunity
      where opportunity.id = response.opportunity_id
        and opportunity.owner_user_id = auth.uid()
    );
  if not found then raise exception 'Pitch not found or access denied'; end if;
end;
$$;

grant execute on function public.respond_to_member_deal_pitch(uuid, text) to authenticated;

create or replace function public.save_affinity_match_preferences(
  target_specialties text[],
  target_regions text[],
  target_minimum_score integer,
  target_email_notifications boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  profile_id uuid;
begin
  if target_minimum_score not between 0 and 100 then raise exception 'Invalid minimum score'; end if;
  select id into profile_id from public.provider_profiles
  where owner_user_id = auth.uid() and is_example = false limit 1;
  if profile_id is null then raise exception 'Professional profile required'; end if;
  insert into public.affinity_member_preferences(provider_id, specialties, regions, minimum_affinity_score, email_notifications, updated_at)
  values (profile_id, coalesce(target_specialties, '{}'), coalesce(target_regions, '{}'), target_minimum_score, target_email_notifications, now())
  on conflict (provider_id) do update set
    specialties = excluded.specialties,
    regions = excluded.regions,
    minimum_affinity_score = excluded.minimum_affinity_score,
    email_notifications = excluded.email_notifications,
    updated_at = now();
end;
$$;

grant execute on function public.save_affinity_match_preferences(text[], text[], integer, boolean) to authenticated;

create or replace function public.load_affinity_match_preferences()
returns table(specialties text[], regions text[], minimum_affinity_score integer, email_notifications boolean)
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(preference.specialties, provider.specialties, '{}'),
         coalesce(preference.regions, provider.service_markets, '{}'),
         coalesce(preference.minimum_affinity_score, 0),
         coalesce(preference.email_notifications, true)
  from public.provider_profiles provider
  left join public.affinity_member_preferences preference on preference.provider_id = provider.id
  where provider.owner_user_id = auth.uid() and provider.is_example = false
  limit 1;
$$;

grant execute on function public.load_affinity_match_preferences() to authenticated;

create or replace function public.browse_matched_member_deals()
returns table (
  id uuid, headline text, industry text, region text, summary text, stage text,
  purchase_price_band text, capital_required_band text, affinity_score integer,
  score_label text, support_needed text[], published_at timestamptz,
  match_score integer, match_reason text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  member_provider public.provider_profiles;
  member_preferences public.affinity_member_preferences;
begin
  if not public.is_active_affinity_member() then
    raise exception 'A verified Affinity member is required';
  end if;
  select * into member_provider from public.provider_profiles p
  where p.owner_user_id = auth.uid() and p.verified = true limit 1;
  select * into member_preferences from public.affinity_member_preferences p
  where p.provider_id = member_provider.id;

  return query
  select opportunity.id, opportunity.headline, opportunity.industry, opportunity.region,
         opportunity.summary, opportunity.stage, opportunity.purchase_price_band,
         opportunity.capital_required_band, opportunity.affinity_score,
         opportunity.score_label, opportunity.support_needed, opportunity.published_at,
         least(100,
           50 +
           case when coalesce(cardinality(member_preferences.regions), 0) = 0 then 10
                when exists (select 1 from unnest(member_preferences.regions) wanted_region
                  where lower(opportunity.region) like '%' || lower(wanted_region) || '%') then 25 else 0 end +
           case when coalesce(cardinality(member_preferences.specialties), 0) = 0 then 10
                when exists (
                  select 1 from unnest(member_preferences.specialties) specialty,
                    unnest(opportunity.support_needed) needed
                  where lower(needed) like '%' || lower(specialty) || '%'
                     or lower(specialty) like '%' || lower(needed) || '%'
                ) then 25 else 0 end
         )::integer as match_score,
         case
           when coalesce(cardinality(member_preferences.specialties), 0) = 0
             and coalesce(cardinality(member_preferences.regions), 0) = 0 then 'Complete match settings for a more precise feed'
           when exists (
             select 1 from unnest(coalesce(member_preferences.specialties, '{}')) specialty,
               unnest(opportunity.support_needed) needed
             where lower(needed) like '%' || lower(specialty) || '%'
                or lower(specialty) like '%' || lower(needed) || '%'
           ) then 'Matches your selected expertise'
           else 'Matches your score and region settings'
         end as match_reason
  from public.member_deal_opportunities opportunity
  where opportunity.status = 'published'
    and coalesce(opportunity.affinity_score, 0) >= coalesce(member_preferences.minimum_affinity_score, 0)
    and (
      coalesce(cardinality(member_preferences.regions), 0) = 0
      or exists (select 1 from unnest(member_preferences.regions) wanted_region
        where lower(opportunity.region) like '%' || lower(wanted_region) || '%')
    )
    and (
      coalesce(cardinality(member_preferences.specialties), 0) = 0
      or exists (
        select 1 from unnest(member_preferences.specialties) specialty,
          unnest(opportunity.support_needed) needed
        where lower(needed) like '%' || lower(specialty) || '%'
           or lower(specialty) like '%' || lower(needed) || '%'
      )
    )
  order by match_score desc, opportunity.published_at desc;
end;
$$;

grant execute on function public.browse_matched_member_deals() to authenticated;

create or replace function public.load_affinity_beta_metrics()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_affinity_admin() then raise exception 'Affinity administrator access required'; end if;
  return jsonb_build_object(
    'submitted_deals', (select count(*) from public.member_deal_opportunities),
    'published_deals', (select count(*) from public.member_deal_opportunities where status = 'published'),
    'total_pitches', (select count(*) from public.member_deal_pitches),
    'shortlisted_pitches', (select count(*) from public.member_deal_pitches where status = 'shortlisted'),
    'accepted_pitches', (select count(*) from public.member_deal_pitches where status = 'accepted'),
    'active_professionals', (select count(*) from public.provider_profiles where verified = true and membership_status in ('active', 'trialing') and is_example = false),
    'unread_notifications', (select count(*) from public.affinity_notifications where read_at is null),
    'pending_emails', (select count(*) from public.affinity_notifications where email_status = 'pending'),
    'average_hours_to_publish', coalesce((select round(avg(extract(epoch from (published_at - submitted_at)) / 3600)::numeric, 1) from public.member_deal_opportunities where published_at is not null), 0)
  );
end;
$$;

grant execute on function public.load_affinity_beta_metrics() to authenticated;

create or replace function public.load_affinity_audit_events(event_limit integer default 50)
returns table(id uuid, event_type text, entity_type text, entity_id uuid, actor_email text, metadata jsonb, created_at timestamptz)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_affinity_admin() then raise exception 'Affinity administrator access required'; end if;
  return query
  select event.id, event.event_type, event.entity_type, event.entity_id,
         coalesce(actor.email, 'system'), event.metadata, event.created_at
  from public.affinity_audit_events event
  left join auth.users actor on actor.id = event.actor_user_id
  order by event.created_at desc
  limit least(greatest(event_limit, 1), 200);
end;
$$;

grant execute on function public.load_affinity_audit_events(integer) to authenticated;

comment on table public.affinity_notifications is 'Private in-app notification stream and transactional email outbox.';
comment on table public.affinity_audit_events is 'Security-relevant Member Studio activity. Read only through the private Review Desk RPC.';
