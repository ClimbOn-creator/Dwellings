-- Professional onboarding, lead pipeline and audited private Deal Room files.

alter table public.membership_applications
  add column if not exists professional_attestation boolean not null default false;

alter table public.provider_profiles
  add column if not exists onboarding_status text not null default 'draft',
  add column if not exists verification_notes text not null default '',
  add column if not exists specialties text[] not null default '{}',
  add column if not exists service_markets text[] not null default '{}',
  add column if not exists onboarding_completed_at timestamptz;

create unique index if not exists provider_profiles_one_owned_profile_idx
  on public.provider_profiles(owner_user_id)
  where owner_user_id is not null and is_example = false;

alter table public.provider_profiles
  drop constraint if exists provider_profiles_onboarding_status_check;
alter table public.provider_profiles
  add constraint provider_profiles_onboarding_status_check
  check (onboarding_status in ('draft', 'submitted', 'reviewing', 'needs_information', 'verified', 'declined', 'suspended'));

drop policy if exists "Professionals create own draft profile" on public.provider_profiles;
create policy "Professionals create own draft profile"
  on public.provider_profiles for insert
  with check (
    owner_user_id = auth.uid()
    and verified = false
    and onboarding_status in ('draft', 'submitted')
  );

drop policy if exists "Owners can update own professional profile" on public.provider_profiles;
create policy "Owners can update own professional profile"
  on public.provider_profiles for update
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

-- A professional may maintain their listing, but verification is a platform
-- decision. Dashboard/SQL administrators (where auth.uid() is null) retain the
-- ability to review an application without exposing that ability through RLS.
create or replace function public.protect_provider_review_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and auth.uid() = old.owner_user_id then
    new.verified := old.verified;
    new.verification_notes := old.verification_notes;
    if new.onboarding_status not in ('draft', 'submitted', 'needs_information') then
      new.onboarding_status := old.onboarding_status;
    end if;
    if new.onboarding_status = 'submitted' and old.onboarding_status <> 'submitted' then
      new.onboarding_completed_at := now();
    else
      new.onboarding_completed_at := old.onboarding_completed_at;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_provider_review_fields_trigger on public.provider_profiles;
create trigger protect_provider_review_fields_trigger
before update on public.provider_profiles
for each row execute function public.protect_provider_review_fields();

alter table public.lead_requests
  add column if not exists deal_room_id uuid references public.deal_rooms(id) on delete set null,
  add column if not exists lead_type text not null default 'general',
  add column if not exists budget_range text not null default '',
  add column if not exists preferred_contact text not null default 'email',
  add column if not exists next_follow_up_at timestamptz,
  add column if not exists provider_notes text not null default '',
  add column if not exists closed_reason text not null default '',
  add column if not exists updated_at timestamptz not null default now();

alter table public.lead_requests
  drop constraint if exists lead_requests_status_check;
alter table public.lead_requests
  add constraint lead_requests_status_check
  check (status in ('new', 'accepted', 'qualified', 'contacted', 'consultation', 'won', 'lost', 'declined', 'closed'));

alter table public.lead_requests
  drop constraint if exists lead_requests_preferred_contact_check;
alter table public.lead_requests
  add constraint lead_requests_preferred_contact_check
  check (preferred_contact in ('email', 'phone', 'either'));

create index if not exists lead_requests_provider_pipeline_idx
  on public.lead_requests(provider_id, status, next_follow_up_at, updated_at desc);

drop function if exists public.respond_to_introduction(uuid, text, text);

create or replace function public.respond_to_introduction(
  introduction_id uuid,
  response_status text,
  response_message text default null,
  follow_up_at timestamptz default null,
  private_notes text default null,
  loss_reason text default null
)
returns public.lead_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_request public.lead_requests;
begin
  if response_status not in ('accepted', 'qualified', 'contacted', 'consultation', 'won', 'lost', 'declined', 'closed') then
    raise exception 'Invalid introduction status';
  end if;

  update public.lead_requests request
  set status = response_status,
      member_message = coalesce(nullif(trim(response_message), ''), request.member_message),
      next_follow_up_at = follow_up_at,
      provider_notes = coalesce(nullif(trim(private_notes), ''), request.provider_notes),
      closed_reason = case when response_status in ('lost', 'declined', 'closed')
        then coalesce(nullif(trim(loss_reason), ''), request.closed_reason) else '' end,
      responded_at = coalesce(request.responded_at, now()),
      updated_at = now()
  where request.id = introduction_id
    and exists (
      select 1 from public.provider_profiles provider
      where provider.id = request.provider_id
        and provider.owner_user_id = auth.uid()
    )
  returning request.* into updated_request;

  if updated_request.id is null then
    raise exception 'Introduction not found or access denied';
  end if;
  return updated_request;
end;
$$;

grant execute on function public.respond_to_introduction(uuid, text, text, timestamptz, text, text)
  to authenticated;

alter table public.deal_room_documents
  add column if not exists sha256 text not null default '',
  add column if not exists security_status text not null default 'validated',
  add column if not exists category text not null default 'general',
  add column if not exists deleted_at timestamptz;

alter table public.deal_room_documents
  drop constraint if exists deal_room_documents_security_status_check;
alter table public.deal_room_documents
  add constraint deal_room_documents_security_status_check
  check (security_status in ('quarantined', 'validated', 'rejected'));

create table if not exists public.deal_room_document_events (
  id uuid primary key default gen_random_uuid(),
  deal_room_id uuid not null references public.deal_rooms(id) on delete cascade,
  document_id uuid references public.deal_room_documents(id) on delete set null,
  actor_user_id uuid not null references auth.users(id) on delete restrict,
  event_type text not null check (event_type in ('uploaded', 'viewed', 'downloaded', 'deleted', 'access_denied')),
  file_name text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists deal_room_document_events_room_created_idx
  on public.deal_room_document_events(deal_room_id, created_at desc);

alter table public.deal_room_document_events enable row level security;

create or replace function public.can_access_deal_documents(target_room_id uuid)
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
    from public.deal_rooms room
    join public.deal_room_members member on member.deal_room_id = room.id
    join public.provider_profiles provider on provider.id = member.provider_id
    where room.id = target_room_id
      and provider.owner_user_id = auth.uid()
      and member.status = 'accepted'
      and coalesce((room.sharing_preferences ->> 'documents')::boolean, false)
  );
$$;

grant execute on function public.can_access_deal_documents(uuid) to authenticated;

drop policy if exists "Participants read document audit events" on public.deal_room_document_events;
drop policy if exists "Participants create own document audit events" on public.deal_room_document_events;
create policy "Participants read document audit events"
  on public.deal_room_document_events for select
  using (public.can_access_deal_documents(deal_room_id));
create policy "Participants create own document audit events"
  on public.deal_room_document_events for insert
  with check (
    actor_user_id = auth.uid()
    and public.can_access_deal_documents(deal_room_id)
  );

-- Business documents may now be uploaded, but only through the authenticated
-- Cloudflare file API. The database record remains protected by Deal Room RLS.
drop policy if exists "Participants upload property room documents" on public.deal_room_documents;
drop policy if exists "Participants upload deal room documents" on public.deal_room_documents;
drop policy if exists "Participants upload secure deal room documents" on public.deal_room_documents;
drop policy if exists "Participants read deal room documents" on public.deal_room_documents;
create policy "Participants read secure deal room documents"
  on public.deal_room_documents for select
  using (public.can_access_deal_documents(deal_room_id));
create policy "Participants upload secure deal room documents"
  on public.deal_room_documents for insert
  with check (
    public.can_access_deal_documents(deal_room_id)
    and uploaded_by = auth.uid()
    and security_status in ('quarantined', 'validated')
  );

drop policy if exists "Deal owners delete room documents" on public.deal_room_documents;
drop policy if exists "Uploaders delete own deal room documents" on public.deal_room_documents;
create policy "Deal owners delete room documents"
  on public.deal_room_documents for delete
  using (
    uploaded_by = auth.uid()
    or exists (
      select 1 from public.deal_rooms room
      where room.id = deal_room_id and room.user_id = auth.uid()
    )
  );
