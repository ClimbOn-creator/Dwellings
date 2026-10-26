-- Workspace selection is shared by desktop and mobile and can be made once.
-- This does not grant professional capabilities or change existing data access.
create table public.account_workspaces (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('buyer', 'seller', 'member')),
  created_at timestamptz not null default now()
);
alter table public.account_workspaces enable row level security;
revoke all on public.account_workspaces from public, anon, authenticated;
grant select, insert on public.account_workspaces to authenticated;
grant all on public.account_workspaces to service_role;
create policy "Read own workspace" on public.account_workspaces
  for select to authenticated using (user_id = (select auth.uid()));
create policy "Choose own workspace once" on public.account_workspaces
  for insert to authenticated with check (user_id = (select auth.uid()));
-- No UPDATE or DELETE grant/policy: a client cannot change or reset its choice.
-- Only unambiguous existing professional accounts are recognized automatically.
-- Generic legacy 'user' profiles do not distinguish buyers from sellers.
insert into public.account_workspaces (user_id, role)
select distinct p.owner_user_id, 'member' from public.provider_profiles p
where p.owner_user_id is not null
and not exists (select 1 from public.business_sale_bulletins b where b.created_by_user_id = p.owner_user_id);
