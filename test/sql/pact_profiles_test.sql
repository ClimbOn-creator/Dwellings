-- Run in BEGIN ... ROLLBACK; existing identities are restored with the rollback.
do $$
declare a uuid; b uuid; provider uuid; stamp timestamptz; image_id uuid:=gen_random_uuid(); out jsonb; n integer;
begin
 select owner_user_id,id into a,provider from public.provider_profiles where owner_user_id is not null limit 1;
 select id into b from auth.users where id<>a limit 1;
 if a is null or b is null then raise exception 'Two accounts and an owned profile required'; end if;
 select updated_at into stamp from public.profiles where id=a;
 perform set_config('request.jwt.claim.sub',a::text,true);
 set local role authenticated;
 out:=public.pact_save_profile(jsonb_build_object('full_name','Rollback professional','bio','Shared description','job_title','Adviser','company_name','Test firm','specialties',jsonb_build_array('Acquisitions','Tax'),'service_markets',jsonb_build_array('Vancouver')),stamp);
 if (select description from public.provider_profiles where id=provider)<>'Shared description' then raise exception 'TEST_FAIL: account to directory sync'; end if;
 if (select specialties from public.provider_profiles where id=provider)<>array['Acquisitions','Tax'] then raise exception 'TEST_FAIL: specialties'; end if;
 update public.provider_profiles set description='Edited on web' where id=provider;
 if (select bio from public.profiles where id=a)<>'Edited on web' then raise exception 'TEST_FAIL: directory to account sync'; end if;
 begin
  perform public.pact_save_profile(jsonb_build_object('full_name','Stale overwrite'), '2000-01-01'::timestamptz);
  raise exception 'TEST_FAIL: stale edit accepted';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 out:=public.pact_register_profile_media('cover',image_id,100);
 if (select profile_cover_url from public.profiles where id=a)<>out->>'url' then raise exception 'TEST_FAIL: cover account'; end if;
 if (select cover_photo_url from public.provider_profiles where id=provider)<>out->>'url' then raise exception 'TEST_FAIL: cover directory'; end if;
 if (select object_key from public.pact_profile_media where owner_id=a and slot='cover')<>'profiles/'||a::text||'/cover/'||image_id::text||'.png' then raise exception 'TEST_FAIL: image namespace'; end if;
 perform set_config('request.jwt.claim.sub',b::text,true);
 update public.profiles set bio='Unauthorized' where id=a;
 get diagnostics n=row_count;
 if n<>0 then raise exception 'TEST_FAIL: another account edit'; end if;
 begin
  insert into public.pact_profile_media(owner_id,slot,id,object_key,byte_size) values(a,'avatar',image_id,'invalid',10);
  raise exception 'TEST_FAIL: foreign image registration';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 reset role;
 if has_function_privilege('anon','public.pact_save_profile(jsonb,timestamptz)','execute') or has_function_privilege('anon','public.pact_register_profile_media(text,uuid,integer)','execute') then raise exception 'TEST_FAIL: anonymous mutation'; end if;
end $$;
select 'PASS: profile sync in both directions, specialties, stale save rejection, R2 metadata, owner isolation and anonymous restrictions' as result;
