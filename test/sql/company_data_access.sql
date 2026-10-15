begin;
-- Synthetic account and activity are transaction-scoped and rolled back.
select set_config('company.test.usage_before',(select coalesce(sum(visits),0)::text from public.affinity_usage_daily),true);
select set_config('company.test.user',gen_random_uuid()::text,true);
insert into auth.users(id) values(current_setting('company.test.user')::uuid);
select set_config('company.test.owner',(select user_id::text from public.affinity_admins where role='owner' order by user_id limit 1),true);
select set_config('company.test.owner2',(select user_id::text from public.affinity_admins where role='owner' order by user_id offset 1 limit 1),true);
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ declare denied boolean:=false;begin
 begin perform public.load_affinity_company_data(30);exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Anonymous report access accepted';end if;
 denied:=false;
 begin perform public.record_affinity_feature_visit('buyer');exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Anonymous activity write accepted';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('company.test.user'),'role','authenticated','user_metadata',jsonb_build_object('role','owner'))::text,true);
set local role authenticated;
do $$ declare denied boolean:=false;begin
 if public.is_affinity_data_owner() then raise exception 'User metadata granted owner access';end if;
 begin perform public.load_affinity_company_data(30);exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Regular user report access accepted';end if;
 denied:=false;
 begin perform 1 from public.affinity_usage_daily;exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Direct usage table read accepted';end if;
 denied:=false;
 begin insert into public.affinity_usage_daily(feature) values('buyer');exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Direct usage table write accepted';end if;
 denied:=false;
 begin perform public.record_affinity_feature_visit('private form data');exception when invalid_parameter_value then denied:=true;end;
 if not denied then raise exception 'Arbitrary analytics fields accepted';end if;
 perform public.record_affinity_feature_visit('buyer');
end $$;
reset role;
insert into public.affinity_admins(user_id,role) values(current_setting('company.test.user')::uuid,'reviewer');
set local role authenticated;
do $$ declare denied boolean:=false;begin
 begin perform public.load_affinity_company_data(30);exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Reviewer report access accepted';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('company.test.owner'),'role','authenticated')::text,true);
set local role authenticated;
do $$ declare report jsonb;denied boolean:=false;begin
 if not public.is_affinity_data_owner() then raise exception 'Owner one missing access';end if;
 perform public.record_affinity_feature_visit('learning');
 report:=public.load_affinity_company_data(30);
 if jsonb_array_length(report->'inventory')<>27 then raise exception 'Incomplete inventory';end if;
 if (report->'totals'->>'Registered accounts')::bigint<1 then raise exception 'Missing accounts';end if;
 if jsonb_array_length(report->'new_accounts')<>30 then raise exception 'Date range failed';end if;
 begin perform public.load_affinity_company_data(999);exception when invalid_parameter_value then denied:=true;end;
 if not denied then raise exception 'Unbounded report period accepted';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('company.test.owner2'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin
 if not public.is_affinity_data_owner() then raise exception 'Owner two missing access';end if;
 perform public.load_affinity_company_data(7);
end $$;
reset role;
do $$ begin
 if (select coalesce(sum(visits),0) from public.affinity_usage_daily) <> current_setting('company.test.usage_before')::bigint+1 then raise exception 'Owner visits were counted or user visit was lost';end if;
end $$;
-- A role revocation takes effect immediately, even with the same JWT.
update public.affinity_admins set role='reviewer' where user_id=current_setting('company.test.owner2')::uuid;
set local role authenticated;
do $$ declare denied boolean:=false;begin
 begin perform public.load_affinity_company_data(30);exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Revoked owner retained access';end if;
end $$;
reset role;
select 'Owner, second owner, reviewer, non-owner, anonymous, metadata spoof, revoked role, allowlist and reporting checks passed; all test changes rolled back.' as result;
rollback;
