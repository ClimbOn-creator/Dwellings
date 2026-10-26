-- A single canonical relationship is visible to both members. No profile copy,
-- email, message or private account data is placed in the public content store.
create table public.member_friendships (
  id uuid primary key default gen_random_uuid(),
  member_low uuid not null references public.profiles(id) on delete cascade,
  member_high uuid not null references public.profiles(id) on delete cascade,
  requested_by uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  unique(member_low,member_high),
  check (member_low < member_high),
  check (requested_by in (member_low,member_high)),
  check ((status='pending' and accepted_at is null) or (status='accepted' and accepted_at is not null))
);
create index member_friendships_high on public.member_friendships(member_high);
alter table public.member_friendships enable row level security;
revoke all on public.member_friendships from public, anon, authenticated;
grant select on public.member_friendships to authenticated;
grant all on public.member_friendships to service_role;
create policy "Members read their own friendships" on public.member_friendships
for select to authenticated using ((select auth.uid()) in (member_low,member_high));

-- Private privileged code is needed to read each peer's membership and expose
-- only deliberate profile fields without opening private profiles to the API.
create function pact_private.friend_action(p_target uuid,p_action text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); lo uuid; hi uuid; relation public.member_friendships;
begin
  if actor is null or p_target is null or actor=p_target then raise exception 'Choose another member'; end if;
  if not exists(select 1 from public.account_workspaces where user_id=actor and role='member')
    or not exists(select 1 from public.account_workspaces where user_id=p_target and role='member') then
    raise exception 'Friends is available between Member accounts';
  end if;
  lo:=least(actor,p_target); hi:=greatest(actor,p_target);
  perform pg_advisory_xact_lock(hashtextextended(lo::text||hi::text,0));
  select * into relation from public.member_friendships where member_low=lo and member_high=hi for update;
  if p_action='request' then
    if relation.id is null then
      if (select count(*) from public.member_friendships where requested_by=actor and created_at>now()-interval '1 hour')>=30 then
        raise exception 'Please wait before sending more friend requests';
      end if;
      insert into public.member_friendships(member_low,member_high,requested_by) values(lo,hi,actor) returning * into relation;
    end if;
  elsif p_action='accept' then
    if relation.id is null or relation.requested_by=actor then raise exception 'Only the recipient can accept this request'; end if;
    update public.member_friendships set status='accepted',accepted_at=coalesce(accepted_at,now()) where id=relation.id returning * into relation;
  elsif p_action in ('decline','cancel','remove') then
    if relation.id is not null then
      if (p_action='decline' and (relation.status<>'pending' or relation.requested_by=actor))
        or (p_action='cancel' and (relation.status<>'pending' or relation.requested_by<>actor))
        or (p_action='remove' and relation.status<>'accepted') then raise exception 'This friendship changed. Refresh and try again.'; end if;
      delete from public.member_friendships where id=relation.id;
    end if;
    return jsonb_build_object('status','none');
  else raise exception 'Invalid friend action'; end if;
  return jsonb_build_object('id',relation.id,'status',relation.status,'incoming',relation.requested_by<>actor);
end $$;
revoke all on function pact_private.friend_action(uuid,text) from public,anon,authenticated;
grant execute on function pact_private.friend_action(uuid,text) to authenticated;

create function public.pact_friend_action(p_target uuid,p_action text) returns jsonb
language sql security invoker set search_path='' as $$ select pact_private.friend_action(p_target,p_action) $$;
revoke all on function public.pact_friend_action(uuid,text) from public,anon;
grant execute on function public.pact_friend_action(uuid,text) to authenticated;

create function pact_private.friend_people(p_scope text,p_query text,p_target uuid,p_offset integer) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=auth.uid(); result jsonb;
begin
  if actor is null or not exists(select 1 from public.account_workspaces where user_id=actor and role='member') then
    raise exception 'Sign in with a Member account to view Friends';
  end if;
  if p_scope not in ('friends','requests','discover','profile') or p_offset<0 or p_offset>10000 or length(p_query)>100 then raise exception 'Invalid friend search'; end if;
  with matches as (
    select p.id as user_id,coalesce(nullif(p.full_name,''),nullif(p.display_name,''),'Pact member') as name,
      p.job_title,p.company_name,p.profile_photo_url as photo_url,p.profile_cover_url as cover_url,p.bio,
      coalesce(f.status,'none') as status,coalesce(f.requested_by<>actor,false) as incoming,
      f.accepted_at,f.created_at
    from public.profiles p
    join public.account_workspaces w on w.user_id=p.id and w.role='member'
    left join public.member_friendships f on f.member_low=least(actor,p.id) and f.member_high=greatest(actor,p.id)
    where p.id<>actor
      and case p_scope
        when 'friends' then f.status='accepted'
        when 'requests' then f.status='pending'
        when 'discover' then f.id is null
        when 'profile' then p.id=p_target
      end
      and (p_scope='profile' or length(trim(p_query))=0 or
        position(lower(trim(p_query)) in lower(coalesce(p.full_name,'')||' '||coalesce(p.company_name,'')||' '||coalesce(p.job_title,'')))>0)
  ) select jsonb_build_object('total',(select count(*) from matches),
    'people',coalesce((select jsonb_agg(to_jsonb(page)) from (
      select * from matches order by incoming desc,name,user_id limit 18 offset p_offset
    ) page),'[]'::jsonb)) into result;
  return result;
end $$;
revoke all on function pact_private.friend_people(text,text,uuid,integer) from public,anon,authenticated;
grant execute on function pact_private.friend_people(text,text,uuid,integer) to authenticated;
create function public.pact_friend_people(p_scope text default 'friends',p_query text default '',p_target uuid default null,p_offset integer default 0) returns jsonb
language sql stable security invoker set search_path='' as $$ select pact_private.friend_people(p_scope,coalesce(p_query,''),p_target,coalesce(p_offset,0)) $$;
revoke all on function public.pact_friend_people(text,text,uuid,integer) from public,anon;
grant execute on function public.pact_friend_people(text,text,uuid,integer) to authenticated;

create function pact_private.friend_provider(p_provider uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=auth.uid(); target uuid;
begin
  if actor is null or not exists(select 1 from public.account_workspaces where user_id=actor and role='member') then
    raise exception 'Sign in with a Member account to view Friends';
  end if;
  select owner_user_id into target from public.provider_profiles where id=p_provider;
  if target is null or target=actor then return null; end if;
  return pact_private.friend_people('profile','',target,0)->'people'->0;
end $$;
revoke all on function pact_private.friend_provider(uuid) from public,anon,authenticated;
grant execute on function pact_private.friend_provider(uuid) to authenticated;
create function public.pact_friend_provider(p_provider uuid) returns jsonb
language sql stable security invoker set search_path='' as $$ select pact_private.friend_provider(p_provider) $$;
revoke all on function public.pact_friend_provider(uuid) from public,anon;
grant execute on function public.pact_friend_provider(uuid) to authenticated;
