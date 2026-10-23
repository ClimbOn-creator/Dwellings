-- Shared account/professional identity. Existing content and media remain intact.
alter table public.profiles add column if not exists profile_cover_url text not null default '';
alter table public.provider_profiles add column if not exists cover_photo_url text not null default '';

create or replace function pact_private.sync_profile_identity() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if pg_trigger_depth() > 1 then return new; end if;
  if tg_table_name = 'profiles' then
    update public.provider_profiles set
      display_name = case when new.full_name is distinct from old.full_name then new.full_name else display_name end,
      company_name = case when new.company_name is distinct from old.company_name then new.company_name else company_name end,
      job_title = case when new.job_title is distinct from old.job_title then new.job_title else job_title end,
      description = case when new.bio is distinct from old.bio then new.bio else description end,
      logo_object_key = case when new.profile_photo_url is distinct from old.profile_photo_url then new.profile_photo_url else logo_object_key end,
      cover_photo_url = case when new.profile_cover_url is distinct from old.profile_cover_url then new.profile_cover_url else cover_photo_url end,
      updated_at = now()
    where owner_user_id = new.id;
  elsif new.owner_user_id is not null then
    update public.profiles set
      full_name = case when new.display_name is distinct from old.display_name then new.display_name else full_name end,
      display_name = case when new.display_name is distinct from old.display_name then new.display_name else display_name end,
      company_name = case when new.company_name is distinct from old.company_name then new.company_name else company_name end,
      job_title = case when new.job_title is distinct from old.job_title then new.job_title else job_title end,
      bio = case when new.description is distinct from old.description then new.description else bio end,
      profile_photo_url = case when new.logo_object_key is distinct from old.logo_object_key then coalesce(new.logo_object_key,'') else profile_photo_url end,
      profile_cover_url = case when new.cover_photo_url is distinct from old.cover_photo_url then new.cover_photo_url else profile_cover_url end,
      updated_at = now()
    where id = new.owner_user_id;
  end if;
  return new;
end $$;
revoke all on function pact_private.sync_profile_identity() from public, anon, authenticated;
create trigger pact_account_identity after update of full_name, company_name, job_title, bio, profile_photo_url, profile_cover_url on public.profiles for each row
when (old.full_name is distinct from new.full_name or old.company_name is distinct from new.company_name or old.job_title is distinct from new.job_title or old.bio is distinct from new.bio or old.profile_photo_url is distinct from new.profile_photo_url or old.profile_cover_url is distinct from new.profile_cover_url)
execute function pact_private.sync_profile_identity();
create trigger pact_professional_identity after update of display_name, company_name, job_title, description, logo_object_key, cover_photo_url on public.provider_profiles for each row
when (old.display_name is distinct from new.display_name or old.company_name is distinct from new.company_name or old.job_title is distinct from new.job_title or old.description is distinct from new.description or old.logo_object_key is distinct from new.logo_object_key or old.cover_photo_url is distinct from new.cover_photo_url)
execute function pact_private.sync_profile_identity();

create table public.pact_profile_media (
  owner_id uuid not null references public.profiles(id) on delete cascade,
  slot text not null check (slot in ('avatar','cover')),
  id uuid not null unique,
  object_key text not null,
  byte_size integer not null check (byte_size between 1 and 8388608),
  updated_at timestamptz not null default now(),
  primary key (owner_id, slot),
  check (object_key = 'profiles/' || owner_id::text || '/' || slot || '/' || id::text || '.png')
);
alter table public.pact_profile_media enable row level security;
-- Only deliberately public profile images are served; private documents use different APIs.
create policy "Public profile image metadata" on public.pact_profile_media for select to anon, authenticated using (true);
create policy "Own profile image insert" on public.pact_profile_media for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "Own profile image update" on public.pact_profile_media for update to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
revoke all on public.pact_profile_media from public, anon, authenticated;
grant select on public.pact_profile_media to anon;
grant select, insert, update on public.pact_profile_media to authenticated;

create function public.pact_register_profile_media(p_slot text,p_id uuid,p_bytes integer) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare actor uuid := auth.uid(); previous_key text; stamp timestamptz; media_url text;
begin
  if actor is null then raise exception 'Sign in required'; end if;
  if p_slot not in ('avatar','cover') or p_id is null or p_bytes not between 1 and 8388608 then raise exception 'Invalid image'; end if;
  perform pg_advisory_xact_lock(hashtextextended(actor::text || p_slot,0));
  select object_key,updated_at into previous_key,stamp from public.pact_profile_media where owner_id=actor and slot=p_slot;
  if stamp > clock_timestamp() - interval '2 seconds' then raise exception 'Please wait before changing this image again'; end if;
  insert into public.pact_profile_media(owner_id,slot,id,object_key,byte_size)
  values(actor,p_slot,p_id,'profiles/'||actor::text||'/'||p_slot||'/'||p_id::text||'.png',p_bytes)
  on conflict(owner_id,slot) do update set id=excluded.id,object_key=excluded.object_key,byte_size=excluded.byte_size,updated_at=now();
  media_url := 'https://dwelling-iq-app.pages.dev/api/profile-media?id=' || p_id::text;
  update public.profiles set
    profile_photo_url=case when p_slot='avatar' then media_url else profile_photo_url end,
    profile_cover_url=case when p_slot='cover' then media_url else profile_cover_url end,updated_at=now()
  where id=actor;
  if not found then raise exception 'Account profile missing'; end if;
  return jsonb_build_object('url',media_url,'previous_key',previous_key);
end $$;
revoke all on function public.pact_register_profile_media(text,uuid,integer) from public,anon;
grant execute on function public.pact_register_profile_media(text,uuid,integer) to authenticated;

create function public.pact_save_profile(payload jsonb, expected_updated_at timestamptz default null) returns jsonb
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
  update public.provider_profiles set
    specialties=case when payload ? 'specialties' then array(select jsonb_array_elements_text(payload->'specialties')) else specialties end,
    service_markets=case when payload ? 'service_markets' then array(select jsonb_array_elements_text(payload->'service_markets')) else service_markets end,
    phone=coalesce(payload->>'phone',phone),website_url=coalesce(payload->>'website_url',website_url),updated_at=now()
  where owner_user_id=actor;
  return (select to_jsonb(p) from public.profiles p where id=actor);
end $$;
revoke all on function public.pact_save_profile(jsonb,timestamptz) from public,anon;
grant execute on function public.pact_save_profile(jsonb,timestamptz) to authenticated;
