-- Run after the migration inside BEGIN ... ROLLBACK. No persistent test data.
do $$
declare a uuid; b uuid; outsider uuid := gen_random_uuid(); t uuid:=gen_random_uuid(); m uuid:=gen_random_uuid(); r jsonb;
begin
 select owner_user_id into a from public.provider_profiles where verified and not is_example and membership_status in ('active','trialing') and owner_user_id is not null order by id limit 1;
 select owner_user_id into b from public.provider_profiles where owner_user_id<>a and verified and not is_example and membership_status in ('active','trialing') order by id limit 1;
 if a is null or b is null then raise exception 'Two available member accounts required'; end if;
 perform set_config('request.jwt.claim.sub',a::text,true);
 set local role authenticated;
 r:=public.pact_messaging('create',jsonb_build_object('id',t,'title','Rollback test','recipients',jsonb_build_array(b)));
 r:=public.pact_messaging('send',jsonb_build_object('thread_id',t,'id',m,'body','hello'));
 if (r->>'sequence')::int<>1 then raise exception 'TEST_FAIL: first request message'; end if;
 perform set_config('request.jwt.claim.sub',b::text,true);
 r:=public.pact_messaging('messages',jsonb_build_object('thread_id',t));
 if jsonb_array_length(r)<>1 then raise exception 'TEST_FAIL: request preview'; end if;
 perform public.pact_messaging('respond',jsonb_build_object('thread_id',t,'status','accepted'));
 perform set_config('request.jwt.claim.sub',a::text,true);
 r:=public.pact_messaging('send',jsonb_build_object('thread_id',t,'id',m,'body','hello'));
 if (r->>'sequence')::int<>1 then raise exception 'TEST_FAIL: sequence'; end if;
 r:=public.pact_messaging('send',jsonb_build_object('thread_id',t,'id',m,'body','hello'));
 r:=public.pact_messaging('messages',jsonb_build_object('thread_id',t));
 if jsonb_array_length(r)<>1 then raise exception 'TEST_FAIL: duplicate retry'; end if;
 begin
  perform public.pact_messaging('send',jsonb_build_object('thread_id',t,'id',m,'body','changed'));
  raise exception 'TEST_FAIL: changed idempotent body accepted';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 perform set_config('request.jwt.claim.sub',b::text,true);
 perform public.pact_messaging('read',jsonb_build_object('thread_id',t,'sequence',1));
 begin
  perform public.pact_messaging('read',jsonb_build_object('thread_id',t,'sequence',999));
  raise exception 'TEST_FAIL: advanced read beyond displayed history';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 perform public.pact_messaging('leave',jsonb_build_object('thread_id',t));
 begin
  perform public.pact_messaging('messages',jsonb_build_object('thread_id',t));
  raise exception 'TEST_FAIL: former member access';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 perform set_config('request.jwt.claim.sub',outsider::text,true);
 begin
  perform public.pact_messaging('messages',jsonb_build_object('thread_id',t));
  raise exception 'TEST_FAIL: invalid account access';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 reset role;
 if has_function_privilege('anon','public.pact_messaging(text,jsonb)','execute') then raise exception 'TEST_FAIL: anonymous RPC'; end if;
 if has_table_privilege('authenticated','public.pact_messages','select') then raise exception 'TEST_FAIL: raw table access'; end if;
end $$;
select 'PASS: requests, authorization, retry deduplication, payload conflict, read bounds, removed member, anonymous/direct access' as result;
