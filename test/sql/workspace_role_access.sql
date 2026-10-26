begin;
-- Temporary auth fixtures; all data is rolled back, no email is sent.
select set_config('workspace.test.first',gen_random_uuid()::text,true);
select set_config('workspace.test.second',gen_random_uuid()::text,true);
insert into auth.users(id,email,raw_user_meta_data) values
(current_setting('workspace.test.first')::uuid,'workspace-first-'||current_setting('workspace.test.first')||'@example.invalid','{}'),
(current_setting('workspace.test.second')::uuid,'workspace-second-'||current_setting('workspace.test.second')||'@example.invalid','{}');
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('workspace.test.first'),'role','authenticated')::text,true);
set local role authenticated;
insert into public.account_workspaces(user_id,role) values(auth.uid(),'seller');
do $$ begin
 if (select role from public.account_workspaces where user_id=auth.uid()) <> 'seller' then raise exception 'Saved role not recognized'; end if;
 begin
  insert into public.account_workspaces(user_id,role) values(auth.uid(),'buyer');
  raise exception 'Second choice accepted';
 exception when unique_violation then null; end;
 begin
  update public.account_workspaces set role='buyer' where user_id=auth.uid();
  raise exception 'Role change accepted';
 exception when insufficient_privilege then null; end;
 begin
  delete from public.account_workspaces where user_id=auth.uid();
  raise exception 'Role reset accepted';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.account_workspaces(user_id,role) values(current_setting('workspace.test.second')::uuid,'member');
  raise exception 'Other account role accepted';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('workspace.test.second'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin
 if exists(select 1 from public.account_workspaces) then raise exception 'Other account role exposed'; end if;
 begin
  insert into public.account_workspaces(user_id,role) values(auth.uid(),'admin');
  raise exception 'Invalid role accepted';
 exception when check_violation then null; end;
end $$;
insert into public.account_workspaces(user_id,role) values(auth.uid(),'member');
reset role;
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ begin
 begin
  perform * from public.account_workspaces;
  raise exception 'Anonymous workspace access accepted';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'PASS: role persistence, first choice wins, no role changes/resets, account isolation, invalid roles and anonymous denial' as result;
