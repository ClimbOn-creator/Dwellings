alter table public.lead_requests
  add column if not exists member_message text,
  add column if not exists responded_at timestamptz;

drop policy if exists "Provider owners can read assigned introductions"
  on public.lead_requests;

create policy "Provider owners can read assigned introductions"
  on public.lead_requests for select using (
    exists (
      select 1
      from public.provider_profiles provider
      where provider.id = provider_id
        and provider.owner_user_id = auth.uid()
    )
  );

create or replace function public.respond_to_introduction(
  introduction_id uuid,
  response_status text,
  response_message text default null
)
returns public.lead_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_request public.lead_requests;
begin
  if response_status not in ('accepted', 'declined', 'contacted', 'closed') then
    raise exception 'Invalid introduction status';
  end if;

  update public.lead_requests request
  set
    status = response_status,
    member_message = nullif(trim(response_message), ''),
    responded_at = now()
  where request.id = introduction_id
    and exists (
      select 1
      from public.provider_profiles provider
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

grant execute on function public.respond_to_introduction(uuid, text, text)
  to authenticated;

comment on function public.respond_to_introduction(uuid, text, text) is
  'Allows the authenticated owner of a professional profile to respond to an assigned introduction without exposing unrestricted lead update access.';
