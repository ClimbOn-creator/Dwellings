begin;
select set_config('friends.test.a',gen_random_uuid()::text,true);
select set_config('friends.test.b',gen_random_uuid()::text,true);
select set_config('friends.test.c',gen_random_uuid()::text,true);
select set_config('friends.test.d',gen_random_uuid()::text,true);
insert into auth.users(id,email,raw_user_meta_data)
select current_setting('friends.test.'||k)::uuid,'friend-'||current_setting('friends.test.'||k)||'@example.invalid','{}'::jsonb from unnest(array['a','b','c','d']) k;
insert into public.account_workspaces(user_id,role)
select current_setting('friends.test.'||k)::uuid,case when k='d' then 'buyer' else 'member' end from unnest(array['a','b','c','d']) k;
update public.profiles set full_name='Temporary Friends fixture',bio='Temporary public introduction' where id in
(current_setting('friends.test.a')::uuid,current_setting('friends.test.b')::uuid,current_setting('friends.test.c')::uuid);
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('friends.test.a'),'role','authenticated')::text,true);
set local role authenticated;
select public.pact_friend_action(current_setting('friends.test.b')::uuid,'request');
select public.pact_friend_action(current_setting('friends.test.b')::uuid,'request');
do $$ declare result jsonb; begin
 if (select count(*) from public.member_friendships)<>1 then raise exception 'Duplicate relationships created'; end if;
 begin
  perform public.pact_friend_action(current_setting('friends.test.b')::uuid,'accept');
  raise exception 'Sender accepted own request';
 exception when raise_exception then if sqlerrm='Sender accepted own request' then raise; end if; end;
 begin
  perform public.pact_friend_action(auth.uid(),'request');
  raise exception 'Self friendship accepted';
 exception when raise_exception then if sqlerrm='Self friendship accepted' then raise; end if; end;
 begin
  perform public.pact_friend_action(current_setting('friends.test.d')::uuid,'request');
  raise exception 'Buyer accepted as member friend';
 exception when raise_exception then if sqlerrm='Buyer accepted as member friend' then raise; end if; end;
 begin
  update public.member_friendships set status='accepted',accepted_at=now();
  raise exception 'Direct friendship update accepted';
 exception when insufficient_privilege then null; end;
 result:=public.pact_friend_people('requests','',null,0);
 if (select count(*) from jsonb_array_elements(result->'people') p where p->>'user_id'=current_setting('friends.test.b') and p->>'incoming'='false')<>1 then raise exception 'Outgoing request missing'; end if;
 if result::text like '%email%' or result::text like '%username%' then raise exception 'Private fields exposed'; end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('friends.test.b'),'role','authenticated')::text,true);
set local role authenticated;
select public.pact_friend_action(current_setting('friends.test.a')::uuid,'request');
do $$ begin
 if exists(select 1 from public.member_friendships where status='accepted') then raise exception 'Crossed requests silently accepted'; end if;
end $$;
select public.pact_friend_action(current_setting('friends.test.a')::uuid,'accept');
do $$ declare result jsonb; begin
 result:=public.pact_friend_people('friends','',null,0);
 if not exists(select 1 from jsonb_array_elements(result->'people') p where p->>'user_id'=current_setting('friends.test.a') and p->>'status'='accepted') then raise exception 'Recipient profile missing mutual friend'; end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('friends.test.c'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin
 if exists(select 1 from public.member_friendships) then raise exception 'Friendships exposed to outsider'; end if;
 begin
  perform public.pact_friend_action(current_setting('friends.test.a')::uuid,'accept');
  raise exception 'Outsider accepted a request';
 exception when raise_exception then if sqlerrm='Outsider accepted a request' then raise; end if; end;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('friends.test.a'),'role','authenticated')::text,true);
set local role authenticated;
do $$ declare result jsonb; begin
 result:=public.pact_friend_people('friends','',null,0);
 if not exists(select 1 from jsonb_array_elements(result->'people') p where p->>'user_id'=current_setting('friends.test.b') and p->>'status'='accepted') then raise exception 'Sender profile missing mutual friend'; end if;
end $$;
select public.pact_friend_action(current_setting('friends.test.b')::uuid,'remove');
select public.pact_friend_action(current_setting('friends.test.b')::uuid,'request');
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('friends.test.b'),'role','authenticated')::text,true);
set local role authenticated;
select public.pact_friend_action(current_setting('friends.test.a')::uuid,'decline');
do $$ begin
 if exists(select 1 from public.member_friendships) then raise exception 'Removal or decline did not clear both profiles'; end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('friends.test.d'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin
 begin
  perform public.pact_friend_people('discover','',null,0);
  raise exception 'Buyer accessed member directory';
 exception when raise_exception then if sqlerrm='Buyer accessed member directory' then raise; end if; end;
end $$;
reset role;
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ begin
 begin perform public.pact_friend_people(); raise exception 'Anonymous directory access'; exception when insufficient_privilege then null; end;
 begin perform * from public.member_friendships; raise exception 'Anonymous friendship access'; exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'PASS: recipient consent, both profile lists, duplicate protection, member-only discovery, private field filtering, outsider denial, decline and mutual removal' as result;
