-- Account-backed message receipts and notification cleanup.
-- Conversations and messages already belong to provider_profiles, whose
-- owner_user_id ties them to the signed-in account on every device.

alter table public.member_messages
  add column if not exists read_at timestamptz;

-- Preserve useful receipts for conversations that were read before this
-- migration was installed. New receipts are written once and never moved.
update public.member_messages message
set read_at = reading.last_read_at
from public.member_conversation_reads reading
where reading.conversation_id = message.conversation_id
  and reading.provider_id <> message.sender_provider_id
  and reading.last_read_at >= message.created_at
  and message.read_at is null;

create or replace function public.load_member_messages_with_receipts(
  target_conversation_id uuid
)
returns table (
  id uuid,
  sender_provider_id uuid,
  sender_name text,
  body text,
  created_at timestamptz,
  is_mine boolean,
  read_at timestamptz
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
  select message.id,
         message.sender_provider_id,
         sender.display_name,
         message.body,
         message.created_at,
         message.sender_provider_id = member_id,
         case when message.sender_provider_id = member_id
           then message.read_at else null end
  from public.member_messages message
  join public.provider_profiles sender on sender.id = message.sender_provider_id
  where message.conversation_id = target_conversation_id
  order by message.created_at;
end;
$$;

revoke all on function public.load_member_messages_with_receipts(uuid) from public, anon;
grant execute on function public.load_member_messages_with_receipts(uuid) to authenticated;

create or replace function public.mark_member_conversation_read(target_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  member_id uuid := public.current_affinity_provider_id();
  viewed_at timestamptz := now();
begin
  if not exists (
    select 1 from public.member_conversations conversation
    where conversation.id = target_conversation_id
      and member_id in (conversation.provider_a_id, conversation.provider_b_id)
  ) then raise exception 'Conversation access denied'; end if;

  insert into public.member_conversation_reads(conversation_id, provider_id, last_read_at)
  values (target_conversation_id, member_id, viewed_at)
  on conflict (conversation_id, provider_id)
  do update set last_read_at = excluded.last_read_at;

  update public.member_messages
  set read_at = viewed_at
  where conversation_id = target_conversation_id
    and sender_provider_id <> member_id
    and read_at is null;

  update public.affinity_notifications
  set read_at = viewed_at
  where user_id = auth.uid()
    and notification_type = 'message'
    and entity_type = 'conversation'
    and entity_id = target_conversation_id
    and read_at is null;
end;
$$;

revoke all on function public.mark_member_conversation_read(uuid) from public, anon;
grant execute on function public.mark_member_conversation_read(uuid) to authenticated;

comment on function public.load_member_messages_with_receipts(uuid) is
  'Loads profile-owned conversation messages and exposes when the other member last read each outgoing message.';
