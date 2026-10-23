-- Execute inside BEGIN ... ROLLBACK. No persistent fixture data.
do $$
declare seller uuid:=gen_random_uuid(); stranger uuid:=gen_random_uuid(); buyer uuid:=gen_random_uuid();
 listing uuid:=gen_random_uuid(); hidden uuid:=gen_random_uuid(); result jsonb;
begin
 insert into auth.users(id,email) values
 (seller,'mobile-test-'||seller||'@example.invalid'),(stranger,'mobile-test-'||stranger||'@example.invalid'),(buyer,'mobile-test-'||buyer||'@example.invalid');
 insert into public.business_sale_bulletins(id,created_by_user_id,title,summary) values
 (listing,seller,'Seller fixture','A temporary listing used to test owner-only analytics.'),
 (hidden,stranger,'Other fixture','A temporary listing used to test owner-only analytics.');
 insert into public.saved_business_sale_bulletins(user_id,bulletin_id,saved_at) values
 (buyer,listing,now()),(buyer,hidden,now());
 perform set_config('request.jwt.claim.sub',seller::text,true);
 set local role authenticated;
 result:=public.pact_seller_listing_insights(7);
 if jsonb_array_length(result)<>1 or result->0->>'listing_id'<>listing::text
   or (result->0->'daily_saves'->0->>'count')::integer<>1 then raise exception 'Owner totals or isolation failed: %',result; end if;
 begin
  perform public.pact_seller_listing_insights(10000);
  raise exception 'TEST_FAIL: unbounded interval accepted';
 exception when others then if sqlerrm like 'TEST_FAIL:%' then raise; end if; end;
 perform set_config('request.jwt.claim.sub',buyer::text,true);
 if public.pact_seller_listing_insights(7)<>'[]'::jsonb then raise exception 'Buyer saw someone else analytics'; end if;
 perform set_config('request.jwt.claim.sub','',true);
 begin
  perform public.pact_seller_listing_insights(7);
  raise exception 'TEST_FAIL: missing identity accepted';
 exception when insufficient_privilege then null; end;
 reset role;
 if has_function_privilege('anon','public.pact_seller_listing_insights(integer)','execute') then raise exception 'Anonymous analytics permission'; end if;
end $$;
