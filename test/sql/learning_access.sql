-- Run as a database administrator. All fixture data and approvals roll back.
begin;
select set_config('learning.test.owner', (select u.id::text from auth.users u where lower(email)='rw0882308@gmail.com'),true);
select set_config('learning.test.other', (select u.id::text from auth.users u where lower(email)='dfisch5@gmail.com'),true);
with fixture as (insert into public.learning_posts(author_id,title,body,status) values(current_setting('learning.test.owner')::uuid,'Learning access test','Transaction-only fixture','draft') returning id)
select set_config('learning.test.post',(select id::text from fixture),true);
insert into public.learning_media(post_id,object_path,filename,mime_type,byte_size)
values(current_setting('learning.test.post')::uuid,current_setting('learning.test.owner')||'/'||current_setting('learning.test.post')||'/test.png','test.png','image/png',10);
select set_config('request.jwt.claims','{}',true);
select set_config('request.jwt.claim.sub','',true);
set local role anon;
do $$ begin
 if exists(select 1 from public.learning_posts where id=current_setting('learning.test.post')::uuid) then raise exception 'Draft exposed to anon';end if;
 if exists(select 1 from public.learning_media where post_id=current_setting('learning.test.post')::uuid) then raise exception 'Draft media exposed to anon';end if;
 if (public.learning_permissions()->>'can_publish')::boolean then raise exception 'Anonymous publishing allowed';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.test.owner'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin
 if not (public.learning_permissions()->>'is_owner')::boolean then raise exception 'Creator owner denied';end if;
 if not exists(select 1 from public.learning_media where post_id=current_setting('learning.test.post')::uuid) then raise exception 'Owner draft access denied';end if;
end $$;
update public.learning_posts set status='published' where id=current_setting('learning.test.post')::uuid;
reset role;
select set_config('request.jwt.claims','{}',true);
set local role anon;
do $$ begin
 if not exists(select 1 from public.learning_posts where id=current_setting('learning.test.post')::uuid) then raise exception 'Published post missing';end if;
 if not exists(select 1 from public.learning_media where post_id=current_setting('learning.test.post')::uuid) then raise exception 'Published media missing';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.test.other'),'role','authenticated')::text,true);
set local role authenticated;
do $$ declare denied boolean:=false; begin
 if (public.learning_permissions()->>'can_publish')::boolean then raise exception 'Unapproved account allowed to publish';end if;
 begin insert into public.learning_posts(author_id,title) values(current_setting('learning.test.other')::uuid,'Blocked post');exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Post insert bypassed approval';end if;
 denied:=false;
 begin perform public.approve_learning_publisher('dfisch5@gmail.com','Other creator',true);exception when raise_exception then if sqlerrm='Creator approval required' then denied:=true;else raise;end if;end;
 if not denied then raise exception 'Non-creator granted approval';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.test.owner'),'role','authenticated')::text,true);
set local role authenticated;
select public.approve_learning_publisher('dfisch5@gmail.com','Test contributor',true);
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.test.other'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin if not (public.learning_permissions()->>'can_publish')::boolean then raise exception 'Approved publisher denied';end if;end $$;
insert into public.learning_reactions(post_id,user_id,kind) values(current_setting('learning.test.post')::uuid,current_setting('learning.test.other')::uuid,'like');
do $$ begin if (select likes_count from public.learning_posts where id=current_setting('learning.test.post')::uuid)<>1 then raise exception 'Like count incorrect';end if;end $$;
delete from public.learning_reactions where post_id=current_setting('learning.test.post')::uuid;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.test.owner'),'role','authenticated')::text,true);
set local role authenticated;
select public.approve_learning_publisher('dfisch5@gmail.com','Test contributor',false);
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.test.other'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin if (public.learning_permissions()->>'can_publish')::boolean then raise exception 'Revocation did not take effect';end if;end $$;
rollback;
select 'PASS: draft privacy, published reads, creator approval, unapproved write rejection, likes and revocation' as result;
