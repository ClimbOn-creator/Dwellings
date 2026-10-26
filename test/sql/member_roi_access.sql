begin;
select set_config('roi.test.a',gen_random_uuid()::text,true);
select set_config('roi.test.b',gen_random_uuid()::text,true);
select set_config('roi.test.c',gen_random_uuid()::text,true);
select set_config('roi.test.p',gen_random_uuid()::text,true);
select set_config('roi.test.q',gen_random_uuid()::text,true);
select set_config('roi.test.lead',gen_random_uuid()::text,true);
select set_config('roi.test.foreignlead',gen_random_uuid()::text,true);
select set_config('roi.test.outcome',gen_random_uuid()::text,true);
insert into auth.users(id,email,raw_user_meta_data)select current_setting('roi.test.'||v)::uuid,'roi-'||current_setting('roi.test.'||v)||'@example.invalid','{}'::jsonb from unnest(array['a','b','c'])v;
insert into public.account_workspaces(user_id,role)select current_setting('roi.test.'||v)::uuid,case when v='c' then 'buyer' else 'member' end from unnest(array['a','b','c'])v;
insert into public.provider_profiles(id,owner_user_id,provider_type,display_name,company_name,verified)values
(current_setting('roi.test.p')::uuid,current_setting('roi.test.a')::uuid,'accountant','Temporary ROI professional','Fixture',true),
(current_setting('roi.test.q')::uuid,current_setting('roi.test.b')::uuid,'accountant','Other ROI professional','Fixture',true);
insert into public.lead_requests(id,user_id,provider_id,requester_name,requester_email,property_summary,consent_to_contact)values
(current_setting('roi.test.lead')::uuid,current_setting('roi.test.c')::uuid,current_setting('roi.test.p')::uuid,'ROI fixture','roi@example.invalid','Temporary fixture',true),
(current_setting('roi.test.foreignlead')::uuid,current_setting('roi.test.c')::uuid,current_setting('roi.test.q')::uuid,'Other fixture','other@example.invalid','Temporary fixture',true);
update public.lead_requests set status='qualified' where id=current_setting('roi.test.lead')::uuid;
update public.lead_requests set status='consultation' where id=current_setting('roi.test.lead')::uuid;
update public.lead_requests set status='won' where id=current_setting('roi.test.lead')::uuid;
update public.lead_requests set status='lost' where id=current_setting('roi.test.lead')::uuid;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('roi.test.a'),'role','authenticated')::text,true);
set local role authenticated;
select public.pact_record_member_profile_view(current_setting('roi.test.a')::uuid);
insert into public.member_roi_settings(owner_id,annual_cost)values(auth.uid(),2988);
insert into public.member_roi_outcomes(id,owner_id,kind,label,source,lead_id,occurred_on,revenue)values
(current_setting('roi.test.outcome')::uuid,auth.uid(),'transaction','Temporary commission','Pact introduction',current_setting('roi.test.lead')::uuid,current_date,15000),
(gen_random_uuid(),auth.uid(),'consultation','Linked consultation','Pact introduction',current_setting('roi.test.lead')::uuid,current_date,0);
do $$ declare d jsonb; begin
 d:=public.pact_member_roi_summary(365);
 if(d->>'views')::int<>0 then raise exception 'Self views counted';end if;
 if(d->>'qualified_inquiries')::int<>1 or(d->>'consultations')::int<>1 or(d->>'transactions')::int<>1 then raise exception 'Workflow milestones lost or linked outcomes double counted';end if;
 if(d->>'revenue')::numeric<>15000 or(d->>'annual_cost')::numeric<>2988 then raise exception 'ROI totals incorrect';end if;
 begin insert into public.member_roi_outcomes(id,owner_id,kind,label,source,occurred_on,revenue)values(current_setting('roi.test.outcome')::uuid,auth.uid(),'transaction','Duplicate','Pact profile',current_date,100);raise exception 'Duplicate outcome accepted';exception when unique_violation then null;end;
 begin insert into public.member_roi_outcomes(id,owner_id,kind,label,source,lead_id,occurred_on,revenue)values(gen_random_uuid(),auth.uid(),'transaction','Foreign lead','Pact introduction',current_setting('roi.test.foreignlead')::uuid,current_date,10);raise exception 'Other member lead accepted';exception when insufficient_privilege then null;end;
 begin update public.member_roi_settings set owner_id=current_setting('roi.test.b')::uuid where owner_id=auth.uid();raise exception 'Cost ownership reassignment accepted';exception when insufficient_privilege then null;end;
 begin perform * from pact_private.member_profile_visits;raise exception 'Private visitor identities exposed';exception when insufficient_privilege then null;end;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('roi.test.c'),'role','authenticated')::text,true);
set local role authenticated;
select public.pact_record_member_profile_view(current_setting('roi.test.a')::uuid);
select public.pact_record_member_profile_view(null,current_setting('roi.test.p')::uuid);
do $$ begin
 begin perform public.pact_member_roi_summary(365);raise exception 'Buyer read member ROI';exception when raise_exception then if sqlerrm='Buyer read member ROI' then raise;end if;end;
 if exists(select 1 from public.member_roi_outcomes) then raise exception 'Other account outcomes exposed';end if;
 begin insert into public.member_roi_outcomes(id,owner_id,kind,label,source,occurred_on,revenue)values(gen_random_uuid(),current_setting('roi.test.a')::uuid,'transaction','Forged revenue','Pact profile',current_date,999999);raise exception 'Other account revenue forged';exception when insufficient_privilege then null;end;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('roi.test.b'),'role','authenticated')::text,true);
set local role authenticated;
do $$ declare d jsonb;begin
 d:=public.pact_member_roi_summary(365);
 if(d->>'revenue')::numeric<>0 or(d->>'transactions')::int<>0 then raise exception 'Other member totals exposed';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('roi.test.a'),'role','authenticated')::text,true);
set local role authenticated;
do $$ declare d jsonb;begin
 d:=public.pact_member_roi_summary(365);if(d->>'views')::int<>1 then raise exception 'Repeated daily visits inflated views';end if;
end $$;
update public.member_roi_outcomes set voided_at=now() where id=current_setting('roi.test.outcome')::uuid;
do $$ declare d jsonb;begin d:=public.pact_member_roi_summary(365);if(d->>'revenue')::numeric<>0 then raise exception 'Voided outcome still affects ROI';end if;end $$;
reset role;
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ begin begin perform public.pact_member_roi_summary(365);raise exception 'Anonymous ROI access';exception when insufficient_privilege then null;end;end $$;
reset role;
rollback;
select 'PASS: owner-only ROI, member authorization, self/daily view exclusion, milestone persistence, linked outcome deduplication, cost ownership, immutable outcome IDs and revenue correction' as result;
