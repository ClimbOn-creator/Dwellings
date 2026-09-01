-- Member-to-member conversations and professional referrals for reviewed deals.
-- Buyer identity remains isolated: deal context uses only the anonymous opportunity.

create table if not exists public.member_conversations (
  id uuid primary key default gen_random_uuid(),
  provider_a_id uuid not null references public.provider_profiles(id) on delete cascade,
  provider_b_id uuid not null references public.provider_profiles(id) on delete cascade,
  opportunity_id uuid references public.member_deal_opportunities(id) on delete set null,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  check (provider_a_id <> provider_b_id)
);

create unique index if not exists member_conversations_pair_context_idx
  on public.member_conversations (
    provider_a_id,
    provider_b_id,
    coalesce(opportunity_id, '00000000-0000-0000-0000-000000000000'::uuid)
  );

create table if not exists public.member_conversation_reads (
  conversation_id uuid not null references public.member_conversations(id) on delete cascade,
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (conversation_id, provider_id)
);

create table if not exists public.member_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.member_conversations(id) on delete cascade,
  sender_provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index if not exists member_messages_conversation_created_idx
  on public.member_messages(conversation_id, created_at);

create table if not exists public.member_deal_referrals (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references public.member_deal_opportunities(id) on delete cascade,
  referrer_provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  referred_provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  note text not null default '' check (char_length(note) <= 600),
  status text not null default 'sent' check (status in ('sent', 'viewed', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  unique (opportunity_id, referrer_provider_id, referred_provider_id),
  check (referrer_provider_id <> referred_provider_id)
);

alter table public.member_conversations enable row level security;
alter table public.member_conversation_reads enable row level security;
alter table public.member_messages enable row level security;
alter table public.member_deal_referrals enable row level security;

create or replace function public.current_affinity_provider_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select provider.id
  from public.provider_profiles provider
  where provider.owner_user_id = auth.uid()
    and provider.verified = true
    and provider.membership_status in ('active', 'trialing')
    and provider.onboarding_status = 'verified'
  limit 1;
$$;

revoke all on function public.current_affinity_provider_id() from public, anon;
grant execute on function public.current_affinity_provider_id() to authenticated;

create or replace function public.start_member_conversation(
  target_provider_id uuid,
  target_opportunity_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  sender_id uuid := public.current_affinity_provider_id();
  first_id uuid;
  second_id uuid;
  result_id uuid;
begin
  if sender_id is null then raise exception 'Verified member access required'; end if;
  if sender_id = target_provider_id then raise exception 'You cannot message yourself'; end if;
  if not exists (
    select 1 from public.provider_profiles provider
    where provider.id = target_provider_id
      and provider.verified = true
      and provider.is_example = false
      and provider.membership_status in ('active', 'trialing')
  ) then raise exception 'That member is not available for messaging'; end if;
  if target_opportunity_id is not null and not exists (
    select 1 from public.member_deal_opportunities opportunity
    where opportunity.id = target_opportunity_id and opportunity.status = 'published'
  ) then raise exception 'Reviewed opportunity not found'; end if;

  if sender_id::text < target_provider_id::text then
    first_id := sender_id; second_id := target_provider_id;
  else
    first_id := target_provider_id; second_id := sender_id;
  end if;

  insert into public.member_conversations(provider_a_id, provider_b_id, opportunity_id)
  values (first_id, second_id, target_opportunity_id)
  on conflict do nothing;

  select conversation.id into result_id
  from public.member_conversations conversation
  where conversation.provider_a_id = first_id
    and conversation.provider_b_id = second_id
    and conversation.opportunity_id is not distinct from target_opportunity_id;

  insert into public.member_conversation_reads(conversation_id, provider_id)
  values (result_id, sender_id), (result_id, target_provider_id)
  on conflict do nothing;
  return result_id;
end;
$$;

grant execute on function public.start_member_conversation(uuid, uuid) to authenticated;

create or replace function public.list_member_conversations()
returns table (
  conversation_id uuid,
  other_provider_id uuid,
  other_name text,
  other_company text,
  other_job_title text,
  other_provider_type text,
  other_photo_index integer,
  other_photo_url text,
  opportunity_id uuid,
  opportunity_headline text,
  last_message text,
  last_message_at timestamptz,
  unread_count bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare member_id uuid := public.current_affinity_provider_id();
begin
  if member_id is null then raise exception 'Verified member access required'; end if;
  return query
  select conversation.id,
         other.id,
         other.display_name,
         other.company_name,
         other.job_title,
         other.provider_type,
         other.photo_index,
         other.logo_object_key,
         opportunity.id,
         opportunity.headline,
         coalesce(latest.body, ''),
         coalesce(latest.created_at, conversation.last_message_at),
         count(unread.id)
  from public.member_conversations conversation
  join public.provider_profiles other
    on other.id = case when conversation.provider_a_id = member_id
      then conversation.provider_b_id else conversation.provider_a_id end
  left join public.member_deal_opportunities opportunity on opportunity.id = conversation.opportunity_id
  left join lateral (
    select message.body, message.created_at
    from public.member_messages message
    where message.conversation_id = conversation.id
    order by message.created_at desc limit 1
  ) latest on true
  left join public.member_conversation_reads reading
    on reading.conversation_id = conversation.id and reading.provider_id = member_id
  left join public.member_messages unread
    on unread.conversation_id = conversation.id
   and unread.sender_provider_id <> member_id
   and unread.created_at > coalesce(reading.last_read_at, '-infinity'::timestamptz)
  where member_id in (conversation.provider_a_id, conversation.provider_b_id)
  group by conversation.id, other.id, opportunity.id, latest.body, latest.created_at
  order by (count(unread.id) > 0) desc,
           coalesce(latest.created_at, conversation.last_message_at) desc;
end;
$$;

grant execute on function public.list_member_conversations() to authenticated;

create or replace function public.load_member_messages(target_conversation_id uuid)
returns table (
  id uuid,
  sender_provider_id uuid,
  sender_name text,
  body text,
  created_at timestamptz,
  is_mine boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare member_id uuid := public.current_affinity_provider_id();
begin
  if not exists (
    select 1 from public.member_conversations conversation
    where conversation.id = target_conversation_id
      and member_id in (conversation.provider_a_id, conversation.provider_b_id)
  ) then raise exception 'Conversation access denied'; end if;
  return query
  select message.id, message.sender_provider_id, sender.display_name,
         message.body, message.created_at, message.sender_provider_id = member_id
  from public.member_messages message
  join public.provider_profiles sender on sender.id = message.sender_provider_id
  where message.conversation_id = target_conversation_id
  order by message.created_at;
end;
$$;

grant execute on function public.load_member_messages(uuid) to authenticated;

create or replace function public.mark_member_conversation_read(target_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare member_id uuid := public.current_affinity_provider_id();
begin
  if not exists (
    select 1 from public.member_conversations conversation
    where conversation.id = target_conversation_id
      and member_id in (conversation.provider_a_id, conversation.provider_b_id)
  ) then raise exception 'Conversation access denied'; end if;
  insert into public.member_conversation_reads(conversation_id, provider_id, last_read_at)
  values (target_conversation_id, member_id, now())
  on conflict (conversation_id, provider_id) do update set last_read_at = excluded.last_read_at;
end;
$$;

grant execute on function public.mark_member_conversation_read(uuid) to authenticated;

create or replace function public.send_member_message(
  target_conversation_id uuid,
  message_body text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  member_id uuid := public.current_affinity_provider_id();
  recipient public.provider_profiles;
  sender_name text;
  message_id uuid;
begin
  if char_length(trim(message_body)) not between 1 and 2000 then
    raise exception 'Messages must contain 1–2000 characters';
  end if;
  select other.* into recipient
  from public.member_conversations conversation
  join public.provider_profiles other
    on other.id = case when conversation.provider_a_id = member_id
      then conversation.provider_b_id else conversation.provider_a_id end
  where conversation.id = target_conversation_id
    and member_id in (conversation.provider_a_id, conversation.provider_b_id);
  if recipient.id is null then raise exception 'Conversation access denied'; end if;

  insert into public.member_messages(conversation_id, sender_provider_id, body)
  values (target_conversation_id, member_id, trim(message_body)) returning id into message_id;
  update public.member_conversations set last_message_at = now() where id = target_conversation_id;
  insert into public.member_conversation_reads(conversation_id, provider_id, last_read_at)
  values (target_conversation_id, member_id, now())
  on conflict (conversation_id, provider_id) do update set last_read_at = excluded.last_read_at;

  select display_name into sender_name from public.provider_profiles where id = member_id;
  perform public.create_affinity_notification(
    recipient.owner_user_id, 'message', 'New message from ' || coalesce(sender_name, 'an Affinity member'),
    left(trim(message_body), 180), 'member-studio', 'conversation', target_conversation_id
  );
  return message_id;
end;
$$;

grant execute on function public.send_member_message(uuid, text) to authenticated;

create or replace function public.refer_member_to_deal(
  target_opportunity_id uuid,
  target_provider_id uuid,
  referral_note text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  member_id uuid := public.current_affinity_provider_id();
  opportunity public.member_deal_opportunities;
  target public.provider_profiles;
  referral_id uuid;
begin
  if member_id is null then raise exception 'Verified member access required'; end if;
  if member_id = target_provider_id then raise exception 'Choose another member to refer'; end if;
  select * into opportunity from public.member_deal_opportunities
  where id = target_opportunity_id and status = 'published';
  select * into target from public.provider_profiles
  where id = target_provider_id and verified = true and is_example = false;
  if opportunity.id is null then raise exception 'Reviewed opportunity not found'; end if;
  if target.id is null then raise exception 'Verified member not found'; end if;
  if exists (
    select 1 from public.deal_room_members member
    where member.deal_room_id = opportunity.deal_room_id
      and member.provider_id = target.id
      and member.status = 'accepted'
  ) then raise exception 'That member is already part of this deal team'; end if;
  if exists (
    select 1
    from public.deal_room_members member
    join public.provider_profiles teammate on teammate.id = member.provider_id
    where member.deal_room_id = opportunity.deal_room_id
      and member.status = 'accepted'
      and teammate.provider_type = target.provider_type
      and teammate.id <> target.id
  ) then raise exception 'That professional role is already filled on this deal'; end if;

  insert into public.member_deal_referrals(
    opportunity_id, referrer_provider_id, referred_provider_id, note, status
  ) values (
    opportunity.id, member_id, target.id, trim(referral_note), 'sent'
  )
  on conflict (opportunity_id, referrer_provider_id, referred_provider_id)
  do update set note = excluded.note, status = 'sent', created_at = now(), responded_at = null
  returning id into referral_id;

  perform public.create_affinity_notification(
    target.owner_user_id, 'referral', 'A member referred you to a deal',
    opportunity.headline, 'member-studio', 'opportunity', opportunity.id
  );
  perform public.create_affinity_notification(
    opportunity.owner_user_id, 'referral', 'A professional was referred to your deal',
    target.display_name || ' · ' || coalesce(target.job_title, target.provider_type),
    'member-studio', 'opportunity', opportunity.id
  );
  return referral_id;
end;
$$;

grant execute on function public.refer_member_to_deal(uuid, uuid, text) to authenticated;
