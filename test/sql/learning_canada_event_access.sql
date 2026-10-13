begin;
select set_config('learning.event.owner',(select id::text from auth.users where lower(email)='rw0882308@gmail.com'),true);
select set_config('learning.event.host',(select id::text from auth.users where lower(email)='dfisch5@gmail.com'),true);
select set_config('learning.event.id',gen_random_uuid()::text,true);
select set_config('learning.event.cover',gen_random_uuid()::text,true);
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.event.owner'),'role','authenticated')::text,true);
set local role authenticated;
select public.approve_learning_publisher('dfisch5@gmail.com','Temporary event host',false);
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.event.host'),'role','authenticated')::text,true);
set local role authenticated;
do $$ declare denied boolean:=false;begin
 begin insert into public.learning_seminars(host_id,title,starts_at,duration_minutes,meeting_url) values(auth.uid(),'Temporary event test',now()+interval '2 days',60,'https://example.com/meeting');exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Unapproved event publishing accepted';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.event.owner'),'role','authenticated')::text,true);
set local role authenticated;
select public.approve_learning_publisher('dfisch5@gmail.com','Temporary event host',true);
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.event.host'),'role','authenticated')::text,true);
set local role authenticated;
insert into public.learning_seminars(id,host_id,title,starts_at,duration_minutes,meeting_url,organization,event_kind,event_mode,area_name,latitude,longitude,venue,website_url)
 values(current_setting('learning.event.id')::uuid,auth.uid(),'Temporary map event',now()+interval '2 days',60,null,'Temporary Chamber','meeting','in_person','Vancouver, BC',49.3,-123.1,'Community hall','https://example.com/organizer');
with added as(insert into public.learning_event_images(seminar_id,object_path,filename,mime_type,byte_size) values(current_setting('learning.event.id')::uuid,auth.uid()::text||'/'||current_setting('learning.event.id')||'/'||current_setting('learning.event.cover')||'.png','cover.png','image/png',8) returning id) select set_config('learning.event.cover',id::text,true) from added;
reset role;
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ begin
 if exists(select 1 from public.learning_seminars where id=current_setting('learning.event.id')::uuid) then raise exception 'Private draft event exposed';end if;
 if exists(select 1 from public.learning_event_images where id=current_setting('learning.event.cover')::uuid) then raise exception 'Private draft cover exposed';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.event.host'),'role','authenticated')::text,true);
set local role authenticated;
update public.learning_seminars set is_published=true where id=current_setting('learning.event.id')::uuid;
reset role;
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ begin
 if not exists(select 1 from public.learning_seminars where id=current_setting('learning.event.id')::uuid and organization='Temporary Chamber' and latitude=49.3 and website_url='https://example.com/organizer') then raise exception 'Published event missing';end if;
 if not exists(select 1 from public.learning_event_images where id=current_setting('learning.event.cover')::uuid) then raise exception 'Published cover missing';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.event.owner'),'role','authenticated')::text,true);
set local role authenticated;
do $$ declare denied boolean:=false;begin
 begin update public.learning_event_images set object_path=auth.uid()::text||'/'||current_setting('learning.event.id')||'/'||gen_random_uuid()::text||'.png' where id=current_setting('learning.event.cover')::uuid;exception when insufficient_privilege then denied:=true;end;
 -- RLS may deny UPDATE by returning zero rows. Either form must leave the owner's path intact.
 if exists(select 1 from public.learning_event_images where id=current_setting('learning.event.cover')::uuid and object_path like auth.uid()::text||'/%') then raise exception 'Another host cover reassigned';end if;
end $$;
select public.approve_learning_publisher('dfisch5@gmail.com','Temporary event host',false);
reset role;
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ begin
 if exists(select 1 from public.learning_seminars where id=current_setting('learning.event.id')::uuid) then raise exception 'Revoked host event exposed';end if;
 if exists(select 1 from public.learning_event_images where id=current_setting('learning.event.cover')::uuid) then raise exception 'Revoked host cover exposed';end if;
end $$;
reset role;
rollback;
select 'PASS: approved-only event publishing, private drafts/photos, public event previews, cover ownership and revocation' as result;
