begin;
select set_config('learning.test.owner',(select id::text from auth.users where lower(email)='rw0882308@gmail.com'),true);
select set_config('learning.test.other',(select id::text from auth.users where lower(email)='dfisch5@gmail.com'),true);
select set_config('learning.test.near',gen_random_uuid()::text,true);
select set_config('learning.test.far',gen_random_uuid()::text,true);
select set_config('learning.test.reply',gen_random_uuid()::text,true);
insert into public.learning_posts(id,author_id,title,body,topic,status,area_name,latitude,longitude,likes_count,created_at) values
(current_setting('learning.test.near')::uuid,current_setting('learning.test.owner')::uuid,'Temporary local test','', 'both','published','Vancouver, BC',49.3,-123.1,100,now()-interval '2 days'),
(current_setting('learning.test.far')::uuid,current_setting('learning.test.owner')::uuid,'Temporary distant test','', 'both','published','Halifax, NS',44.6,-63.6,0,now()),
(current_setting('learning.test.reply')::uuid,current_setting('learning.test.owner')::uuid,'Temporary near test','', 'both','published','Nearby test area',50.8,-123.1,0,now());
-- Precise device coordinates are rejected even through direct API writes.
do $$ declare denied boolean:=false;begin
 begin update public.learning_posts set latitude=49.261111 where id=current_setting('learning.test.near')::uuid;exception when check_violation then denied:=true;end;
 if not denied then raise exception 'Exact location was accepted';end if;
end $$;
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ begin
 if not exists(select 1 from public.learning_local_feed(49.3,-123.1) where post_id=current_setting('learning.test.near')::uuid) then raise exception 'Local post missing';end if;
 if exists(select 1 from public.learning_local_feed(49.3,-123.1) where post_id=current_setting('learning.test.far')::uuid) then raise exception 'Distant post leaked into local feed';end if;
 if (select post_id from public.learning_local_feed(49.3,-123.1) limit 1)<>current_setting('learning.test.near')::uuid then raise exception 'Likes did not affect recommended order';end if;
 if (select post_id from public.learning_local_feed(49.3,-123.1,'newest') limit 1)<>current_setting('learning.test.reply')::uuid then raise exception 'Newest order incorrect';end if;
end $$;
do $$ declare denied boolean:=false;begin
 begin insert into public.learning_comments(post_id,author_id,body)values(current_setting('learning.test.near')::uuid,current_setting('learning.test.other')::uuid,'Anonymous comment');exception when insufficient_privilege then denied:=true;end;
 if not denied then raise exception 'Anonymous comment accepted';end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.test.other'),'role','authenticated')::text,true);
set local role authenticated;
with added as(insert into public.learning_comments(post_id,author_id,body) values(current_setting('learning.test.near')::uuid,auth.uid(),'Temporary root comment')returning id) select set_config('learning.test.comment',id::text,true) from added;
-- A learner can comment without publishing approval.
insert into public.learning_comments(post_id,author_id,parent_id,body)values(current_setting('learning.test.near')::uuid,auth.uid(),current_setting('learning.test.comment')::uuid,'Temporary threaded reply');
do $$ declare denied boolean:=false;begin
 if(select comments_count from public.learning_posts where id=current_setting('learning.test.near')::uuid)<>2 then raise exception 'Comment counter incorrect';end if;
 if not exists(select 1 from public.learning_comments where parent_id=current_setting('learning.test.comment')::uuid and depth=1) then raise exception 'Reply depth incorrect';end if;
 begin insert into public.learning_comments(post_id,author_id,parent_id,body)values(current_setting('learning.test.reply')::uuid,auth.uid(),current_setting('learning.test.comment')::uuid,'Cross post reply');exception when raise_exception then if sqlerrm='Reply must belong to the same post' then denied:=true;else raise;end if;end;
 if not denied then raise exception 'Cross post reply accepted';end if;
end $$;
insert into public.learning_preferences(user_id,area_name,latitude,longitude)values(auth.uid(),'Vancouver, BC',49.3,-123.1);
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('learning.test.owner'),'role','authenticated')::text,true);
set local role authenticated;
do $$ begin if exists(select 1 from public.learning_preferences where user_id=current_setting('learning.test.other')::uuid) then raise exception 'Other account location preferences exposed';end if;end $$;
-- Creator moderation leaves a tombstone and preserves replies.
update public.learning_comments set body='',removed_at=now() where id=current_setting('learning.test.comment')::uuid;
reset role;
select set_config('request.jwt.claims','{"role":"anon"}',true);
set local role anon;
do $$ begin
 if not exists(select 1 from public.learning_comments where id=current_setting('learning.test.comment')::uuid and body='' and removed_at is not null) then raise exception 'Removal tombstone missing';end if;
 if not exists(select 1 from public.learning_comments where parent_id=current_setting('learning.test.comment')::uuid) then raise exception 'Thread replies lost';end if;
 if(select comments_count from public.learning_posts where id=current_setting('learning.test.near')::uuid)<>1 then raise exception 'Removal counter incorrect';end if;
end $$;
reset role;
rollback;
select 'PASS: 200km feed, ranking, coarse location, authenticated comments, cross-post denial, private preferences and moderated threads' as result;
