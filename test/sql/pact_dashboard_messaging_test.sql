-- Wrap in BEGIN ... ROLLBACK. Fixture accounts and all messages are temporary.
do $$
declare buyer uuid:=gen_random_uuid(); seller uuid:=gen_random_uuid(); member uuid:=gen_random_uuid(); peer uuid:=gen_random_uuid();
 provider uuid:=gen_random_uuid(); peer_provider uuid:=gen_random_uuid(); tid uuid; draft uuid; mid uuid:=gen_random_uuid(); result jsonb; rows jsonb;
begin
 insert into auth.users(id,email,raw_user_meta_data) values
 (buyer,'pact-test-'||buyer::text||'@example.invalid',jsonb_build_object('full_name','Buyer fixture','username','b'||left(replace(buyer::text,'-',''),15))),
 (seller,'pact-test-'||seller::text||'@example.invalid',jsonb_build_object('full_name','Seller fixture','username','s'||left(replace(seller::text,'-',''),15))),
 (member,'pact-test-'||member::text||'@example.invalid',jsonb_build_object('full_name','Member fixture','username','m'||left(replace(member::text,'-',''),15))),
 (peer,'pact-test-'||peer::text||'@example.invalid',jsonb_build_object('full_name','Peer fixture','username','p'||left(replace(peer::text,'-',''),15)));
 insert into public.profiles(id,full_name) values(buyer,'Buyer fixture'),(seller,'Seller fixture'),(member,'Member fixture'),(peer,'Peer fixture') on conflict(id) do nothing;
 insert into public.provider_profiles(id,owner_user_id,provider_type,display_name,company_name,verified,onboarding_status) values
 (provider,member,'accountant','Member fixture','Test',true,'verified'),(peer_provider,peer,'lawyer','Peer fixture','Test',true,'verified');
 perform set_config('request.jwt.claim.sub',member::text,true);
 set local role authenticated;
 -- Even a raw call with a known customer ID must fail; UI hiding is insufficient.
 begin
  perform public.pact_messaging('create',jsonb_build_object('id',gen_random_uuid(),'title','Forbidden','recipients',jsonb_build_array(buyer)));
  raise exception 'TEST_FAIL: member initiated contact to buyer';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 begin
  perform public.pact_messaging('create',jsonb_build_object('id',gen_random_uuid(),'title','Forbidden','recipients',jsonb_build_array(seller)));
  raise exception 'TEST_FAIL: member initiated contact to seller';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 perform set_config('request.jwt.claim.sub',buyer::text,true);
 tid:=gen_random_uuid();
 result:=public.pact_messaging('open_member',jsonb_build_object('id',tid,'provider_id',provider,'context','buyer'));
 if (result->>'id')::uuid<>tid then raise exception 'TEST_FAIL: buyer opens member conversation'; end if;
 result:=public.pact_messaging('open_member',jsonb_build_object('id',gen_random_uuid(),'provider_id',provider,'context','seller'));
 if (result->>'id')::uuid<>tid then raise exception 'TEST_FAIL: duplicate direct thread'; end if;
 perform set_config('request.jwt.claim.sub',member::text,true);
 rows:=public.pact_messaging('list','{}');
 if exists(select 1 from jsonb_array_elements(rows) r where r->>'id'=tid::text) then raise exception 'TEST_FAIL: empty draft notified member'; end if;
 -- Accepting an empty request through a raw API still cannot allow a first reply.
 perform public.pact_messaging('respond',jsonb_build_object('thread_id',tid,'status','accepted'));
 begin
  perform public.pact_messaging('send',jsonb_build_object('thread_id',tid,'id',gen_random_uuid(),'body','Unsolicited'));
  raise exception 'TEST_FAIL: member sent before customer message';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 -- User-editable profile labels cannot turn off the reply restriction.
 update public.profiles set account_role='user' where id=member;
 update public.provider_profiles set is_example=true where id=provider;
 begin
  perform public.pact_messaging('send',jsonb_build_object('thread_id',tid,'id',gen_random_uuid(),'body','Spoofed'));
  raise exception 'TEST_FAIL: editable role/example field bypass';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 update public.provider_profiles set is_example=false where id=provider;
 perform set_config('request.jwt.claim.sub',buyer::text,true);
 perform public.pact_messaging('send',jsonb_build_object('thread_id',tid,'id',mid,'body','Please help with my purchase'));
 perform public.pact_messaging('send',jsonb_build_object('thread_id',tid,'id',mid,'body','Please help with my purchase'));
 rows:=public.pact_messaging('messages',jsonb_build_object('thread_id',tid));
 if jsonb_array_length(rows)<>1 then raise exception 'TEST_FAIL: retry duplicate'; end if;
 perform set_config('request.jwt.claim.sub',member::text,true);
 perform public.pact_messaging('send',jsonb_build_object('thread_id',tid,'id',gen_random_uuid(),'body','Happy to help'));
 -- Seller sends the first request message before the member accepts.
 perform set_config('request.jwt.claim.sub',seller::text,true);
 draft:=gen_random_uuid();
 perform public.pact_messaging('open_member',jsonb_build_object('id',draft,'provider_id',provider,'context','seller'));
 mid:=gen_random_uuid();
 perform public.pact_messaging('send',jsonb_build_object('thread_id',draft,'id',mid,'body','Selling my business'));
 perform public.pact_messaging('send',jsonb_build_object('thread_id',draft,'id',mid,'body','Selling my business'));
 begin
  perform public.pact_messaging('send',jsonb_build_object('thread_id',draft,'id',gen_random_uuid(),'body','Second request before consent'));
  raise exception 'TEST_FAIL: repeated unsolicited request';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 perform set_config('request.jwt.claim.sub',member::text,true);
 rows:=public.pact_messaging('messages',jsonb_build_object('thread_id',draft));
 if jsonb_array_length(rows)<>1 then raise exception 'TEST_FAIL: member cannot read incoming request'; end if;
 begin
  perform public.pact_messaging('send',jsonb_build_object('thread_id',draft,'id',gen_random_uuid(),'body','Reply without acceptance'));
  raise exception 'TEST_FAIL: pending request replied';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 perform public.pact_messaging('respond',jsonb_build_object('thread_id',draft,'status','accepted'));
 perform public.pact_messaging('send',jsonb_build_object('thread_id',draft,'id',gen_random_uuid(),'body','Let us discuss the sale'));
 -- An unrelated account cannot read another person's conversation.
 perform set_config('request.jwt.claim.sub',peer::text,true);
 begin
  perform public.pact_messaging('messages',jsonb_build_object('thread_id',tid));
  raise exception 'TEST_FAIL: outsider read';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 -- Members can still contact other eligible members.
 perform set_config('request.jwt.claim.sub',member::text,true);
 perform public.pact_messaging('open_member',jsonb_build_object('id',gen_random_uuid(),'provider_id',peer_provider,'context','member'));
 -- Blocking closes reply rights.
 perform public.pact_messaging('block',jsonb_build_object('thread_id',tid,'user_id',buyer));
 perform set_config('request.jwt.claim.sub',buyer::text,true);
 begin
  perform public.pact_messaging('send',jsonb_build_object('thread_id',tid,'id',gen_random_uuid(),'body','Blocked'));
  raise exception 'TEST_FAIL: blocked send';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 reset role;
 if has_function_privilege('authenticated','public.start_member_conversation(uuid,uuid)','execute') or has_function_privilege('authenticated','public.send_member_message(uuid,text)','execute') then raise exception 'TEST_FAIL: legacy inbox still writable'; end if;
end $$;
select 'PASS: buyer/seller initiation, member replies only, raw API/role-spoof prevention, requests, duplicate retries, direct-thread reuse, privacy, member networking and blocking' as result;
