create table if not exists public.provider_reviews (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  review_text text not null default '' check (char_length(review_text) <= 2000),
  reviewer_name text not null default 'DwellingsIQ member',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider_id, user_id)
);

create index if not exists provider_reviews_provider_created_idx
  on public.provider_reviews(provider_id, created_at desc);

alter table public.provider_reviews enable row level security;

create or replace function public.set_provider_review_identity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.user_id := auth.uid();
  select coalesce(nullif(trim(full_name), ''), nullif(trim(display_name), ''), 'DwellingsIQ member')
  into new.reviewer_name
  from public.profiles
  where id = auth.uid();
  new.reviewer_name := coalesce(new.reviewer_name, 'DwellingsIQ member');
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists provider_reviews_set_identity on public.provider_reviews;
create trigger provider_reviews_set_identity
before insert or update on public.provider_reviews
for each row execute function public.set_provider_review_identity();

drop policy if exists "Public can read provider reviews" on public.provider_reviews;
drop policy if exists "Members can create own provider reviews" on public.provider_reviews;
drop policy if exists "Members can update own provider reviews" on public.provider_reviews;
drop policy if exists "Members can delete own provider reviews" on public.provider_reviews;

create policy "Public can read provider reviews"
  on public.provider_reviews for select using (true);

create policy "Members can create own provider reviews"
  on public.provider_reviews for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.provider_profiles provider
      where provider.id = provider_id
        and provider.verified = true
        and provider.is_example = false
        and provider.owner_user_id is distinct from auth.uid()
    )
  );

create policy "Members can update own provider reviews"
  on public.provider_reviews for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.provider_profiles provider
      where provider.id = provider_id
        and provider.verified = true
        and provider.is_example = false
        and provider.owner_user_id is distinct from auth.uid()
    )
  );

create policy "Members can delete own provider reviews"
  on public.provider_reviews for delete using (auth.uid() = user_id);

create or replace function public.refresh_provider_review_summary()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_provider_id uuid := coalesce(new.provider_id, old.provider_id);
begin
  update public.provider_profiles
  set
    review_score = coalesce((
      select round(avg(rating)::numeric, 2)
      from public.provider_reviews
      where provider_id = target_provider_id
    ), 0),
    review_count = (
      select count(*)
      from public.provider_reviews
      where provider_id = target_provider_id
    ),
    updated_at = now()
  where id = target_provider_id;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists provider_reviews_refresh_summary on public.provider_reviews;
create trigger provider_reviews_refresh_summary
after insert or update or delete on public.provider_reviews
for each row execute function public.refresh_provider_review_summary();

comment on table public.provider_reviews is
  'One signed-in member review per verified professional. Example profiles and self-reviews are excluded.';
