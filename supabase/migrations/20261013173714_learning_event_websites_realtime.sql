-- Preserve all sessions, content, images and existing approvals.
alter table public.learning_seminars add column website_url text
  check (website_url is null or (length(website_url) <= 2000 and website_url ~ '^https://[^[:space:]/]+'));
grant insert(website_url), update(website_url) on public.learning_seminars to authenticated;
-- Only RLS-authorized event data is sent to each subscriber.
do $$ begin
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='learning_seminars') then
    alter publication supabase_realtime add table public.learning_seminars;
  end if;
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='learning_event_images') then
    alter publication supabase_realtime add table public.learning_event_images;
  end if;
end $$;
notify pgrst, 'reload schema';
