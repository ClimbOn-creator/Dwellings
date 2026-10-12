-- Additive learning area; existing content, account records and deal files remain intact.
create schema if not exists learning_private;
revoke all on schema learning_private from public;
grant usage on schema learning_private to anon, authenticated;

create table public.learning_publishers (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null check (length(trim(display_name)) between 2 and 100),
 approved_by uuid not null references auth.users(id),
 approved_at timestamptz not null default now(), revoked_at timestamptz
);
alter table public.learning_publishers enable row level security;

create function learning_private.is_owner() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.affinity_admins a join auth.users u on u.id=a.user_id
 where a.user_id=(select auth.uid()) and a.role='owner' and lower(u.email)='rw0882308@gmail.com' and u.email_confirmed_at is not null);
$$;
create function learning_private.can_publish() returns boolean language sql stable security definer set search_path = '' as $$
 select (select learning_private.is_owner()) or exists(select 1 from public.learning_publishers p where p.user_id=(select auth.uid()) and p.revoked_at is null);
$$;
revoke all on function learning_private.is_owner(), learning_private.can_publish() from public;
grant execute on function learning_private.is_owner(), learning_private.can_publish() to anon, authenticated;
create policy learning_publishers_read on public.learning_publishers for select to anon,authenticated
 using (revoked_at is null or user_id=(select auth.uid()) or (select learning_private.is_owner()));
grant select(user_id,display_name,approved_at,revoked_at) on public.learning_publishers to anon,authenticated;

create table public.learning_posts (
 id uuid primary key default gen_random_uuid(), author_id uuid not null references public.learning_publishers(user_id),
 title text not null check(length(trim(title)) between 3 and 160), body text not null default '' check(length(body)<=12000),
 topic text not null default 'both' check(topic in ('buyer','seller','both','finance','legal')),
 status text not null default 'draft' check(status in ('draft','published','hidden')),
 likes_count integer not null default 0 check(likes_count>=0), created_at timestamptz not null default now()
);
create index learning_posts_published on public.learning_posts(created_at desc) where status='published';
create index learning_posts_author on public.learning_posts(author_id,created_at desc);
alter table public.learning_posts enable row level security;
create policy learning_posts_read on public.learning_posts for select to anon,authenticated using (
 (status='published' and exists(select 1 from public.learning_publishers p where p.user_id=author_id and p.revoked_at is null))
 or author_id=(select auth.uid()) or (select learning_private.is_owner()));
create policy learning_posts_create on public.learning_posts for insert to authenticated
 with check(author_id=(select auth.uid()) and (select learning_private.can_publish()));
create policy learning_posts_update on public.learning_posts for update to authenticated
 using ((author_id=(select auth.uid()) and (select learning_private.can_publish())) or (select learning_private.is_owner()))
 with check ((author_id=(select auth.uid()) and (select learning_private.can_publish())) or (select learning_private.is_owner()));
grant select on public.learning_posts to anon,authenticated;
grant insert(id,author_id,title,body,topic,status), update(title,body,topic,status) on public.learning_posts to authenticated;

create table public.learning_media (
 id uuid primary key default gen_random_uuid(), post_id uuid not null references public.learning_posts(id) on delete cascade,
 object_path text not null unique, filename text not null check(length(filename) between 1 and 180),
 mime_type text not null check(mime_type in ('image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','video/quicktime','audio/mpeg','audio/wav','audio/mp4','application/pdf')),
 byte_size bigint not null check(byte_size>0 and byte_size<=104857600), position integer not null default 0
);
create index learning_media_post on public.learning_media(post_id,position);
alter table public.learning_media enable row level security;
create policy learning_media_read on public.learning_media for select to anon,authenticated using(exists(select 1 from public.learning_posts p where p.id=post_id and (
 (p.status='published' and exists(select 1 from public.learning_publishers author where author.user_id=p.author_id and author.revoked_at is null))
 or p.author_id=(select auth.uid()) or (select learning_private.is_owner()))));
create policy learning_media_create on public.learning_media for insert to authenticated with check(
 (select learning_private.can_publish()) and exists(select 1 from public.learning_posts p where p.id=post_id and p.author_id=(select auth.uid()))
 and object_path like (select auth.uid())::text || '/' || post_id::text || '/%');
grant select on public.learning_media to anon,authenticated;
grant insert(post_id,object_path,filename,mime_type,byte_size,position) on public.learning_media to authenticated;

create table public.learning_reactions (
 post_id uuid not null references public.learning_posts(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade,
 kind text not null check(kind in ('like','save')), created_at timestamptz not null default now(), primary key(post_id,user_id,kind)
);
create index learning_reactions_user on public.learning_reactions(user_id,kind);
alter table public.learning_reactions enable row level security;
create policy learning_reactions_read on public.learning_reactions for select to authenticated using(user_id=(select auth.uid()));
create policy learning_reactions_create on public.learning_reactions for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.learning_posts p where p.id=post_id and p.status='published'));
create policy learning_reactions_delete on public.learning_reactions for delete to authenticated using(user_id=(select auth.uid()));
grant select, insert, delete on public.learning_reactions to authenticated;
create function learning_private.count_likes() returns trigger language plpgsql security definer set search_path='' as $$
 declare target uuid:=coalesce(new.post_id,old.post_id);
 begin
 perform 1 from public.learning_posts where id=target for update;
 update public.learning_posts set likes_count=(select count(*) from public.learning_reactions r where r.post_id=target and r.kind='like') where id=target;
 return coalesce(new,old);
 end;
$$;
revoke all on function learning_private.count_likes() from public;
create trigger learning_count_likes after insert or delete on public.learning_reactions for each row execute function learning_private.count_likes();

create table public.learning_seminars (
 id uuid primary key default gen_random_uuid(),host_id uuid not null references public.learning_publishers(user_id),
 title text not null check(length(trim(title)) between 3 and 160), description text not null default '' check(length(description)<=6000),
 starts_at timestamptz not null, duration_minutes integer not null default 60 check(duration_minutes between 15 and 480),
 meeting_url text not null check(meeting_url ~ '^https://[^[:space:]]+$'), replay_url text check(replay_url ~ '^https://[^[:space:]]+$'),
 status text not null default 'scheduled' check(status in ('scheduled','live','ended','cancelled')), created_at timestamptz not null default now()
);
create index learning_seminars_schedule on public.learning_seminars(starts_at);
alter table public.learning_seminars enable row level security;
create policy learning_seminars_read on public.learning_seminars for select to anon,authenticated using(exists(select 1 from public.learning_publishers p where p.user_id=host_id and p.revoked_at is null) or (select learning_private.is_owner()));
create policy learning_seminars_create on public.learning_seminars for insert to authenticated with check(host_id=(select auth.uid()) and (select learning_private.can_publish()));
create policy learning_seminars_update on public.learning_seminars for update to authenticated using((host_id=(select auth.uid()) and (select learning_private.can_publish())) or (select learning_private.is_owner())) with check((host_id=(select auth.uid()) and (select learning_private.can_publish())) or (select learning_private.is_owner()));
grant select on public.learning_seminars to anon,authenticated;
grant insert(host_id,title,description,starts_at,duration_minutes,meeting_url,replay_url,status),update(title,description,starts_at,duration_minutes,meeting_url,replay_url,status) on public.learning_seminars to authenticated;
create table public.learning_rsvps (
 seminar_id uuid not null references public.learning_seminars(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,created_at timestamptz not null default now(),primary key(seminar_id,user_id)
);
create index learning_rsvps_user on public.learning_rsvps(user_id);
alter table public.learning_rsvps enable row level security;
create policy learning_rsvps_read on public.learning_rsvps for select to authenticated using(user_id=(select auth.uid()));
create policy learning_rsvps_create on public.learning_rsvps for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.learning_seminars s where s.id=seminar_id and s.status in ('scheduled','live')));
create policy learning_rsvps_delete on public.learning_rsvps for delete to authenticated using(user_id=(select auth.uid()));
grant select,insert,delete on public.learning_rsvps to authenticated;
create table public.learning_progress (
 user_id uuid not null references auth.users(id) on delete cascade,concept_id text not null check(length(concept_id) between 1 and 80),completed_at timestamptz not null default now(), primary key(user_id,concept_id)
);
alter table public.learning_progress enable row level security;
create policy learning_progress_read on public.learning_progress for select to authenticated using(user_id=(select auth.uid()));
create policy learning_progress_create on public.learning_progress for insert to authenticated with check(user_id=(select auth.uid()));
create policy learning_progress_delete on public.learning_progress for delete to authenticated using(user_id=(select auth.uid()));
grant select,insert,delete on public.learning_progress to authenticated;

create function public.learning_permissions() returns jsonb language sql stable security invoker set search_path='' as $$
 select jsonb_build_object('can_publish',learning_private.can_publish(),'is_owner',learning_private.is_owner());
$$;
revoke all on function public.learning_permissions() from public;
grant execute on function public.learning_permissions() to anon,authenticated;
create function learning_private.approve_publisher(target_email text,target_name text,approved boolean) returns void language plpgsql security definer set search_path='' as $$
 declare target uuid;
 begin
 if not learning_private.is_owner() then raise exception 'Creator approval required'; end if;
 select id into target from auth.users where lower(email)=lower(trim(target_email)) and email_confirmed_at is not null;
 if target is null then raise exception 'This person must register and verify their email first'; end if;
 if length(trim(target_name)) not between 2 and 100 then raise exception 'Enter a display name'; end if;
 if target=auth.uid() and not approved then raise exception 'The creator cannot revoke their own access'; end if;
 insert into public.learning_publishers(user_id,display_name,approved_by,revoked_at)
 values(target,trim(target_name),auth.uid(),case when approved then null else now() end)
 on conflict(user_id) do update set display_name=excluded.display_name, approved_by=excluded.approved_by,approved_at=now(),revoked_at=excluded.revoked_at;
 end;
$$;
revoke all on function learning_private.approve_publisher(text,text,boolean) from public;
grant execute on function learning_private.approve_publisher(text,text,boolean) to authenticated;
create function public.approve_learning_publisher(target_email text,target_name text,approved boolean) returns void language sql security invoker set search_path='' as $$
 select learning_private.approve_publisher(target_email,target_name,approved);
$$;
revoke all on function public.approve_learning_publisher(text,text,boolean) from public;
grant execute on function public.approve_learning_publisher(text,text,boolean) to authenticated;
create function learning_private.publisher_list() returns setof jsonb language plpgsql stable security definer set search_path='' as $$
 begin
 if not learning_private.is_owner() then raise exception 'Creator approval required'; end if;
 return query select jsonb_build_object('email',u.email,'display_name',p.display_name,'active',p.revoked_at is null) from public.learning_publishers p join auth.users u on u.id=p.user_id order by p.display_name;
 end;
$$;
revoke all on function learning_private.publisher_list() from public;
grant execute on function learning_private.publisher_list() to authenticated;
create function public.learning_publisher_list() returns setof jsonb language sql stable security invoker set search_path='' as $$select * from learning_private.publisher_list();$$;
revoke all on function public.learning_publisher_list() from public;
grant execute on function public.learning_publisher_list() to authenticated;

-- The existing creator is the first approved publisher. No public posts or fake seminars are seeded.
insert into public.learning_publishers(user_id,display_name,approved_by)
 select u.id,'Will Russell',u.id from auth.users u join public.affinity_admins a on a.user_id=u.id
 where lower(u.email)='rw0882308@gmail.com' and u.email_confirmed_at is not null and a.role='owner';
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('learning-media','learning-media',false,104857600,array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','video/quicktime','audio/mpeg','audio/wav','audio/mp4','application/pdf']);
create policy learning_storage_create on storage.objects for insert to authenticated with check(
 bucket_id='learning-media' and (select learning_private.can_publish()) and (storage.foldername(name))[1]=(select auth.uid())::text
 and exists(select 1 from public.learning_posts p where p.id::text=(storage.foldername(name))[2] and p.author_id=(select auth.uid())));
create policy learning_storage_read on storage.objects for select to anon,authenticated using(
 bucket_id='learning-media' and (exists(select 1 from public.learning_media m join public.learning_posts p on p.id=m.post_id
 join public.learning_publishers author on author.user_id=p.author_id
 where m.object_path=name and p.status='published' and author.revoked_at is null) or (storage.foldername(name))[1]=(select auth.uid())::text or (select learning_private.is_owner())));
create policy learning_storage_delete on storage.objects for delete to authenticated using(bucket_id='learning-media' and ((storage.foldername(name))[1]=(select auth.uid())::text or (select learning_private.is_owner())));
notify pgrst,'reload schema';
