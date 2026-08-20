create table if not exists public.affinity_content_editors (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.site_content (
  content_key text primary key check (char_length(content_key) between 3 and 120),
  content_value text not null check (char_length(content_value) <= 12000),
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.affinity_content_editors enable row level security;
alter table public.site_content enable row level security;

drop policy if exists "Everyone reads published site content" on public.site_content;
create policy "Everyone reads published site content"
  on public.site_content for select using (true);

create or replace function public.is_affinity_content_editor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.affinity_content_editors editor
    where editor.user_id = auth.uid()
  );
$$;

grant execute on function public.is_affinity_content_editor() to authenticated;

create or replace function public.save_site_content(target_key text, target_value text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_affinity_content_editor() then
    raise exception 'Affinity content editor access required';
  end if;
  if char_length(trim(target_key)) not between 3 and 120 then
    raise exception 'Invalid content key';
  end if;
  if char_length(target_value) > 12000 then
    raise exception 'Content is too long';
  end if;

  insert into public.site_content (content_key, content_value, updated_by, updated_at)
  values (trim(target_key), target_value, auth.uid(), now())
  on conflict (content_key) do update set
    content_value = excluded.content_value,
    updated_by = excluded.updated_by,
    updated_at = excluded.updated_at;
end;
$$;

grant execute on function public.save_site_content(text, text) to authenticated;

insert into public.affinity_content_editors (user_id)
select id from auth.users
where lower(email) in ('rw0882308@gmail.com', 'dfisch5@gmail.com')
on conflict (user_id) do nothing;

comment on table public.site_content is
  'Published Affinity interface copy. Only explicitly allow-listed editors may save through save_site_content.';
