-- Apply after 202609030023_business_sale_bulletin_board.sql.
begin;

alter table public.business_sale_bulletins
  add column if not exists details jsonb not null default '{}'::jsonb;

create table if not exists public.saved_business_sale_bulletins (
  user_id uuid not null references auth.users(id) on delete cascade,
  bulletin_id uuid not null references public.business_sale_bulletins(id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (user_id, bulletin_id)
);
create index if not exists saved_business_sale_bulletins_bulletin_idx
  on public.saved_business_sale_bulletins(bulletin_id);
alter table public.saved_business_sale_bulletins enable row level security;
grant select, insert, delete on public.saved_business_sale_bulletins to authenticated;
drop policy if exists "Read own bulletin saves" on public.saved_business_sale_bulletins;
create policy "Read own bulletin saves" on public.saved_business_sale_bulletins
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "Delete own bulletin saves" on public.saved_business_sale_bulletins;
create policy "Delete own bulletin saves" on public.saved_business_sale_bulletins
  for delete to authenticated using (user_id = auth.uid());

-- A definer function checks listing visibility without granting raw table access.
create or replace function public.set_business_sale_bulletin_saved(target_id uuid, should_save boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Sign in to save a business'; end if;
  if should_save then
    if not exists(select 1 from public.business_sale_bulletins where id = target_id and status in ('active','converted')) then
      raise exception 'Business listing unavailable';
    end if;
    insert into public.saved_business_sale_bulletins(user_id, bulletin_id)
    values(auth.uid(), target_id) on conflict do nothing;
  else
    delete from public.saved_business_sale_bulletins where user_id = auth.uid() and bulletin_id = target_id;
  end if;
end;
$$;
revoke all on function public.set_business_sale_bulletin_saved(uuid, boolean) from public, anon;
grant execute on function public.set_business_sale_bulletin_saved(uuid, boolean) to authenticated;

create or replace function public.browse_business_sale_bulletins_v2(target_id uuid default null)
returns setof jsonb language sql stable security definer set search_path = public as $$
  select (to_jsonb(b) - 'created_by_user_id') || jsonb_build_object(
    'can_edit', auth.uid() is not null and (b.created_by_user_id = auth.uid() or public.is_affinity_admin()),
    'can_convert', public.is_affinity_admin() and b.converted_opportunity_id is null,
    'is_saved', exists(select 1 from public.saved_business_sale_bulletins s where s.bulletin_id = b.id and s.user_id = auth.uid())
  ) from public.business_sale_bulletins b
  where b.status in ('active','converted') and (target_id is null or b.id = target_id)
  order by b.posted_at desc;
$$;
revoke all on function public.browse_business_sale_bulletins_v2(uuid) from public;
grant execute on function public.browse_business_sale_bulletins_v2(uuid) to anon, authenticated;

create or replace function public.save_business_sale_bulletin(target_id uuid, listing jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  b public.business_sale_bulletins;
  d jsonb := coalesce(listing->'details', '{}'::jsonb);
  field text;
  link text;
begin
  if auth.uid() is null then raise exception 'Sign in to edit a business'; end if;
  if target_id is null then
    if not public.is_affinity_admin() then raise exception 'Administrator access required to post'; end if;
  else
    select * into b from public.business_sale_bulletins where id = target_id for update;
    if b.id is null then raise exception 'Business listing unavailable'; end if;
    if b.created_by_user_id <> auth.uid() and not public.is_affinity_admin() then
      raise exception 'You cannot edit this business';
    end if;
    if listing->>'expected_updated_at' is null or
       (listing->>'expected_updated_at')::timestamptz is distinct from b.updated_at then
      raise exception 'This listing changed since you opened it. Reload before editing.';
    end if;
  end if;
  if coalesce(char_length(trim(listing->>'title')),0) not between 3 and 180 then raise exception 'Title must be 3–180 characters'; end if;
  if coalesce(char_length(trim(listing->>'summary')),0) not between 20 and 2000 then raise exception 'Description must be 20–2000 characters'; end if;
  if jsonb_typeof(d) <> 'object' then raise exception 'Invalid listing details'; end if;
  foreach field in array array['revenue','cash_flow','real_estate','location_details','reason_for_selling','highlights','contact_url','listing_type'] loop
    if coalesce(char_length(d->>field),0) > 3000 then raise exception 'Listing field too long'; end if;
  end loop;
  if jsonb_typeof(coalesce(d->'photos','[]'::jsonb)) <> 'array' then raise exception 'Photos must be a list'; end if;
  if jsonb_array_length(coalesce(d->'photos','[]'::jsonb)) > 8 then raise exception 'Use at most eight photos'; end if;
  for link in select jsonb_array_elements_text(coalesce(d->'photos','[]'::jsonb))
    union all select coalesce(listing->>'source_url','')
    union all select coalesce(d->>'contact_url','')
  loop
    if link <> '' and (link !~* '^https?://[^/[:space:]]+' or char_length(link) > 2048) then
      raise exception 'Use a complete http or https link';
    end if;
  end loop;
  -- Keep only supported public fields; do not accept ownership or permissions from clients.
  d := jsonb_build_object(
    'revenue', coalesce(d->>'revenue',''), 'cash_flow', coalesce(d->>'cash_flow',''),
    'real_estate', coalesce(d->>'real_estate',''), 'location_details', coalesce(d->>'location_details',''),
    'reason_for_selling', coalesce(d->>'reason_for_selling',''), 'highlights', coalesce(d->>'highlights',''),
    'contact_url', coalesce(d->>'contact_url',''), 'listing_type', coalesce(d->>'listing_type','Business'),
    'photos', coalesce(d->'photos','[]'::jsonb));
  if target_id is null then
    insert into public.business_sale_bulletins(created_by_user_id,title,industry,region,asking_price_band,summary,source_label,source_url,details)
    values(auth.uid(),trim(listing->>'title'),coalesce(listing->>'industry',''),coalesce(listing->>'region',''),
      coalesce(nullif(trim(listing->>'asking_price_band'),''),'Contact seller'),trim(listing->>'summary'),
      coalesce(listing->>'source_label',''),coalesce(listing->>'source_url',''),d) returning id into target_id;
  else
    update public.business_sale_bulletins set title = trim(listing->>'title'), industry = coalesce(listing->>'industry',''),
      region = coalesce(listing->>'region',''), asking_price_band = coalesce(nullif(trim(listing->>'asking_price_band'),''),'Contact seller'),
      summary = trim(listing->>'summary'), source_label = coalesce(listing->>'source_label',''),
      source_url = coalesce(listing->>'source_url',''), details = d
    where id = target_id;
  end if;
  return target_id;
end;
$$;
revoke all on function public.save_business_sale_bulletin(uuid,jsonb) from public, anon;
grant execute on function public.save_business_sale_bulletin(uuid,jsonb) to authenticated;

create or replace function public.notify_saved_bulletin_update()
returns trigger language plpgsql security definer set search_path = public as $$
declare follower record;
begin
  if (to_jsonb(old) - 'updated_at' - 'converted_opportunity_id' - 'status') is not distinct from
     (to_jsonb(new) - 'updated_at' - 'converted_opportunity_id' - 'status') then return new; end if;
  new.updated_at := clock_timestamp();
  for follower in select user_id from public.saved_business_sale_bulletins where bulletin_id = new.id loop
    perform public.create_affinity_notification(follower.user_id,'deal','A saved business was updated',
      new.title || ' has new listing information.','bulletin-board','bulletin',new.id);
  end loop;
  return new;
end;
$$;
drop trigger if exists saved_bulletin_update on public.business_sale_bulletins;
create trigger saved_bulletin_update before update on public.business_sale_bulletins
  for each row execute function public.notify_saved_bulletin_update();

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('business-listing-photos','business-listing-photos',true,8388608,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
drop policy if exists "Public listing photos" on storage.objects;
create policy "Public listing photos" on storage.objects for select using(bucket_id = 'business-listing-photos');
drop policy if exists "Admins upload listing photos" on storage.objects;
create policy "Admins upload listing photos" on storage.objects for insert to authenticated
  with check(bucket_id = 'business-listing-photos' and public.is_affinity_admin() and (storage.foldername(name))[1] = auth.uid()::text);


-- Keep operational review notices, but listing-content updates go only to savers.
create or replace function public.audit_member_studio_opportunity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare follower record;
begin
  if tg_op = 'INSERT' then
    insert into public.affinity_audit_events(actor_user_id, event_type, entity_type, entity_id, metadata)
    values (auth.uid(), 'deal_submitted', 'opportunity', new.id, jsonb_build_object('status', new.status));
    perform public.create_affinity_notification(
      new.owner_user_id, 'deal', 'Affinity received your deal',
      'Your opportunity is private and waiting for Affinity review.',
      'member-studio', 'opportunity', new.id
    );
    perform public.create_affinity_notification(
      administrator.user_id, 'review', 'A deal is waiting for review',
      'A new private deal is ready in the Affinity Review Desk.',
      'review-desk', 'opportunity', new.id
    ) from public.affinity_admins administrator
      where administrator.user_id <> new.owner_user_id;
  elsif old.status is distinct from new.status then
    insert into public.affinity_audit_events(actor_user_id, event_type, entity_type, entity_id, metadata)
    values (auth.uid(), 'deal_status_changed', 'opportunity', new.id,
      jsonb_build_object('from', old.status, 'to', new.status));
    if new.status in ('published','needs_information','approved','declined') then
    perform public.create_affinity_notification(
      new.owner_user_id, 'deal',
      case new.status
        when 'published' then 'Your opportunity is live'
        when 'needs_information' then 'Affinity needs more information'
        when 'approved' then 'Your opportunity passed review'
        when 'declined' then 'Your opportunity review is complete'
        else 'Your opportunity was updated'
      end,
      case new.status
        when 'published' then 'Verified professionals can now review the anonymous brief and submit private pitches.'
        when 'needs_information' then 'Open your Member Studio response centre for the latest review status.'
        when 'approved' then 'Affinity has approved the anonymous brief for the Member Studio.'
        when 'declined' then 'Open Member Studio to review the current status.'
        else 'Open Member Studio to see the latest status.'
      end,
      'member-studio', 'opportunity', new.id
    );
    end if;
  elsif old.headline is distinct from new.headline
     or old.summary is distinct from new.summary
     or old.industry is distinct from new.industry
     or old.region is distinct from new.region
     or old.stage is distinct from new.stage
     or old.purchase_price_band is distinct from new.purchase_price_band
     or old.capital_required_band is distinct from new.capital_required_band
     or old.public_details is distinct from new.public_details
     or old.support_needed is distinct from new.support_needed
     or old.affinity_score is distinct from new.affinity_score
     or old.last_reposted_at is distinct from new.last_reposted_at then
    insert into public.affinity_audit_events(actor_user_id, event_type, entity_type, entity_id, metadata)
    values (auth.uid(), 'deal_content_updated', 'opportunity', new.id,
      jsonb_build_object('status', new.status));

  end if;

  if tg_op = 'UPDATE' then
    if old.status = 'published' and (
       old.status is distinct from new.status or
       old.headline is distinct from new.headline
       or old.summary is distinct from new.summary
       or old.industry is distinct from new.industry
       or old.region is distinct from new.region
       or old.stage is distinct from new.stage
       or old.purchase_price_band is distinct from new.purchase_price_band
       or old.capital_required_band is distinct from new.capital_required_band
       or old.public_details is distinct from new.public_details
       or old.support_needed is distinct from new.support_needed
       or old.affinity_score is distinct from new.affinity_score
       or old.last_reposted_at is distinct from new.last_reposted_at
    ) then
      for follower in
        select saved.user_id from public.member_saved_deals saved
        where saved.opportunity_id = new.id
      loop
        perform public.create_affinity_notification(
          follower.user_id, 'deal', 'A saved deal was updated',
          coalesce(nullif(case when new.status = 'published' then new.headline else old.headline end, ''), 'An anonymous opportunity') || ' has new information.',
          'member-studio', 'opportunity', new.id
        );
      end loop;
    end if;
  end if;
  return new;
end;
$$;


commit;
