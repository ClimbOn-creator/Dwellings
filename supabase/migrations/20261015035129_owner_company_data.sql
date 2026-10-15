-- Aggregate reporting only. Existing content, documents and business records stay intact.
create or replace function public.is_affinity_data_owner()
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.affinity_admins where user_id = auth.uid() and role = 'owner'
  );
$$;
revoke all on function public.is_affinity_data_owner() from public, anon;
grant execute on function public.is_affinity_data_owner() to authenticated;

-- Anonymous daily counters: no account IDs, IPs, URLs, coordinates or form values.
create table public.affinity_usage_daily (
  day date not null default (now() at time zone 'utc')::date,
  feature text not null check (feature in ('landing','buyer','seller','member','learning','consulting')),
  visits bigint not null default 1 check (visits > 0),
  primary key(day, feature)
);
alter table public.affinity_usage_daily enable row level security;
revoke all on public.affinity_usage_daily from public, anon, authenticated;

create or replace function public.record_affinity_feature_visit(feature_name text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  if public.is_affinity_data_owner() then return; end if;
  if feature_name is null or feature_name not in ('landing','buyer','seller','member','learning','consulting') then
    raise exception 'Unsupported feature' using errcode = '22023';
  end if;
  insert into public.affinity_usage_daily(day,feature,visits)
  values ((now() at time zone 'utc')::date, feature_name, 1)
  on conflict (day,feature) do update set visits = public.affinity_usage_daily.visits + 1;
end;
$$;
revoke all on function public.record_affinity_feature_visit(text) from public, anon;
grant execute on function public.record_affinity_feature_visit(text) to authenticated;

create or replace function public.load_affinity_company_data(report_days integer default 30)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  result jsonb;
  inventories jsonb := '[]'::jsonb;
  record_count bigint;
  byte_count bigint;
  relation_name text;
  since_day date;
begin
  if not public.is_affinity_data_owner() then
    raise exception 'Owner access required' using errcode = '42501';
  end if;
  if report_days is null or report_days not in (7,30,90,365) then
    raise exception 'Choose 7, 30, 90 or 365 days' using errcode = '22023';
  end if;
  since_day := (now() at time zone 'utc')::date - (report_days - 1);
  -- Fixed allowlist, never a caller-supplied relation. Only aggregate counts leave the server.
  foreach relation_name in array array[
    'profiles','provider_profiles','membership_applications','user_team_members','lead_requests',
    'business_assessments','property_analyses','deal_rooms','deal_room_members','deal_room_tasks',
    'deal_room_documents','deal_room_document_events','member_deal_opportunities','member_deal_pitches',
    'member_deal_referrals','member_saved_deals','member_conversations','member_messages',
    'learning_posts','learning_comments','learning_reactions','learning_seminars','learning_rsvps',
    'learning_progress','learning_media','learning_event_images','affinity_usage_daily'
  ] loop
    execute pg_catalog.format('select count(*) from public.%I', relation_name) into record_count;
    byte_count := pg_catalog.pg_total_relation_size(pg_catalog.to_regclass('public.' || relation_name));
    inventories := inventories || jsonb_build_array(jsonb_build_object(
      'label', relation_name, 'count', record_count, 'bytes', byte_count));
  end loop;
  result := jsonb_build_object(
    'generated_at', now(), 'days', report_days, 'since', since_day,
    'totals', jsonb_build_object(
      'Registered accounts', (select count(*) from auth.users),
      'Saved profiles', (select count(*) from public.profiles),
      'New accounts in selected period', (select count(*) from auth.users where created_at >= since_day::timestamp at time zone 'utc'),
      'Professional profiles', (select count(*) from public.provider_profiles where not is_example),
      'Example professional profiles', (select count(*) from public.provider_profiles where is_example),
      'Team selections', (select count(*) from public.user_team_members t join public.provider_profiles p on p.id=t.provider_id where not p.is_example),
      'People with a professional on their team', (select count(distinct t.user_id) from public.user_team_members t join public.provider_profiles p on p.id=t.provider_id where not p.is_example),
      'Introduction requests', (select count(*) from public.lead_requests),
      'Deal rooms', (select count(*) from public.deal_rooms),
      'Saved business assessments', (select count(*) from public.business_assessments),
      'Learning posts', (select count(*) from public.learning_posts),
      'Learning comments', (select count(*) from public.learning_comments where removed_at is null),
      'Learning reactions', (select count(*) from public.learning_reactions),
      'Event registrations', (select count(*) from public.learning_rsvps),
      'Learning completions', (select count(*) from public.learning_progress),
      'Recorded feature visits in selected period', (select coalesce(sum(visits),0) from public.affinity_usage_daily where day >= since_day),
      'Profiles with a saved location', (select count(*) from public.profiles where nullif(trim(preferred_city),'') is not null or nullif(trim(preferred_province),'') is not null)
    ),
    'roles', (select coalesce(jsonb_agg(x),'[]') from (
      select coalesce(nullif(trim(account_role),''),'Not provided') as label,count(*) as count from public.profiles group by 1 order by count(*) desc,1 limit 20) x),
    'locations', (select coalesce(jsonb_agg(x),'[]') from (
      select concat_ws(', ', nullif(initcap(trim(preferred_city)),''),nullif(upper(trim(preferred_province)),''),nullif(upper(trim(preferred_country_code)),'')) as label,count(*) as count
      from public.profiles where nullif(trim(preferred_city),'') is not null or nullif(trim(preferred_province),'') is not null
      group by 1 order by count(*) desc,1 limit 20) x),
    'professions', (select coalesce(jsonb_agg(x),'[]') from (
      select coalesce(nullif(trim(job_title),''),nullif(trim(provider_type),''),'Not provided') as label,count(*) as count
      from public.provider_profiles where not is_example group by 1 order by count(*) desc,1 limit 20) x),
    'teams', (select coalesce(jsonb_agg(x),'[]') from (
      select p.id, p.display_name as label,p.company_name as detail,count(*) as count from public.user_team_members t join public.provider_profiles p on p.id=t.provider_id
      where not p.is_example group by p.id,p.display_name,p.company_name order by count(*) desc,p.id limit 20) x),
    'member_status', (select coalesce(jsonb_agg(x),'[]') from (
      select coalesce(nullif(membership_status,''),'Not provided') as label,count(*) as count from public.provider_profiles where not is_example group by 1 order by count(*) desc,1) x),
    'pipeline', (select coalesce(jsonb_agg(x),'[]') from (
      select coalesce(nullif(current_stage,''),'Not provided') as label,count(*) as count from public.deal_rooms group by 1 order by count(*) desc,1) x),
    'new_accounts', (select coalesce(jsonb_agg(x order by x.day),'[]') from (
      select d::date as day,count(u.id) as count from generate_series(since_day::timestamp, (now() at time zone 'utc')::date::timestamp,'1 day'::interval) d
      left join auth.users u on (u.created_at at time zone 'utc')::date=d::date group by 1) x),
    'feature_visits', (select coalesce(jsonb_agg(x),'[]') from (
      select feature as label,sum(visits) as count from public.affinity_usage_daily where day>=since_day group by feature order by sum(visits) desc,feature) x),
    'usage_started', (select min(day) from public.affinity_usage_daily),
    'inventory', inventories,
    'uploaded_file_bytes', (select coalesce(sum(file_size),0) from public.deal_room_documents where deleted_at is null)
       + (select coalesce(sum(byte_size),0) from public.learning_media)
       + (select coalesce(sum(byte_size),0) from public.learning_event_images)
  );
  return result;
end;
$$;
revoke all on function public.load_affinity_company_data(integer) from public, anon;
grant execute on function public.load_affinity_company_data(integer) to authenticated;
comment on table public.affinity_usage_daily is 'Opt-in signed-in navigation totals in UTC. Anonymous aggregates only; not unique people, attendance, verified business outcomes or billing.';
