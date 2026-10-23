-- Run inside BEGIN ... ROLLBACK: no saved content or real profiles are changed.
do $$
declare customer uuid:=gen_random_uuid(); expert uuid:=gen_random_uuid(); other uuid:=gen_random_uuid(); admin uuid:=gen_random_uuid();
 p1 uuid:=gen_random_uuid(); p2 uuid:=gen_random_uuid(); criteria jsonb; rows jsonb; profile_stamp timestamptz; background jsonb;
begin
 insert into auth.users(id,email) values(customer,'match-test-'||customer||'@example.invalid'),(expert,'match-test-'||expert||'@example.invalid'),(other,'match-test-'||other||'@example.invalid'),(admin,'match-test-'||admin||'@example.invalid');
 insert into public.profiles(id,full_name) values(customer,'Customer'),(expert,'Expert'),(other,'Other'),(admin,'Reviewer') on conflict(id) do nothing;
 insert into public.affinity_admins(user_id,role) values(admin,'owner');
 background:='{"services":["financial_due_diligence"],"industries":["hospitality"],"transaction_types":["business_acquisition"],"jurisdictions":["CA-BC"],"currency":"CAD","deal_min":500000,"deal_max":2000000,"availability":"accepting","employment":[{"title":"Partner","organization":"Test practice","start_year":"2015","end_year":"","description":"Transaction work"}],"credentials":[{"title":"CPA","kind":"designation","issuer":"Test regulator","number":"test-123","jurisdiction":"CA-BC","expires_on":"2030-01-01"}]}';
 insert into public.provider_profiles(id,owner_user_id,provider_type,display_name,company_name,verified,membership_status,is_example,professional_background)
 values(p1,expert,'accountant','Relevant expert','Test',true,'active',false,background),
 (p2,other,'accountant','Keyword-heavy profile','Test',true,'active',false,'{"services":["tax_planning"],"industries":["retail"],"transaction_types":["business_sale"],"jurisdictions":["CA-BC"],"availability":"accepting","currency":"CAD","deal_min":1,"deal_max":2}');
 update public.provider_profiles set description=repeat('hospitality financial_due_diligence business_acquisition ',60),membership_tier='featured' where id=p2;
 criteria:='{"profession":"accountant","service":"financial_due_diligence","industry":"hospitality","transaction_type":"business_acquisition","currency":"CAD","amount":1000000,"jurisdiction":"CA-BC","require_credential":false}';
 perform set_config('request.jwt.claim.sub',customer::text,true);
 set local role authenticated;
 rows:=public.pact_professional_matches(criteria);
 if not exists(select 1 from jsonb_array_elements(rows) r where r->'provider'->>'id'=p1::text and (r->>'score')::int=100 and (r->>'eligible')::boolean) then raise exception 'TEST_FAIL: complete relevant expert not ranked correctly %',rows; end if;
 if exists(select 1 from jsonb_array_elements(rows) r where r->'provider'->>'id'=p2::text and (r->>'score')::int>10) then raise exception 'TEST_FAIL: About text or paid tier boosted ranking'; end if;
 rows:=public.pact_professional_matches(criteria||'{"jurisdiction":"CA-ON"}');
 if exists(select 1 from jsonb_array_elements(rows) r where r->'provider'->>'id'=p1::text and (r->>'eligible')::boolean) then raise exception 'TEST_FAIL: wrong jurisdiction recommended'; end if;
 rows:=public.pact_professional_matches(criteria||'{"require_credential":true}');
 if exists(select 1 from jsonb_array_elements(rows) r where (r->>'eligible')::boolean) then raise exception 'TEST_FAIL: unverified claim qualified'; end if;
 perform set_config('request.jwt.claim.sub',expert::text,true);
 select updated_at into profile_stamp from public.provider_profiles where id=p1;
 begin
  perform public.pact_verify_professional_credential(p1,0,profile_stamp,true);
  raise exception 'TEST_FAIL: owner verified credential';
 exception when insufficient_privilege then null; end;
 begin
  update public.provider_profiles set professional_background=background||'{"verified":true}' where id=p1;
  raise exception 'TEST_FAIL: forged verification field saved';
 exception when check_violation then null; end;
 begin
  perform public.pact_save_profile(jsonb_build_object('full_name','Expert','professional_background',background),now()-interval '1 day');
  raise exception 'TEST_FAIL: stale profile overwrote background';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 perform public.pact_save_profile(jsonb_build_object('full_name','Expert','professional_background',background,'bio','Preserved account biography'));
 reset role;
 if (select bio from public.profiles where id=expert)<>'Preserved account biography' or (select description from public.provider_profiles where id=p1)<>'Preserved account biography' then raise exception 'TEST_FAIL: shared profile identity sync'; end if;
 perform set_config('request.jwt.claim.sub',admin::text,true);
 set local role authenticated;
 select updated_at into profile_stamp from public.provider_profiles where id=p1;
 perform public.pact_verify_professional_credential(p1,0,profile_stamp,true);
 rows:=public.pact_professional_credentials(p1);
 if jsonb_array_length(rows)<>1 then raise exception 'TEST_FAIL: verified credential unavailable'; end if;
 perform set_config('request.jwt.claim.sub',customer::text,true);
 rows:=public.pact_professional_matches(criteria||'{"require_credential":true}');
 if not exists(select 1 from jsonb_array_elements(rows) r where r->'provider'->>'id'=p1::text and (r->>'eligible')::boolean) then raise exception 'TEST_FAIL: valid credential did not qualify'; end if;
 reset role;
 -- A previously reviewed accountant designation cannot qualify a legal profile.
 update public.provider_profiles set provider_type='lawyer' where id=p1;
 if public.pact_professional_credentials(p1)<>'[]'::jsonb then raise exception 'TEST_FAIL: verification survived profession change'; end if;
 perform set_config('request.jwt.claim.sub',admin::text,true);
 set local role authenticated;
 select updated_at into profile_stamp from public.provider_profiles where id=p1;
 perform public.pact_verify_professional_credential(p1,0,profile_stamp,true);
 perform set_config('request.jwt.claim.sub',customer::text,true);
 rows:=public.pact_professional_matches(criteria||'{"profession":"lawyer","require_credential":true}');
 if exists(select 1 from jsonb_array_elements(rows) r where r->'provider'->>'id'=p1::text and (r->>'eligible')::boolean) then raise exception 'TEST_FAIL: designation substituted for professional licence'; end if;
 reset role;
 update public.provider_profiles set provider_type='accountant' where id=p1;
 perform set_config('request.jwt.claim.sub',expert::text,true);
 set local role authenticated;
 perform set_config('request.jwt.claim.sub',expert::text,true);
 update public.provider_profiles set professional_background=jsonb_set(professional_background,'{credentials,0,number}','"changed"') where id=p1;
 if public.pact_professional_credentials(p1)<>'[]'::jsonb then raise exception 'TEST_FAIL: changed claim inherited verification'; end if;
 reset role;
 if pact_private.valid_professional_background('{"credentials":[{"title":"Fake","issuer":"Test","jurisdiction":"CA-BC","verified":true}]}') then raise exception 'TEST_FAIL: nested verification accepted'; end if;
 if pact_private.valid_professional_background('{"credentials":[{"title":"Fake","issuer":"Test","jurisdiction":"CA-BC","expires_on":"tomorrow"}]}') then raise exception 'TEST_FAIL: relative expiry accepted'; end if;
 if has_function_privilege('anon','public.pact_professional_matches(jsonb)','EXECUTE') or has_table_privilege('authenticated','pact_private.professional_credentials','INSERT') then raise exception 'TEST_FAIL: excess privileges'; end if;
 set local role anon;
 perform public.pact_professional_credentials(p1);
 reset role;
end $$;
