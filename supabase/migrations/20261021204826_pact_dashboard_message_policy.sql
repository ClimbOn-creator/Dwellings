-- Server-side direction rules apply to every client, including direct API calls.
alter table public.pact_threads add column context text not null default 'general' check(context in ('general','buyer','seller','member'));
alter table public.pact_threads add column direct_key text unique;

-- Professional identity comes from owned provider records, never editable JWT metadata.
create function pact_private.messaging_member(account_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.provider_profiles where owner_user_id=account_id);
$$;
revoke all on function pact_private.messaging_member(uuid) from public,anon,authenticated;

create function pact_private.messaging_can_send(actor uuid, tid uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select
 exists(select 1 from public.pact_thread_members where thread_id=tid and user_id=actor and status='accepted')
 and (select count(*) from public.pact_thread_members where thread_id=tid and status in ('accepted','pending'))>=2
 and not exists(select 1 from public.pact_blocks b join public.pact_thread_members m on m.thread_id=tid and m.status in ('accepted','pending') where (b.user_id=actor and b.blocked_user_id=m.user_id) or (b.blocked_user_id=actor and b.user_id=m.user_id))
 and (not exists(select 1 from public.pact_thread_members where thread_id=tid and status='pending')
      or ((select count(*) from public.pact_thread_members where thread_id=tid)=2 and exists(select 1 from public.pact_threads where id=tid and creator_id=actor and last_sequence=0)))
 and (not pact_private.messaging_member(actor) or not exists(
   select 1 from public.pact_thread_members other where other.thread_id=tid and other.user_id<>actor and other.status in ('accepted','pending')
   and not pact_private.messaging_member(other.user_id)
   and not exists(select 1 from public.pact_messages message where message.thread_id=tid and message.sender_id=other.user_id)
 ));
$$;
revoke all on function pact_private.messaging_can_send(uuid,uuid) from public,anon,authenticated;
create or replace function pact_private.messaging(action text, payload jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 actor uuid := auth.uid(); tid uuid; mid uuid; target uuid; recipients uuid[];
 state text; pair_key text; seq bigint; result jsonb; existing public.pact_messages;
begin
 if actor is null or not exists(select 1 from auth.users where id=actor) then
  raise exception 'Sign in required' using errcode='42501';
 end if;
 if payload ? 'expected_user_id' and payload->>'expected_user_id'<>actor::text then raise exception 'Account changed' using errcode='42501'; end if;
 if action='capabilities' then
  return jsonb_build_object('is_member',pact_private.messaging_member(actor),'can_start_with_members',true);
 elsif action='directory' then
  select coalesce(jsonb_agg(to_jsonb(p)),'[]'::jsonb) into result from (
    select p.id as provider_id,p.owner_user_id as id,p.display_name as full_name,p.company_name,p.job_title,p.logo_object_key as profile_photo_url
    from public.provider_profiles p where p.owner_user_id is not null and p.owner_user_id<>actor
      and p.verified and not p.is_example and p.membership_status in ('active','trialing')
      and (coalesce(btrim(payload->>'query'),'')='' or p.display_name ilike '%'||left(btrim(payload->>'query'),80)||'%' or p.company_name ilike '%'||left(btrim(payload->>'query'),80)||'%')
      and not exists(select 1 from public.pact_blocks b where (b.user_id=actor and b.blocked_user_id=p.owner_user_id) or (b.blocked_user_id=actor and b.user_id=p.owner_user_id))
    order by p.display_name,p.id limit 40
  )p; return result;
 elsif action='open_member' then
  select owner_user_id into target from public.provider_profiles where id=(payload->>'provider_id')::uuid and verified and not is_example and membership_status in ('active','trialing');
  if target is null or target=actor then raise exception 'Choose an available member' using errcode='42501'; end if;
  if exists(select 1 from public.pact_blocks where (user_id=actor and blocked_user_id=target) or (user_id=target and blocked_user_id=actor)) then raise exception 'Conversation unavailable' using errcode='42501'; end if;
  pair_key:=least(actor::text,target::text)||':'||greatest(actor::text,target::text);
  perform pg_advisory_xact_lock(hashtextextended(pair_key,7));
  select id into tid from public.pact_threads where direct_key=pair_key;
  if tid is not null then
    if exists(select 1 from public.pact_thread_members where thread_id=tid and status in ('left','declined')) then raise exception 'This conversation is closed'; end if;
    return jsonb_build_object('id',tid);
  end if;
  -- Opening a profile does not notify its owner. The first actual message does.
  tid:=(payload->>'id')::uuid;
  if tid is null then raise exception 'Conversation identifier required'; end if;
  if exists(select 1 from public.pact_threads where id=tid) then raise exception 'Conversation identifier already used'; end if;
  result:=pact_private.messaging('create',jsonb_build_object('id',tid,'title','Conversation','recipients',jsonb_build_array(target)));
  update public.pact_threads set direct_key=pair_key,context=case when payload->>'context' in ('buyer','seller','member') then payload->>'context' else 'general' end where id=tid;
  delete from public.pact_push_jobs where thread_id=tid;
  return jsonb_build_object('id',tid);
 elsif action='list' then
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into result from (
   select t.id,
   case when t.direct_key is not null then coalesce((select p.full_name from public.pact_thread_members other join public.profiles p on p.id=other.user_id where other.thread_id=t.id and other.user_id<>actor limit 1),t.title) else t.title end as title,
   (select p.profile_photo_url from public.pact_thread_members other join public.profiles p on p.id=other.user_id where other.thread_id=t.id and other.user_id<>actor limit 1) as photo_url,
   t.updated_at,t.creator_id,t.context,m.status,m.last_read_sequence,t.last_sequence,pact_private.messaging_can_send(actor,t.id) as can_send,
   (select count(*) from public.pact_messages x where x.thread_id=t.id and x.sequence>m.last_read_sequence and x.sender_id<>actor) as unread_count,
   case when m.status in ('accepted','pending') then (select body from public.pact_messages x where x.thread_id=t.id order by sequence desc limit 1) else '' end as preview
   from public.pact_threads t join public.pact_thread_members m on m.thread_id=t.id
   where m.user_id=actor and m.status in ('accepted','pending') and (m.status='accepted' or t.direct_key is null or t.last_sequence>0)
   order by t.updated_at desc,t.id limit 100
  )t; return result;
 elsif action='contacts' then
  -- Exact public username lookup avoids exposing the account directory or email.
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into result from (
   select p.id,p.username,p.full_name,p.profile_photo_url from public.profiles p
   where lower(p.username::text)=lower(btrim(payload->>'username')) and p.id<>actor and exists(select 1 from public.provider_profiles provider where provider.owner_user_id=p.id and provider.verified and not provider.is_example and provider.membership_status in ('active','trialing'))
   and not exists(select 1 from public.pact_blocks b where (b.user_id=actor and b.blocked_user_id=p.id) or (b.user_id=p.id and b.blocked_user_id=actor)) limit 1
  )t; return result;
 elsif action='create' then
  -- Serializes per-account creation/rate limiting, including concurrent retries.
  perform pg_advisory_xact_lock(hashtextextended(actor::text,0));
  tid:=(payload->>'id')::uuid;
  if exists(select 1 from public.pact_threads where id=tid and creator_id=actor) then return jsonb_build_object('id',tid); end if;
  if (select count(*) from public.pact_threads where creator_id=actor and created_at>now()-interval '1 day')>=20 then raise exception 'Daily conversation limit reached'; end if;
  select array_agg(distinct value::uuid) into recipients from jsonb_array_elements_text(payload->'recipients');
  if coalesce(cardinality(recipients),0) not between 1 and 9 or actor=any(recipients) then raise exception 'Choose 1 to 9 other people'; end if;
  if exists(select 1 from unnest(recipients) r where not exists(select 1 from public.provider_profiles p where p.owner_user_id=r and p.verified and not p.is_example and p.membership_status in ('active','trialing'))) then
    raise exception 'New conversations can only be addressed to available members. Members can reply to buyers and sellers after they contact them.' using errcode='42501';
  end if;
  if exists(select 1 from public.pact_blocks where (user_id=actor and blocked_user_id=any(recipients)) or (blocked_user_id=actor and user_id=any(recipients))) then raise exception 'Account unavailable'; end if;
  insert into public.pact_threads(id,title,creator_id) values(tid,btrim(payload->>'title'),actor);
  insert into public.pact_thread_members values(tid,actor,'accepted',0);
  insert into public.pact_thread_members select tid,r,'pending',0 from unnest(recipients) r;
  insert into public.pact_push_jobs(thread_id,user_id) select tid,r from unnest(recipients) r;
  return jsonb_build_object('id',tid);
 elsif action='register_device' then
  perform pg_advisory_xact_lock(hashtextextended(actor::text,2));
  delete from public.pact_push_devices where user_id=actor and updated_at<now()-interval '30 days';
  if not exists(select 1 from public.pact_push_devices where token=payload->>'token' and user_id=actor) and (select count(*) from public.pact_push_devices where user_id=actor)>=10 then raise exception 'Device limit reached'; end if;
  if not exists(select 1 from auth.sessions where id=(auth.jwt()->>'session_id')::uuid and user_id=actor) then raise exception 'Valid session required'; end if;
  insert into public.pact_push_devices(user_id,session_id,token) values(actor,(auth.jwt()->>'session_id')::uuid,payload->>'token')
  on conflict(token) do update set user_id=actor,session_id=excluded.session_id,updated_at=now();
  return '{}'::jsonb;
 elsif action='unregister_device' then
  delete from public.pact_push_devices where user_id=actor and token=payload->>'token'; return '{}'::jsonb;
 end if;
 tid:=(payload->>'thread_id')::uuid;
 -- Lock thread first in every mutation: sequence allocation and memberships
 -- cannot change halfway through send/read/respond.
 perform 1 from public.pact_threads where id=tid for update;
 select status into state from public.pact_thread_members where thread_id=tid and user_id=actor;
 if state is null or state in ('declined','left') then raise exception 'Conversation unavailable' using errcode='42501'; end if;
 if action='respond' then
  if state<>'pending' or payload->>'status' not in ('accepted','declined') then raise exception 'Invalid request response'; end if;
  update public.pact_thread_members set status=payload->>'status' where thread_id=tid and user_id=actor;
  return '{}'::jsonb;
 elsif action='members' then
  select jsonb_agg(jsonb_build_object('id',m.user_id,'name',p.full_name,'photo_url',p.profile_photo_url,'status',m.status,'read_sequence',m.last_read_sequence)) into result
  from public.pact_thread_members m join public.profiles p on p.id=m.user_id where thread_id=tid;
  return coalesce(result,'[]'::jsonb);
 elsif state='pending' and action='messages' then
  select coalesce(jsonb_agg(to_jsonb(x) order by sequence),'[]'::jsonb) into result from (select id,thread_id,sender_id,sequence,body,created_at from public.pact_messages where thread_id=tid order by sequence limit 50)x; return result;
 elsif state<>'accepted' then raise exception 'Accept the request first' using errcode='42501';
 elsif action='messages' then
  select coalesce(jsonb_agg(to_jsonb(t) order by sequence), '[]'::jsonb) into result from (
   select id,thread_id,sender_id,sequence,body,created_at from public.pact_messages
   where thread_id=tid and sequence<coalesce((payload->>'before')::bigint,9223372036854775807)
   order by sequence desc limit 50
  )t; return result;
 elsif action='send' then
  mid:=(payload->>'id')::uuid;
  select * into existing from public.pact_messages where id=mid;
  if found then
   if existing.sender_id<>actor or existing.thread_id<>tid or existing.body<>btrim(payload->>'body') then raise exception 'Retry does not match original message'; end if;
   return to_jsonb(existing);
  end if;
  if not pact_private.messaging_can_send(actor,tid) then raise exception 'Replies require a message from the buyer or seller, and an accepted conversation. Only the initiator can send the first request message.' using errcode='42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(actor::text,1));
  if (select count(*) from public.pact_messages where sender_id=actor and created_at>now()-interval '1 minute')>=30 then raise exception 'Please wait before sending more messages'; end if;
  if pg_database_size(current_database())>850000000 then raise exception 'Messaging storage is temporarily full'; end if;
  update public.pact_threads set last_sequence=last_sequence+1,updated_at=now() where id=tid returning last_sequence into seq;
  insert into public.pact_messages values(mid,tid,actor,seq,btrim(payload->>'body'),now()) returning to_jsonb(pact_messages.*) into result;
  insert into public.pact_push_jobs(thread_id,user_id)
   select tid,user_id from public.pact_thread_members where thread_id=tid and user_id<>actor and status in ('accepted','pending')
   on conflict(thread_id,user_id) do update set available_at=now(),completed_at=null,attempts=0,revision=pact_push_jobs.revision+1;
  return result;
 elsif action='read' then
  seq:=(payload->>'sequence')::bigint;
  if not exists(select 1 from public.pact_messages where thread_id=tid and sequence=seq) then raise exception 'Unknown displayed message'; end if;
  update public.pact_thread_members set last_read_sequence=greatest(last_read_sequence,seq) where thread_id=tid and user_id=actor;
  return '{}'::jsonb;
 elsif action='leave' then
  update public.pact_thread_members set status='left' where thread_id=tid and user_id=actor;
  delete from public.pact_push_jobs where thread_id=tid and user_id=actor;
  return '{}'::jsonb;
 elsif action='block' then
  target:=(payload->>'user_id')::uuid;
  if not exists(select 1 from public.pact_thread_members where thread_id=tid and user_id=target) then raise exception 'Participant unavailable'; end if;
  insert into public.pact_blocks values(actor,target) on conflict do nothing;
  update public.pact_thread_members set status='left' where thread_id=tid and user_id=actor;
  delete from public.pact_push_jobs where thread_id=tid and user_id=actor;
  return '{}'::jsonb;
 end if;
 raise exception 'Unsupported messaging action';
end $$;

-- Retire legacy write paths so web dashboards cannot fork into a second inbox.
revoke execute on function public.start_member_conversation(uuid,uuid),public.send_member_message(uuid,text) from public,anon,authenticated;
revoke insert,update,delete on public.member_conversations,public.member_messages from anon,authenticated;
