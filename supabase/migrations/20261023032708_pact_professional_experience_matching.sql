-- Additive structured public experience. Existing descriptions, photos and specialties survive.
create function pact_private.valid_professional_background(data jsonb) returns boolean
language plpgsql immutable security invoker set search_path='' as $$
declare k text; v jsonb; entry jsonb; field text;
begin
 if jsonb_typeof(data) is distinct from 'object' or octet_length(data::text)>24576 then return false; end if;
 if exists(select 1 from jsonb_object_keys(data) x where x not in ('services','industries','transaction_types','jurisdictions','currency','deal_min','deal_max','availability','employment','deals','credentials')) then return false; end if;
 foreach k in array array['services','industries','transaction_types','jurisdictions'] loop
  if data ? k then
   if jsonb_typeof(data->k)<>'array' or jsonb_array_length(data->k)>16 then return false; end if;
   for v in select * from jsonb_array_elements(data->k) loop
    if jsonb_typeof(v)<>'string' or length(v#>>'{}') not between 1 and 100 then return false; end if;
    if k='jurisdictions' and (v#>>'{}') !~ '^[A-Z]{2}(-[A-Z0-9]{1,3})?$' then return false; end if;
   end loop;
  end if;
 end loop;
 if data ? 'availability' and data->>'availability' not in ('accepting','limited','unavailable','unknown') then return false; end if;
 if data ? 'currency' and data->>'currency' not in ('CAD','USD','EUR','GBP','AUD') then return false; end if;
 foreach k in array array['deal_min','deal_max'] loop
  if data ? k and (jsonb_typeof(data->k)<>'number' or (data->>k)::numeric<0 or (data->>k)::numeric>1000000000000) then return false; end if;
 end loop;
 if data ? 'deal_min' and data ? 'deal_max' and (data->>'deal_min')::numeric>(data->>'deal_max')::numeric then return false; end if;
 foreach k in array array['employment','deals','credentials'] loop
  if data ? k then
   if jsonb_typeof(data->k)<>'array' or jsonb_array_length(data->k)>12 then return false; end if;
   for entry in select * from jsonb_array_elements(data->k) loop
    if jsonb_typeof(entry)<>'object' or length(trim(coalesce(entry->>'title','')))=0 then return false; end if;
    for field,v in select * from jsonb_each(entry) loop
     if field not in ('title','organization','start_year','end_year','description','industry','transaction_type','role','year','summary','issuer','number','jurisdiction','expires_on')
       or jsonb_typeof(v)<>'string' or length(v#>>'{}')>(case when field in ('description','summary') then 1200 else 160 end) then return false; end if;
     if field in ('year','start_year','end_year') and (v#>>'{}')<>'' and (v#>>'{}') !~ '^(19|20)[0-9]{2}$' then return false; end if;
    end loop;
    if k='credentials' and (coalesce(entry->>'jurisdiction','') !~ '^[A-Z]{2}(-[A-Z0-9]{1,3})?$' or length(trim(coalesce(entry->>'issuer','')))=0) then return false; end if;
    if k='credentials' and coalesce(entry->>'expires_on','')<>'' then
      if (entry->>'expires_on') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' or to_char((entry->>'expires_on')::date,'YYYY-MM-DD')<>(entry->>'expires_on') then return false; end if;
    end if;
    if k='employment' and coalesce(entry->>'end_year','')<>'' and coalesce(entry->>'start_year','')<>'' and (entry->>'end_year')::int < (entry->>'start_year')::int then return false; end if;
   end loop;
  end if;
 end loop;
 return true;
exception when others then return false;
end $$;
revoke all on function pact_private.valid_professional_background(jsonb) from public,anon;
grant execute on function pact_private.valid_professional_background(jsonb) to authenticated;
alter table public.provider_profiles add column professional_background jsonb not null default '{}'::jsonb
 check (pact_private.valid_professional_background(professional_background));

create function pact_private.touch_background_account() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 update public.profiles set updated_at=now() where id=new.owner_user_id;
 return new;
end $$;
revoke all on function pact_private.touch_background_account() from public,anon,authenticated;
create trigger pact_background_account_stamp after update of professional_background on public.provider_profiles
for each row when (old.professional_background is distinct from new.professional_background)
execute function pact_private.touch_background_account();

create or replace function public.pact_save_profile(payload jsonb, expected_updated_at timestamptz default null) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare actor uuid:=auth.uid(); current_stamp timestamptz; values_array text[];
begin
  if actor is null then raise exception 'Sign in required'; end if;
  if jsonb_typeof(payload) <> 'object' or length(trim(coalesce(payload->>'full_name',''))) not between 1 and 120
    or length(coalesce(payload->>'job_title','')) > 120 or length(coalesce(payload->>'company_name','')) > 160
    or length(coalesce(payload->>'bio','')) > 4000 or length(coalesce(payload->>'phone','')) > 60
    or length(coalesce(payload->>'website_url','')) > 2048 then raise exception 'Check profile field lengths'; end if;
  if coalesce(payload->>'website_url','') <> '' and payload->>'website_url' !~ '^https?://[^[:space:]]+$' then raise exception 'Use an https or http website URL'; end if;
  for values_array in select array(select jsonb_array_elements_text(coalesce(payload->k,'[]'::jsonb))) from unnest(array['specialties','service_markets']) k loop
    if cardinality(values_array)>16 or exists(select 1 from unnest(values_array) v where length(v)>100 or length(trim(v))=0) then raise exception 'Use up to 16 specialties or markets, each under 100 characters'; end if;
  end loop;
  select updated_at into current_stamp from public.profiles where id=actor for update;
  if not found then raise exception 'Account profile missing'; end if;
  if expected_updated_at is not null and current_stamp is distinct from expected_updated_at then raise exception 'Profile changed on another device. Reopen the editor to load the latest version.'; end if;
  update public.profiles set full_name=trim(payload->>'full_name'),display_name=trim(payload->>'full_name'),
    job_title=trim(coalesce(payload->>'job_title','')),company_name=trim(coalesce(payload->>'company_name','')),
    bio=trim(coalesce(payload->>'bio','')),employment_type=coalesce(payload->>'employment_type',employment_type),updated_at=now()
  where id=actor;
  if payload ? 'professional_background' and not pact_private.valid_professional_background(payload->'professional_background') then raise exception 'Check your experience fields and size limits'; end if;
  update public.provider_profiles set
    professional_background=case when payload ? 'professional_background' then payload->'professional_background' else professional_background end,
    accepting_leads=case payload->'professional_background'->>'availability' when 'unavailable' then false when 'accepting' then true when 'limited' then true else accepting_leads end,
    specialties=case when payload ? 'specialties' then array(select jsonb_array_elements_text(payload->'specialties')) else specialties end,
    service_markets=case when payload ? 'service_markets' then array(select jsonb_array_elements_text(payload->'service_markets')) else service_markets end,
    phone=coalesce(payload->>'phone',phone),website_url=coalesce(payload->>'website_url',website_url),updated_at=now()
  where owner_user_id=actor;
  return (select to_jsonb(p) from public.profiles p where id=actor);
end $$;
revoke all on function public.pact_save_profile(jsonb,timestamptz) from public,anon;
grant execute on function public.pact_save_profile(jsonb,timestamptz) to authenticated;

grant usage on schema pact_private to anon;

-- Verification is held outside the owner's editable public profile.
create table pact_private.professional_credentials (
 provider_id uuid not null references public.provider_profiles(id) on delete cascade,
 claim_hash text not null,
 claim jsonb not null,
 approved boolean not null,
 verified_at timestamptz not null default now(),
 verified_by uuid not null references auth.users(id),
 primary key(provider_id,claim_hash)
);
alter table pact_private.professional_credentials enable row level security;
revoke all on pact_private.professional_credentials from public,anon,authenticated;

create function pact_private.professional_credential_records(target_id uuid) returns jsonb
language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('title',c.claim->>'title','issuer',c.claim->>'issuer','jurisdiction',c.claim->>'jurisdiction','expires_on',c.claim->>'expires_on','verified_at',c.verified_at,'claim',c.claim)),'[]'::jsonb)
 from pact_private.professional_credentials c join public.provider_profiles p on p.id=c.provider_id
 where p.id=target_id and (p.verified or p.owner_user_id=auth.uid()) and c.approved
 and exists(select 1 from jsonb_array_elements(coalesce(p.professional_background->'credentials','[]')) entry where encode(sha256(convert_to(entry::text,'UTF8')),'hex')=c.claim_hash)
 and (coalesce(c.claim->>'expires_on','')='' or (c.claim->>'expires_on')::date>=current_date);
$$;
revoke all on function pact_private.professional_credential_records(uuid) from public;
grant execute on function pact_private.professional_credential_records(uuid) to anon,authenticated;
create function public.pact_professional_credentials(target_id uuid) returns jsonb
language sql stable security invoker set search_path='' as $$ select pact_private.professional_credential_records(target_id); $$;
revoke all on function public.pact_professional_credentials(uuid) from public;
grant execute on function public.pact_professional_credentials(uuid) to anon,authenticated;

create function pact_private.verify_professional_credential(target_id uuid, claim_index integer, expected_stamp timestamptz, approve boolean) returns void
language plpgsql security definer set search_path='' as $$
declare p public.provider_profiles; claim jsonb;
begin
 if auth.uid() is null or not public.is_affinity_admin() then raise exception 'Administrator required' using errcode='42501'; end if;
 select * into p from public.provider_profiles where id=target_id for update;
 if not found or p.updated_at is distinct from expected_stamp then raise exception 'Profile changed; reload before verifying'; end if;
 if p.owner_user_id=auth.uid() then raise exception 'Another administrator must review your credential'; end if;
 if claim_index is null or claim_index<0 then raise exception 'Choose a credential'; end if;
 claim:=p.professional_background->'credentials'->claim_index;
 if claim is null then raise exception 'Credential missing'; end if;
 insert into pact_private.professional_credentials(provider_id,claim_hash,claim,approved,verified_by)
 values(target_id,encode(sha256(convert_to(claim::text,'UTF8')),'hex'),claim,approve,auth.uid()) on conflict(provider_id,claim_hash)
 do update set approved=excluded.approved,verified_by=excluded.verified_by,verified_at=now();
end $$;
revoke all on function pact_private.verify_professional_credential(uuid,integer,timestamptz,boolean) from public,anon;
grant execute on function pact_private.verify_professional_credential(uuid,integer,timestamptz,boolean) to authenticated;
create function public.pact_verify_professional_credential(target_id uuid,claim_index integer,expected_stamp timestamptz,approve boolean) returns void
language sql security invoker set search_path='' as $$ select pact_private.verify_professional_credential(target_id,claim_index,expected_stamp,approve); $$;
revoke all on function public.pact_verify_professional_credential(uuid,integer,timestamptz,boolean) from public,anon;
grant execute on function public.pact_verify_professional_credential(uuid,integer,timestamptz,boolean) to authenticated;

create function pact_private.professional_matches(criteria jsonb) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare p public.provider_profiles; b jsonb; result jsonb:='[]'; missing jsonb; reasons jsonb; credentials jsonb;
 service_score int; industry_score int; deal_score int; location_score int; needs_license boolean; amount numeric;
begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 if jsonb_typeof(criteria)<>'object' or octet_length(criteria::text)>2048
   or coalesce(criteria->>'profession','') not in ('realtor','mortgage_broker','lawyer','accountant','lender','business_broker','ma_lawyer','quality_of_earnings','commercial_lender','tax_advisor','insurance_advisor','human_resources','cybersecurity','industry_advisor','wealth_manager')
   or coalesce(criteria->>'jurisdiction','') !~ '^[A-Z]{2}(-[A-Z0-9]{1,3})?$'
   or length(coalesce(criteria->>'service','')) not between 1 and 100
   or length(coalesce(criteria->>'industry','')) not between 1 and 100
   or length(coalesce(criteria->>'transaction_type','')) not between 1 and 100
   or coalesce(criteria->>'currency','') not in ('CAD','USD','EUR','GBP','AUD') then raise exception 'Complete the deal matching criteria'; end if;
 amount:=nullif(criteria->>'amount','')::numeric;
 if amount<0 or amount>1000000000000 then raise exception 'Invalid deal amount'; end if;
 needs_license:=coalesce((criteria->>'require_credential')::boolean,false) or criteria->>'profession' in ('realtor','mortgage_broker','lawyer','ma_lawyer');
 for p in select * from public.provider_profiles where verified and not is_example and membership_status in ('active','trialing')
   and provider_type=criteria->>'profession' and owner_user_id is distinct from auth.uid() loop
  b:=p.professional_background; missing:='[]'; reasons:='[]';
  service_score:=0; industry_score:=0; deal_score:=0; location_score:=0;
  if not p.accepting_leads or coalesce(b->>'availability','unknown') not in ('accepting','limited') then missing:=missing||'"Availability not confirmed"'::jsonb; end if;
  if coalesce(b->'jurisdictions','[]') ? (criteria->>'jurisdiction') then location_score:=10; reasons:=reasons||'"Serves your selected jurisdiction"'::jsonb;
  else missing:=missing||'"Service jurisdiction not confirmed"'::jsonb; end if;
  credentials:=pact_private.professional_credential_records(p.id);
  if needs_license and not exists(select 1 from jsonb_array_elements(credentials) c where c->>'jurisdiction'=criteria->>'jurisdiction') then missing:=missing||'"Required credential needs verification for this jurisdiction"'::jsonb; end if;
  if coalesce(b->'services','[]') ? (criteria->>'service') then service_score:=35; reasons:=reasons||'"Relevant service specialty"'::jsonb;
  elsif jsonb_array_length(coalesce(b->'services','[]'))=0 then missing:=missing||'"Service specialties not supplied"'::jsonb; end if;
  if jsonb_array_length(coalesce(b->'industries','[]'))=0 then missing:=missing||'"Industry experience not supplied"'::jsonb; end if;
  if jsonb_array_length(coalesce(b->'transaction_types','[]'))=0 then missing:=missing||'"Transaction experience not supplied"'::jsonb; end if;
  if amount is not null and (b->>'currency' is distinct from criteria->>'currency' or not (b ? 'deal_min' and b ? 'deal_max')) then missing:=missing||'"Comparable deal-size range not confirmed"'::jsonb; end if;
  if coalesce(b->'industries','[]') ? (criteria->>'industry') then industry_score:=30; reasons:=reasons||'"Experience in your industry"'::jsonb; end if;
  if coalesce(b->'transaction_types','[]') ? (criteria->>'transaction_type') then deal_score:=15; reasons:=reasons||'"Relevant transaction type"'::jsonb; end if;
  if amount is not null and b->>'currency'=criteria->>'currency' and b ? 'deal_min' and b ? 'deal_max'
    and amount between (b->>'deal_min')::numeric and (b->>'deal_max')::numeric then deal_score:=deal_score+10; reasons:=reasons||'"Your deal falls within their stated size range"'::jsonb; end if;
  result:=result||jsonb_build_array(jsonb_build_object(
    'provider',jsonb_build_object('id',p.id,'provider_type',p.provider_type,'display_name',p.display_name,'company_name',p.company_name,'job_title',p.job_title,'logo_object_key',p.logo_object_key,'verified',p.verified,'is_example',false,'accepting_leads',p.accepting_leads,'specialties',p.specialties,'service_markets',p.service_markets),
    'score',service_score+industry_score+deal_score+location_score,'eligible',jsonb_array_length(missing)=0,'missing',missing,'reasons',reasons,
    'components',jsonb_build_object('service',service_score,'industry',industry_score,'deal',deal_score,'location',location_score)));
  select coalesce(jsonb_agg(row order by (row->>'eligible')::boolean desc,(row->>'score')::int desc,row->'provider'->>'id'),'[]') into result
    from (select row from jsonb_array_elements(result) row order by (row->>'eligible')::boolean desc,(row->>'score')::int desc,row->'provider'->>'id' limit 40) top_matches;
 end loop;
 return result;
end $$;
revoke all on function pact_private.professional_matches(jsonb) from public,anon;
grant execute on function pact_private.professional_matches(jsonb) to authenticated;
create function public.pact_professional_matches(criteria jsonb) returns jsonb
language sql stable security invoker set search_path='' as $$ select pact_private.professional_matches(criteria); $$;
revoke all on function public.pact_professional_matches(jsonb) from public,anon;
grant execute on function public.pact_professional_matches(jsonb) to authenticated;
