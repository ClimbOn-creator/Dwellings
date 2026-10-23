-- Private per-account invalidation events; never broadcast message text.
create policy pact_account_message_events on realtime.messages
for select to authenticated using (
 (select realtime.topic()) = 'pact:user:' || (select auth.uid())::text
 and topic = 'pact:user:' || (select auth.uid())::text
 and extension='broadcast'
);
create function pact_private.notify_message_change()
returns trigger language plpgsql security definer set search_path='' as $$
declare participant uuid;
begin
 if tg_table_name='pact_thread_members' and tg_op='UPDATE' then
  if new.status=old.status and new.last_read_sequence=old.last_read_sequence then return new; end if;
 end if;
 for participant in select user_id from public.pact_thread_members where thread_id=new.thread_id and status in ('accepted','pending') loop
  perform realtime.send(jsonb_build_object('thread_id',new.thread_id),'changed','pact:user:'||participant::text,true);
 end loop;
 return new;
end $$;
revoke all on function pact_private.notify_message_change() from public,anon,authenticated;
create trigger pact_message_changed after insert on public.pact_messages for each row execute function pact_private.notify_message_change();
create trigger pact_membership_changed after insert or update on public.pact_thread_members for each row execute function pact_private.notify_message_change();
