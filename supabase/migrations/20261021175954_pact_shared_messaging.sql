-- Additive account-based messaging. Legacy records and content remain untouched.
create schema if not exists pact_private;
revoke all on schema pact_private from public, anon;
grant usage on schema pact_private to authenticated;
create table public.pact_threads (
 id uuid primary key default gen_random_uuid(), title text not null check(length(title) between 1 and 120),
 creator_id uuid not null references auth.users(id), created_at timestamptz not null default now(),
 last_sequence bigint not null default 0, updated_at timestamptz not null default now()
);
create table public.pact_thread_members (
 thread_id uuid not null references public.pact_threads(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 status text not null check(status in ('pending','accepted','declined','left')),
 last_read_sequence bigint not null default 0, primary key(thread_id,user_id)
);
create index pact_members_user on public.pact_thread_members(user_id,status,thread_id);
create table public.pact_messages (
 id uuid primary key, thread_id uuid not null references public.pact_threads(id) on delete cascade,
 sender_id uuid not null references auth.users(id), sequence bigint not null,
 body text not null check(char_length(btrim(body)) between 1 and 4000),
 created_at timestamptz not null default now(), unique(thread_id,sequence)
);
create index pact_messages_sender_created on public.pact_messages(sender_id,created_at);
create table public.pact_blocks (
 user_id uuid not null references auth.users(id) on delete cascade,
 blocked_user_id uuid not null references auth.users(id) on delete cascade,
 primary key(user_id,blocked_user_id), check(user_id<>blocked_user_id)
);
create table public.pact_push_devices (
 user_id uuid not null references auth.users(id) on delete cascade,
 session_id uuid not null references auth.sessions(id) on delete cascade,
 token text primary key check(length(token) between 20 and 4096), updated_at timestamptz not null default now()
);
create index pact_push_devices_user on public.pact_push_devices(user_id);
create index pact_push_devices_session on public.pact_push_devices(session_id);
create table public.pact_push_jobs (
 id bigint generated always as identity primary key,
 thread_id uuid not null references public.pact_threads(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), attempts int not null default 0,
 available_at timestamptz not null default now(), completed_at timestamptz, revision bigint not null default 1,
 unique(thread_id,user_id)
);
-- Direct table reads and writes are denied. Narrow RPCs are the only client API.
alter table public.pact_threads enable row level security;
alter table public.pact_thread_members enable row level security;
alter table public.pact_messages enable row level security;
alter table public.pact_blocks enable row level security;
alter table public.pact_push_devices enable row level security;
alter table public.pact_push_jobs enable row level security;
revoke all on public.pact_threads,public.pact_thread_members,public.pact_messages,public.pact_blocks,public.pact_push_devices,public.pact_push_jobs from anon,authenticated;

-- Privileged implementation stays in an unexposed schema, with an explicit
-- account check and membership checks for every operation. Client fields never
-- select the acting identity. No dynamic SQL or arbitrary table access.
create function pact_private.messaging(action text, payload jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 actor uuid := auth.uid(); tid uuid; mid uuid; target uuid; recipients uuid[];
 state text; seq bigint; result jsonb; existing public.pact_messages;
begin
 if actor is null or not exists(select 1 from auth.users where id=actor) then
  raise exception 'Sign in required' using errcode='42501';
 end if;
 if payload ? 'expected_user_id' and payload->>'expected_user_id'<>actor::text then raise exception 'Account changed' using errcode='42501'; end if;
 if action='list' then
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into result from (
   select t.id,t.title,t.updated_at,m.status,m.last_read_sequence,t.last_sequence,
   (select count(*) from public.pact_messages x where x.thread_id=t.id and x.sequence>m.last_read_sequence and x.sender_id<>actor) as unread_count,
   case when m.status='accepted' then (select body from public.pact_messages x where x.thread_id=t.id order by sequence desc limit 1) else '' end as preview
   from public.pact_threads t join public.pact_thread_members m on m.thread_id=t.id
   where m.user_id=actor and m.status in ('accepted','pending')
   order by t.updated_at desc,t.id limit 100
  )t; return result;
 elsif action='contacts' then
  -- Exact public username lookup avoids exposing the account directory or email.
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) into result from (
   select p.id,p.username,p.full_name,p.profile_photo_url from public.profiles p
   where lower(p.username::text)=lower(btrim(payload->>'username')) and p.id<>actor
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
  if exists(select 1 from unnest(recipients) r where not exists(select 1 from public.profiles where id=r)) then raise exception 'Account unavailable'; end if;
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
 elsif state<>'accepted' then raise exception 'Accept the request first' using errcode='42501';
 elsif action='messages' then
  select coalesce(jsonb_agg(to_jsonb(t) order by sequence), '[]'::jsonb) into result from (
   select id,thread_id,sender_id,sequence,body,created_at from public.pact_messages
   where thread_id=tid and sequence<coalesce((payload->>'before')::bigint,9223372036854775807)
   order by sequence desc limit 50
  )t; return result;
 elsif action='send' then
  if exists(select 1 from public.pact_thread_members where thread_id=tid and status='pending') then raise exception 'Waiting for everyone to accept'; end if;
  if (select count(*) from public.pact_thread_members where thread_id=tid and status='accepted')<2 then raise exception 'No other participant is available'; end if;
  if exists(select 1 from public.pact_blocks b join public.pact_thread_members m on m.thread_id=tid and m.status='accepted' where (b.user_id=actor and b.blocked_user_id=m.user_id) or (b.blocked_user_id=actor and b.user_id=m.user_id)) then raise exception 'Conversation unavailable'; end if;
  mid:=(payload->>'id')::uuid;
  select * into existing from public.pact_messages where id=mid;
  if found then
   if existing.sender_id<>actor or existing.thread_id<>tid or existing.body<>btrim(payload->>'body') then raise exception 'Retry does not match original message'; end if;
   return to_jsonb(existing);
  end if;
  perform pg_advisory_xact_lock(hashtextextended(actor::text,1));
  if (select count(*) from public.pact_messages where sender_id=actor and created_at>now()-interval '1 minute')>=30 then raise exception 'Please wait before sending more messages'; end if;
  if pg_database_size(current_database())>850000000 then raise exception 'Messaging storage is temporarily full'; end if;
  update public.pact_threads set last_sequence=last_sequence+1,updated_at=now() where id=tid returning last_sequence into seq;
  insert into public.pact_messages values(mid,tid,actor,seq,btrim(payload->>'body'),now()) returning to_jsonb(pact_messages.*) into result;
  insert into public.pact_push_jobs(thread_id,user_id)
   select tid,user_id from public.pact_thread_members where thread_id=tid and user_id<>actor and status='accepted'
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
revoke all on function pact_private.messaging(text,jsonb) from public,anon;
grant execute on function pact_private.messaging(text,jsonb) to authenticated;
create function public.pact_messaging(action text,payload jsonb default '{}'::jsonb)
returns jsonb language sql security invoker set search_path='' as $$ select pact_private.messaging(action,payload); $$;
revoke all on function public.pact_messaging(text,jsonb) from public,anon;
grant execute on function public.pact_messaging(text,jsonb) to authenticated;
-- Legacy functions retain their authenticated checks but lose anonymous entry.
revoke execute on function public.start_member_conversation(uuid,uuid),public.list_member_conversations(),public.load_member_messages(uuid),public.send_member_message(uuid,text) from public,anon;
grant execute on function public.start_member_conversation(uuid,uuid),public.list_member_conversations(),public.load_member_messages(uuid),public.send_member_message(uuid,text) to authenticated;
