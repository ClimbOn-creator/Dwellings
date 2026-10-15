-- Additive aggregate-only API. Existing saved content and access lists are untouched.
create or replace function public.load_affinity_data_explorer(report_days integer default 30)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  report jsonb;
  histories jsonb := '{}'::jsonb;
  spec record;
  history jsonb;
  start_day date;
  end_day date := (now() at time zone 'utc')::date;
begin
  -- Reuse the live database owner check and bounded-period validation.
  report := public.load_affinity_company_data(report_days);
  start_day := end_day - (report_days-1);
  -- Every source is fixed here; callers cannot submit SQL, table names or filters.
  for spec in select * from (values
    ('accounts','select created_at as occurred_at, 1::bigint as amount from auth.users'),
    ('profiles','select created_at as occurred_at, 1::bigint as amount from public.profiles'),
    ('provider_profiles','select created_at as occurred_at, 1::bigint as amount from public.provider_profiles where not is_example'),
    ('membership_applications','select created_at as occurred_at, 1::bigint as amount from public.membership_applications'),
    ('user_team_members','select t.created_at as occurred_at, 1::bigint as amount from public.user_team_members t join public.provider_profiles p on p.id=t.provider_id where not p.is_example'),
    ('lead_requests','select created_at as occurred_at, 1::bigint as amount from public.lead_requests'),
    ('business_assessments','select created_at as occurred_at, 1::bigint as amount from public.business_assessments'),
    ('property_analyses','select created_at as occurred_at, 1::bigint as amount from public.property_analyses'),
    ('deal_rooms','select created_at as occurred_at, 1::bigint as amount from public.deal_rooms'),
    ('deal_room_members','select created_at as occurred_at, 1::bigint as amount from public.deal_room_members'),
    ('deal_room_tasks','select created_at as occurred_at, 1::bigint as amount from public.deal_room_tasks'),
    ('deal_room_documents','select created_at as occurred_at, 1::bigint as amount from public.deal_room_documents where deleted_at is null'),
    ('deal_room_document_events','select created_at as occurred_at, 1::bigint as amount from public.deal_room_document_events'),
    ('member_deal_opportunities','select submitted_at as occurred_at, 1::bigint as amount from public.member_deal_opportunities'),
    ('member_deal_pitches','select created_at as occurred_at, 1::bigint as amount from public.member_deal_pitches'),
    ('member_deal_referrals','select created_at as occurred_at, 1::bigint as amount from public.member_deal_referrals'),
    ('member_saved_deals','select saved_at as occurred_at, 1::bigint as amount from public.member_saved_deals'),
    ('member_conversations','select created_at as occurred_at, 1::bigint as amount from public.member_conversations'),
    ('member_messages','select created_at as occurred_at, 1::bigint as amount from public.member_messages'),
    ('learning_posts','select created_at as occurred_at, 1::bigint as amount from public.learning_posts'),
    ('learning_comments','select created_at as occurred_at, 1::bigint as amount from public.learning_comments where removed_at is null'),
    ('learning_reactions','select created_at as occurred_at, 1::bigint as amount from public.learning_reactions'),
    ('learning_seminars','select created_at as occurred_at, 1::bigint as amount from public.learning_seminars'),
    ('learning_rsvps','select created_at as occurred_at, 1::bigint as amount from public.learning_rsvps'),
    ('learning_progress','select completed_at as occurred_at, 1::bigint as amount from public.learning_progress'),
    ('affinity_usage_daily','select day::timestamp at time zone ''utc'' as occurred_at, visits as amount from public.affinity_usage_daily')
  ) as sources(id,source_sql) loop
    execute pg_catalog.format($query$
      with events as materialized (%s),
      daily as (select (occurred_at at time zone 'utc')::date as day,sum(amount) as count
        from events where occurred_at >= $1::timestamp at time zone 'utc'
          and occurred_at < ($2+1)::timestamp at time zone 'utc' group by 1)
      select jsonb_build_object(
        'current_total',(select coalesce(sum(amount),0) from events),
        'period_total',(select coalesce(sum(count),0) from daily),
        'previous_total',(select coalesce(sum(amount),0) from events
          where occurred_at >= ($1-$3)::timestamp at time zone 'utc'
            and occurred_at < $1::timestamp at time zone 'utc'),
        'first_recorded_day',(select min((occurred_at at time zone 'utc')::date) from events),
        'series',(select jsonb_agg(jsonb_build_object('day',d::date,'count',coalesce(daily.count,0)) order by d)
          from generate_series($1::timestamp,$2::timestamp,interval '1 day') d left join daily on daily.day=d::date)
      )
    $query$,spec.source_sql) into history using start_day,end_day,report_days;
    histories := histories || jsonb_build_object(spec.id,history);
  end loop;
  return report || jsonb_build_object('histories',histories,'timezone','UTC');
end;
$$;
revoke all on function public.load_affinity_data_explorer(integer) from public,anon;
grant execute on function public.load_affinity_data_explorer(integer) to authenticated;
