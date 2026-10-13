-- Add event metadata without changing existing sessions, approvals or user content.
alter table public.learning_seminars
 add column is_published boolean not null default false,
 add column organization text not null default '' check(length(organization)<=160),
 add column event_kind text not null default 'seminar' check(event_kind in ('seminar','meeting','information','workshop')),
 add column event_mode text not null default 'online' check(event_mode in ('online','in_person','hybrid')),
 add column area_name text,
 add column latitude double precision check(latitude between 41 and 84 and latitude=round(latitude::numeric,1)::double precision),
 add column longitude double precision check(longitude between -141 and -52 and longitude=round(longitude::numeric,1)::double precision),
 add column venue text not null default '' check(length(venue)<=300),
 add constraint learning_event_area_pair check((latitude is null)=(longitude is null));
-- In-person events need a location, online events need a joining URL.
alter table public.learning_seminars alter column meeting_url drop not null;
-- The original URL check allows NULL; existing HTTPS values are retained.
alter table public.learning_seminars add constraint learning_event_join_location check(
 (event_mode='online' and meeting_url is not null) or
 (event_mode='hybrid' and meeting_url is not null and latitude is not null) or
 (event_mode='in_person' and latitude is not null));
grant insert(is_published,organization,event_kind,event_mode,area_name,latitude,longitude,venue),update(is_published,organization,event_kind,event_mode,area_name,latitude,longitude,venue) on public.learning_seminars to authenticated;
-- Preserve the exact existing public visibility: the old read policy already exposes
-- sessions from approved, non-revoked hosts, irrespective of event status.
-- Future events default private and become public only when the host publishes.
update public.learning_seminars s set is_published=true where exists(select 1 from public.learning_publishers p where p.user_id=s.host_id and p.revoked_at is null);
drop policy learning_seminars_read on public.learning_seminars;
create policy learning_seminars_read on public.learning_seminars for select to anon,authenticated using(
 (is_published and exists(select 1 from public.learning_publishers p where p.user_id=host_id and p.revoked_at is null))
 or (not is_published and host_id=(select auth.uid())) or (select learning_private.is_owner()));
create index learning_events_upcoming on public.learning_seminars(starts_at,status);

create table public.learning_event_images (
 id uuid primary key default gen_random_uuid(), seminar_id uuid not null unique references public.learning_seminars(id),
 object_path text not null unique, filename text not null check(length(filename) between 1 and 180),
 mime_type text not null check(mime_type in ('image/jpeg','image/png','image/webp')),byte_size bigint not null check(byte_size>0 and byte_size<=5242880)
);
alter table public.learning_event_images enable row level security;
revoke all on public.learning_event_images from anon,authenticated;
grant select on public.learning_event_images to anon,authenticated;
grant insert(seminar_id,object_path,filename,mime_type,byte_size),update(object_path,filename,mime_type,byte_size) on public.learning_event_images to authenticated;
create policy learning_event_image_read on public.learning_event_images for select to anon,authenticated using(exists(
 select 1 from public.learning_seminars s join public.learning_publishers p on p.user_id=s.host_id
 where s.id=seminar_id and ((s.is_published and p.revoked_at is null) or s.host_id=(select auth.uid()) or (select learning_private.is_owner()))));
create policy learning_event_image_insert on public.learning_event_images for insert to authenticated with check(
 (select learning_private.can_publish()) and exists(select 1 from public.learning_seminars s where s.id=seminar_id and s.host_id=(select auth.uid()))
 and object_path like (select auth.uid())::text || '/' || seminar_id::text || '/%');
create policy learning_event_image_update on public.learning_event_images for update to authenticated using(
 (select learning_private.can_publish()) and exists(select 1 from public.learning_seminars s where s.id=seminar_id and s.host_id=(select auth.uid())))
 with check((select learning_private.can_publish()) and exists(select 1 from public.learning_seminars s where s.id=seminar_id and s.host_id=(select auth.uid())) and object_path like (select auth.uid())::text || '/' || seminar_id::text || '/%');
notify pgrst,'reload schema';
