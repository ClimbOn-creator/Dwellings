-- New uploads go to R2. Any pre-existing Supabase attachments keep their original location.
alter table public.learning_media add column storage_backend text not null default 'supabase'
 check(storage_backend in ('supabase','r2'));
grant insert(storage_backend) on public.learning_media to authenticated;
create policy learning_media_draft_cleanup on public.learning_media for delete to authenticated
 using(exists(select 1 from public.learning_posts p where p.id=post_id and p.author_id=(select auth.uid()) and p.status='draft'));
grant delete on public.learning_media to authenticated;
notify pgrst,'reload schema';
