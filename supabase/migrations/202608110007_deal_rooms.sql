alter table public.provider_profiles
  add column if not exists membership_tier text not null default 'free',
  add column if not exists membership_status text not null default 'active';

alter table public.provider_profiles
  drop constraint if exists provider_profiles_membership_tier_check;
alter table public.provider_profiles
  add constraint provider_profiles_membership_tier_check
  check (membership_tier in ('free', 'professional', 'featured'));

alter table public.provider_profiles
  drop constraint if exists provider_profiles_membership_status_check;
alter table public.provider_profiles
  add constraint provider_profiles_membership_status_check
  check (membership_status in ('active', 'trialing', 'past_due', 'cancelled'));

drop policy if exists "Owners can read own professional profile"
  on public.provider_profiles;
drop policy if exists "Owners can update own professional profile"
  on public.provider_profiles;
create policy "Owners can read own professional profile"
  on public.provider_profiles for select using (owner_user_id = auth.uid());
create policy "Owners can update own professional profile"
  on public.provider_profiles for update
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

alter table public.membership_applications
  add column if not exists requested_tier text not null default 'free';
alter table public.membership_applications
  drop constraint if exists membership_applications_requested_tier_check;
alter table public.membership_applications
  add constraint membership_applications_requested_tier_check
  check (requested_tier in ('free', 'professional', 'featured'));

create table if not exists public.deal_rooms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  property_analysis_id uuid references public.property_analyses(id) on delete set null,
  title text not null,
  property_address text not null default '',
  city text not null default '',
  purchase_price numeric not null default 0,
  timeline text not null default '',
  goals text not null default '',
  status text not null default 'active' check (
    status in ('draft', 'active', 'under_offer', 'closing', 'completed', 'archived')
  ),
  property_snapshot jsonb not null default '{}'::jsonb,
  risk_snapshot jsonb not null default '{}'::jsonb,
  sharing_preferences jsonb not null default '{"financials":true,"risk":true,"documents":false}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deal_room_members (
  id uuid primary key default gen_random_uuid(),
  deal_room_id uuid not null references public.deal_rooms(id) on delete cascade,
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  invited_by uuid not null references auth.users(id) on delete cascade,
  status text not null default 'invited' check (
    status in ('invited', 'accepted', 'declined', 'removed')
  ),
  access_level text not null default 'standard' check (
    access_level in ('summary', 'standard', 'full')
  ),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  unique (deal_room_id, provider_id)
);

create table if not exists public.deal_room_tasks (
  id uuid primary key default gen_random_uuid(),
  deal_room_id uuid not null references public.deal_rooms(id) on delete cascade,
  title text not null,
  category text not null default 'general',
  assigned_provider_id uuid references public.provider_profiles(id) on delete set null,
  completed boolean not null default false,
  due_at timestamptz,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deal_room_notes (
  id uuid primary key default gen_random_uuid(),
  deal_room_id uuid not null references public.deal_rooms(id) on delete cascade,
  author_user_id uuid not null references auth.users(id) on delete cascade,
  note_text text not null check (char_length(note_text) between 1 and 4000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deal_room_documents (
  id uuid primary key default gen_random_uuid(),
  deal_room_id uuid not null references public.deal_rooms(id) on delete cascade,
  uploaded_by uuid not null references auth.users(id) on delete cascade,
  object_key text not null unique,
  file_name text not null,
  file_size bigint not null default 0,
  content_type text not null default 'application/octet-stream',
  created_at timestamptz not null default now()
);

create index if not exists deal_rooms_user_updated_idx
  on public.deal_rooms(user_id, updated_at desc);
create index if not exists deal_room_members_provider_idx
  on public.deal_room_members(provider_id, status);
create index if not exists deal_room_tasks_room_position_idx
  on public.deal_room_tasks(deal_room_id, position);
create index if not exists deal_room_notes_room_created_idx
  on public.deal_room_notes(deal_room_id, created_at desc);
create index if not exists deal_room_documents_room_created_idx
  on public.deal_room_documents(deal_room_id, created_at desc);

create or replace function public.can_access_deal_room(target_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.deal_rooms room
    where room.id = target_room_id and room.user_id = auth.uid()
  ) or exists (
    select 1
    from public.deal_room_members member
    join public.provider_profiles provider on provider.id = member.provider_id
    where member.deal_room_id = target_room_id
      and provider.owner_user_id = auth.uid()
      and member.status in ('invited', 'accepted')
  );
$$;

grant execute on function public.can_access_deal_room(uuid) to authenticated;

alter table public.deal_rooms enable row level security;
alter table public.deal_room_members enable row level security;
alter table public.deal_room_tasks enable row level security;
alter table public.deal_room_notes enable row level security;
alter table public.deal_room_documents enable row level security;

drop policy if exists "Clients manage own deal rooms" on public.deal_rooms;
drop policy if exists "Professionals read shared deal rooms" on public.deal_rooms;
create policy "Clients manage own deal rooms" on public.deal_rooms
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Professionals read shared deal rooms" on public.deal_rooms
  for select using (public.can_access_deal_room(id));

drop policy if exists "Clients manage own deal room members" on public.deal_room_members;
drop policy if exists "Professionals read own deal room invitations" on public.deal_room_members;
drop policy if exists "Participants read deal room roster" on public.deal_room_members;
create policy "Clients manage own deal room members" on public.deal_room_members
  for all using (
    exists (
      select 1 from public.deal_rooms room
      where room.id = deal_room_id and room.user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.deal_rooms room
      where room.id = deal_room_id and room.user_id = auth.uid()
    )
  );
create policy "Professionals read own deal room invitations" on public.deal_room_members
  for select using (
    exists (
      select 1 from public.provider_profiles provider
      where provider.id = provider_id and provider.owner_user_id = auth.uid()
    )
  );
create policy "Participants read deal room roster" on public.deal_room_members
  for select using (public.can_access_deal_room(deal_room_id));

drop policy if exists "Participants read deal room tasks" on public.deal_room_tasks;
drop policy if exists "Participants update deal room tasks" on public.deal_room_tasks;
drop policy if exists "Clients create deal room tasks" on public.deal_room_tasks;
drop policy if exists "Clients delete deal room tasks" on public.deal_room_tasks;
create policy "Participants read deal room tasks" on public.deal_room_tasks
  for select using (public.can_access_deal_room(deal_room_id));
create policy "Participants update deal room tasks" on public.deal_room_tasks
  for update using (public.can_access_deal_room(deal_room_id))
  with check (public.can_access_deal_room(deal_room_id));
create policy "Clients create deal room tasks" on public.deal_room_tasks
  for insert with check (
    exists (
      select 1 from public.deal_rooms room
      where room.id = deal_room_id and room.user_id = auth.uid()
    )
  );
create policy "Clients delete deal room tasks" on public.deal_room_tasks
  for delete using (
    exists (
      select 1 from public.deal_rooms room
      where room.id = deal_room_id and room.user_id = auth.uid()
    )
  );

drop policy if exists "Participants read deal room notes" on public.deal_room_notes;
drop policy if exists "Participants create deal room notes" on public.deal_room_notes;
drop policy if exists "Authors manage own deal room notes" on public.deal_room_notes;
create policy "Participants read deal room notes" on public.deal_room_notes
  for select using (public.can_access_deal_room(deal_room_id));
create policy "Participants create deal room notes" on public.deal_room_notes
  for insert with check (
    public.can_access_deal_room(deal_room_id) and author_user_id = auth.uid()
  );
create policy "Authors manage own deal room notes" on public.deal_room_notes
  for update using (author_user_id = auth.uid())
  with check (author_user_id = auth.uid());

drop policy if exists "Participants read deal room documents" on public.deal_room_documents;
drop policy if exists "Participants upload deal room documents" on public.deal_room_documents;
drop policy if exists "Uploaders delete own deal room documents" on public.deal_room_documents;
create policy "Participants read deal room documents" on public.deal_room_documents
  for select using (public.can_access_deal_room(deal_room_id));
create policy "Participants upload deal room documents" on public.deal_room_documents
  for insert with check (
    public.can_access_deal_room(deal_room_id) and uploaded_by = auth.uid()
  );
create policy "Uploaders delete own deal room documents" on public.deal_room_documents
  for delete using (uploaded_by = auth.uid());

create or replace function public.respond_to_deal_room_invite(
  membership_id uuid,
  invite_status text
)
returns public.deal_room_members
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_membership public.deal_room_members;
begin
  if invite_status not in ('accepted', 'declined') then
    raise exception 'Invalid invitation status';
  end if;

  update public.deal_room_members member
  set status = invite_status, responded_at = now()
  where member.id = membership_id
    and exists (
      select 1 from public.provider_profiles provider
      where provider.id = member.provider_id
        and provider.owner_user_id = auth.uid()
    )
  returning member.* into updated_membership;

  if updated_membership.id is null then
    raise exception 'Invitation not found or access denied';
  end if;
  return updated_membership;
end;
$$;

grant execute on function public.respond_to_deal_room_invite(uuid, text)
  to authenticated;

comment on table public.deal_rooms is
  'A private, permissioned workspace generated from a saved property analysis.';
