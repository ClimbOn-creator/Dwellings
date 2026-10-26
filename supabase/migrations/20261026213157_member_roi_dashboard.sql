-- Additive ROI tracking. Existing account data, site copy and media are retained.
create table public.member_roi_settings (
 owner_id uuid primary key references public.profiles(id) on delete cascade,
 annual_cost numeric(14,2) check(annual_cost between 0 and 999999999999),
 currency text not null default 'CAD' check(currency='CAD')
);
create table public.member_roi_outcomes (
 id uuid primary key,
 owner_id uuid not null references public.profiles(id) on delete cascade,
 kind text not null check(kind in ('consultation','transaction')),
 label text not null check(length(trim(label)) between 1 and 120),
 source text not null check(source in ('Pact profile','Pact introduction','Pact message','Pact opportunity')),
 lead_id uuid references public.lead_requests(id) on delete set null,
 occurred_on date not null check(occurred_on between date '2020-01-01' and current_date),
 revenue numeric(14,2) not null default 0 check(revenue between 0 and 999999999999 and (kind='transaction' or revenue=0)),
 created_at timestamptz not null default now(), voided_at timestamptz
);
create index member_roi_outcomes_owner_date on public.member_roi_outcomes(owner_id,occurred_on desc) where voided_at is null;
alter table public.member_roi_settings enable row level security;
alter table public.member_roi_outcomes enable row level security;
revoke all on public.member_roi_settings,public.member_roi_outcomes from public,anon,authenticated;
grant select,insert,update on public.member_roi_settings to authenticated;
grant select,insert on public.member_roi_outcomes to authenticated;
grant update(voided_at) on public.member_roi_outcomes to authenticated;
grant all on public.member_roi_settings,public.member_roi_outcomes to service_role;
create policy "Read own ROI settings" on public.member_roi_settings for select to authenticated using(owner_id=(select auth.uid()));
create policy "Insert own ROI settings" on public.member_roi_settings for insert to authenticated with check(owner_id=(select auth.uid()) and exists(select 1 from public.account_workspaces w where w.user_id=(select auth.uid()) and w.role='member'));
create policy "Update own ROI settings" on public.member_roi_settings for update to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()) and exists(select 1 from public.account_workspaces w where w.user_id=(select auth.uid()) and w.role='member'));
create policy "Read own ROI outcomes" on public.member_roi_outcomes for select to authenticated using(owner_id=(select auth.uid()));
create policy "Insert own ROI outcomes" on public.member_roi_outcomes for insert to authenticated with check(
 owner_id=(select auth.uid()) and exists(select 1 from public.account_workspaces w where w.user_id=(select auth.uid()) and w.role='member')
 and (lead_id is null or exists(select 1 from public.lead_requests l join public.provider_profiles p on p.id=l.provider_id where l.id=lead_id and p.owner_user_id=(select auth.uid())))
);
create policy "Void own ROI outcomes" on public.member_roi_outcomes for update to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));

create table pact_private.member_roi_tracking (id boolean primary key default true check(id),started_at timestamptz not null default now());
insert into pact_private.member_roi_tracking(id) values(true);
create table pact_private.member_profile_visits (
 owner_id uuid not null references public.profiles(id) on delete cascade,
 viewer_id uuid not null references auth.users(id) on delete cascade,
 viewed_on date not null default current_date,
 primary key(owner_id,viewer_id,viewed_on)
);
create table pact_private.member_roi_milestones (
 lead_id uuid not null references public.lead_requests(id) on delete cascade,
 kind text not null check(kind in ('qualified','consultation','transaction')),
 occurred_at timestamptz not null default now(),primary key(lead_id,kind)
);
alter table pact_private.member_roi_tracking enable row level security;
alter table pact_private.member_profile_visits enable row level security;
alter table pact_private.member_roi_milestones enable row level security;
revoke all on pact_private.member_roi_tracking,pact_private.member_profile_visits,pact_private.member_roi_milestones from public,anon,authenticated;
create function pact_private.capture_roi_milestone() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.status in ('qualified','contacted','consultation','won') then
  insert into pact_private.member_roi_milestones(lead_id,kind) values(new.id,'qualified') on conflict do nothing;
 end if;
 if new.status in ('consultation','won') then
  insert into pact_private.member_roi_milestones(lead_id,kind) values(new.id,case when new.status='won' then 'transaction' else 'consultation' end) on conflict do nothing;
 end if;
 return new;
end $$;
revoke all on function pact_private.capture_roi_milestone() from public,anon,authenticated;
create trigger member_roi_lead_milestone after insert or update of status on public.lead_requests for each row execute function pact_private.capture_roi_milestone();

create function pact_private.record_member_profile_view(p_member uuid,p_provider uuid) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); target uuid:=p_member;
begin
 if actor is null then return; end if;
 if p_provider is not null then select owner_user_id into target from public.provider_profiles where id=p_provider and verified and not is_example; end if;
 if target is null or target=actor or not exists(select 1 from public.account_workspaces where user_id=target and role='member') then return; end if;
 insert into pact_private.member_profile_visits(owner_id,viewer_id) values(target,actor) on conflict do nothing;
end $$;
revoke all on function pact_private.record_member_profile_view(uuid,uuid) from public,anon,authenticated;
grant execute on function pact_private.record_member_profile_view(uuid,uuid) to authenticated;
create function public.pact_record_member_profile_view(p_member uuid default null,p_provider uuid default null) returns void language sql security invoker set search_path='' as $$ select pact_private.record_member_profile_view(p_member,p_provider) $$;
revoke all on function public.pact_record_member_profile_view(uuid,uuid) from public,anon;
grant execute on function public.pact_record_member_profile_view(uuid,uuid) to authenticated;

create function pact_private.member_roi_summary(p_days integer) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=auth.uid(); first_day date; result jsonb;
begin
 if actor is null or not exists(select 1 from public.account_workspaces where user_id=actor and role='member') then raise exception 'Member account required'; end if;
 if p_days not in (30,90,365) then raise exception 'Choose 30, 90 or 365 days'; end if;
 first_day:=current_date-(p_days-1);
 with milestones as (
  select m.* from pact_private.member_roi_milestones m join public.lead_requests l on l.id=m.lead_id join public.provider_profiles p on p.id=l.provider_id
  where p.owner_user_id=actor and m.occurred_at>=first_day
 ), outcomes as (select * from public.member_roi_outcomes where owner_id=actor and voided_at is null and occurred_on>=first_day),
 consultations as (select 'lead:'||lead_id::text as key from milestones where kind='consultation' union select coalesce('lead:'||lead_id::text,'outcome:'||id::text) from outcomes where kind='consultation'),
 transactions as (select 'lead:'||lead_id::text as key from milestones where kind='transaction' union select coalesce('lead:'||lead_id::text,'outcome:'||id::text) from outcomes where kind='transaction')
 select jsonb_build_object(
  'days',p_days,'tracking_started_at',(select started_at from pact_private.member_roi_tracking),
  'views',(select count(*) from pact_private.member_profile_visits where owner_id=actor and viewed_on>=first_day),
  'qualified_inquiries',(select count(*) from milestones where kind='qualified'),
  'consultations',(select count(*) from consultations),'transactions',(select count(*) from transactions),
  'revenue',coalesce((select sum(revenue) from outcomes where kind='transaction'),0),
  'annual_cost',(select annual_cost from public.member_roi_settings where owner_id=actor),'currency','CAD',
  'outcomes',coalesce((select jsonb_agg(to_jsonb(t)) from (select id,kind,label,source,occurred_on,revenue from outcomes order by occurred_on desc,created_at desc limit 20)t),'[]'::jsonb),
  'inquiries',coalesce((select jsonb_agg(to_jsonb(t)) from (select l.id,l.requester_name,l.status from public.lead_requests l join public.provider_profiles p on p.id=l.provider_id where p.owner_user_id=actor order by l.created_at desc limit 50)t),'[]'::jsonb)
 ) into result;
 return result;
end $$;
revoke all on function pact_private.member_roi_summary(integer) from public,anon,authenticated;
grant execute on function pact_private.member_roi_summary(integer) to authenticated;
create function public.pact_member_roi_summary(p_days integer default 365) returns jsonb language sql stable security invoker set search_path='' as $$ select pact_private.member_roi_summary(p_days) $$;
revoke all on function public.pact_member_roi_summary(integer) from public,anon;
grant execute on function public.pact_member_roi_summary(integer) to authenticated;
