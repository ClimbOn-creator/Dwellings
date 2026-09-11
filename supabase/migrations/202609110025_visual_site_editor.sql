begin;

-- Resolve the verified account on each request, including first sign-in after
-- this migration. User-editable profile metadata cannot grant editor access.
create or replace function public.is_affinity_content_editor()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from auth.users u where u.id = auth.uid()
      and u.email_confirmed_at is not null
      and (lower(u.email) in ('rw0882308@gmail.com', 'dfisch5@gmail.com')
        or exists (select 1 from public.affinity_content_editors e where e.user_id = u.id))
  );
$$;
revoke all on function public.is_affinity_content_editor() from public;
grant execute on function public.is_affinity_content_editor() to anon, authenticated;

-- Serialize writes to the same key, including first publication and resets.
create or replace function public.save_site_content_v2(
  target_key text, target_value text, expected_value text
) returns void language plpgsql security definer set search_path = public as $$
declare current_value text;
begin
  if not public.is_affinity_content_editor() then
    raise exception 'Affinity content editor access required';
  end if;
  if target_key is null or char_length(target_key) not between 3 and 120
     or target_key <> trim(target_key) then raise exception 'Invalid content key'; end if;
  if char_length(target_value) > 12000 then raise exception 'Content is too long'; end if;
  if target_key like 'image.%' and target_value is not null and
     target_value !~ '^https://[^/]+/storage/v1/object/public/site-media/[a-f0-9-]+/[a-zA-Z0-9.-]+\.(jpg|jpeg|png|webp)$'
     then raise exception 'Upload a site image first'; end if;
  perform pg_advisory_xact_lock(hashtextextended(target_key, 0));
  select content_value into current_value from public.site_content where content_key = target_key;
  if current_value is distinct from expected_value then
    raise exception 'This content changed since you opened it';
  end if;
  if target_value is null then
    delete from public.site_content where content_key = target_key;
  else
    insert into public.site_content(content_key, content_value, updated_by, updated_at)
    values(target_key, target_value, auth.uid(), now())
    on conflict(content_key) do update set content_value = excluded.content_value,
      updated_by = excluded.updated_by, updated_at = excluded.updated_at;
  end if;
end;
$$;
revoke all on function public.save_site_content_v2(text, text, text) from public, anon;
grant execute on function public.save_site_content_v2(text, text, text) to authenticated;
grant select on public.site_content to anon, authenticated;
revoke insert, update, delete on public.site_content from anon, authenticated;
revoke all on public.affinity_content_editors from anon, authenticated;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values('site-media', 'site-media', true, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Editors upload site media" on storage.objects;
create policy "Editors upload site media" on storage.objects for insert to authenticated
with check (bucket_id = 'site-media' and public.is_affinity_content_editor()
  and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Editors remove own unused site media" on storage.objects;
create policy "Editors remove own unused site media" on storage.objects for delete to authenticated
using (bucket_id = 'site-media' and public.is_affinity_content_editor()
  and (storage.foldername(name))[1] = auth.uid()::text
  and not exists(select 1 from public.site_content c where c.content_value like '%' || '/site-media/' || name));
drop policy if exists "Read site media" on storage.objects;
create policy "Read site media" on storage.objects for select using (bucket_id = 'site-media');
commit;
