-- Additive: keep existing posts, attachments, site copy and saved reaction records.
-- Public coordinates describe broad community areas, never exact device positions.
-- Both database and client enforce 0.1-degree (roughly 10 km) precision.
alter table public.learning_posts add column area_name text,
 add column latitude double precision check(latitude between -90 and 90 and latitude=round(latitude::numeric,1)::double precision),
 add column longitude double precision check(longitude between -180 and 180 and longitude=round(longitude::numeric,1)::double precision),
 add column comments_count integer not null default 0 check(comments_count>=0),
 add constraint learning_post_area_pair check((latitude is null)=(longitude is null));
grant insert(area_name,latitude,longitude), update(area_name,latitude,longitude) on public.learning_posts to authenticated;
create index learning_posts_location on public.learning_posts(latitude,longitude) where status='published';

create table public.learning_preferences (
 user_id uuid primary key references auth.users(id) on delete cascade,
 area_name text not null check(length(area_name) between 1 and 120),
 latitude double precision not null check(latitude between -90 and 90 and latitude=round(latitude::numeric,1)::double precision),
 longitude double precision not null check(longitude between -180 and 180 and longitude=round(longitude::numeric,1)::double precision)
);
alter table public.learning_preferences enable row level security;
revoke all on public.learning_preferences from anon,authenticated;
grant select,insert,update on public.learning_preferences to authenticated;
create policy learning_preferences_own_read on public.learning_preferences for select to authenticated using(user_id=(select auth.uid()));
create policy learning_preferences_own_insert on public.learning_preferences for insert to authenticated with check(user_id=(select auth.uid()));
create policy learning_preferences_own_update on public.learning_preferences for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));

create table public.learning_comments (
 id uuid primary key default gen_random_uuid(), post_id uuid not null references public.learning_posts(id),
 author_id uuid not null references auth.users(id), author_name text not null default 'Learner',
 parent_id uuid, depth integer not null default 0 check(depth between 0 and 8),
 body text not null, created_at timestamptz not null default now(), removed_at timestamptz,
 unique(id,post_id), foreign key(parent_id,post_id) references public.learning_comments(id,post_id),
 check((removed_at is null and length(trim(body)) between 1 and 2000) or (removed_at is not null and body=''))
);
create index learning_comments_post on public.learning_comments(post_id,created_at,id);
create index learning_comments_author on public.learning_comments(author_id,created_at);
create index learning_comments_parent on public.learning_comments(parent_id,post_id);
alter table public.learning_comments enable row level security;
revoke all on public.learning_comments from anon,authenticated;
grant select on public.learning_comments to anon,authenticated;
grant insert(post_id,author_id,parent_id,body),update(body,removed_at) on public.learning_comments to authenticated;
create policy learning_comments_read on public.learning_comments for select to anon,authenticated using(exists(
 select 1 from public.learning_posts p join public.learning_publishers a on a.user_id=p.author_id
 where p.id=post_id and p.status='published' and a.revoked_at is null));
create policy learning_comments_insert on public.learning_comments for insert to authenticated with check(
 author_id=(select auth.uid()) and exists(select 1 from public.learning_posts p join public.learning_publishers a on a.user_id=p.author_id
 where p.id=post_id and p.status='published' and a.revoked_at is null));
create policy learning_comments_remove on public.learning_comments for update to authenticated using(
 author_id=(select auth.uid()) or (select learning_private.is_owner())) with check(author_id=(select auth.uid()) or (select learning_private.is_owner()));

create function learning_private.comment_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare parent public.learning_comments; display text;
begin
 if tg_op='INSERT' then
  if auth.uid() is null or new.author_id<>auth.uid() then raise exception 'Comment author must be the signed in learner';end if;
  if (select count(*) from public.learning_comments where author_id=auth.uid() and created_at>now()-interval '5 minutes')>=20 then raise exception 'Please wait before adding more comments';end if;
  select coalesce(nullif(trim(display_name),''),nullif(trim(full_name),''),'Learner') into display from public.profiles where id=auth.uid();
  new.author_name:=left(coalesce(display,'Learner'),100);
  if new.parent_id is not null then
   select * into parent from public.learning_comments where id=new.parent_id and post_id=new.post_id;
   if parent.id is null then raise exception 'Reply must belong to the same post';end if;
   if parent.removed_at is not null then raise exception 'This comment was removed; reply to another comment';end if;
   new.depth:=parent.depth+1;
  end if;
 else
  if new.removed_at is null or old.removed_at is not null then raise exception 'Comments can only be removed once';end if;
  new.body:='';new.removed_at:=now();
 end if;
 return new;
end $$;
revoke all on function learning_private.comment_guard() from public,anon,authenticated;
create trigger learning_comment_guard before insert or update on public.learning_comments for each row execute function learning_private.comment_guard();
create function learning_private.comment_count() returns trigger language plpgsql security definer set search_path='' as $$
begin
 update public.learning_posts set comments_count=comments_count+case when tg_op='INSERT' then 1 else -1 end where id=new.post_id;
 return new;
end $$;
revoke all on function learning_private.comment_count() from public,anon,authenticated;
create trigger learning_comment_count after insert or update of removed_at on public.learning_comments for each row execute function learning_private.comment_count();

create function public.learning_local_feed(latitude double precision,longitude double precision,feed_order text default 'recommended')
 returns table(post_id uuid,distance_km double precision) language sql stable security invoker set search_path='' as $$
 with nearby as (
 select p.id,p.created_at,p.likes_count,p.comments_count,
  6371.0088*2*asin(sqrt(least(1.0,power(sin(radians(p.latitude-$1)/2),2)+cos(radians($1))*cos(radians(p.latitude))*power(sin(radians(p.longitude-$2)/2),2)))) as km
 from public.learning_posts p join public.learning_publishers a on a.user_id=p.author_id
 where p.status='published' and a.revoked_at is null and p.latitude is not null
 and $1 between -90 and 90 and $2 between -180 and 180
 and abs(p.latitude-$1)<=1.8
 )
 select id,km from nearby where km<=200
 order by case when feed_order='newest' then extract(epoch from created_at)
 else (1+ln(1+likes_count)*3+ln(1+comments_count)*1.5)/(power(1+greatest(0,extract(epoch from(now()-created_at))/3600)/24,0.65))+(1-km/200)*0.25 end desc,
 created_at desc,id
 limit 100;
$$;
revoke all on function public.learning_local_feed(double precision,double precision,text) from public;
grant execute on function public.learning_local_feed(double precision,double precision,text) to anon,authenticated;
notify pgrst,'reload schema';
