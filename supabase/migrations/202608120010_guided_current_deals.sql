-- Guided Current Deals command centre.
-- Run after 202608110009_dual_marketplace.sql.

alter table public.deal_rooms
  add column if not exists deal_kind text not null default 'residential',
  add column if not exists current_stage text not null default 'discovery',
  add column if not exists target_close_date date,
  add column if not exists archived_at timestamptz;

alter table public.deal_rooms
  drop constraint if exists deal_rooms_deal_kind_check;
alter table public.deal_rooms
  add constraint deal_rooms_deal_kind_check
  check (deal_kind in ('residential', 'commercial', 'business'));

alter table public.deal_rooms
  drop constraint if exists deal_rooms_status_check;
alter table public.deal_rooms
  add constraint deal_rooms_status_check
  check (status in (
    'draft', 'active', 'under_offer', 'closing', 'completed', 'cancelled', 'archived'
  ));

update public.deal_rooms
set deal_kind = case
  when transaction_type = 'business' then 'business'
  when coalesce(property_snapshot->>'propertyType', '') in (
    'office', 'retail', 'industrial', 'multifamily', 'mixedUse', 'land', 'hospitality'
  ) then 'commercial'
  else 'residential'
end
where deal_kind = 'residential';

update public.deal_rooms
set current_stage = case status
  when 'draft' then 'discovery'
  when 'under_offer' then 'offer'
  when 'closing' then 'closing'
  when 'completed' then 'complete'
  when 'archived' then 'complete'
  else current_stage
end;

alter table public.deal_room_tasks
  add column if not exists details text not null default '',
  add column if not exists stage text not null default 'discovery',
  add column if not exists task_status text not null default 'not_started',
  add column if not exists blocker_note text not null default '';

alter table public.deal_room_tasks
  drop constraint if exists deal_room_tasks_task_status_check;
alter table public.deal_room_tasks
  add constraint deal_room_tasks_task_status_check
  check (task_status in ('not_started', 'in_progress', 'blocked', 'completed'));

update public.deal_room_tasks
set task_status = case when completed then 'completed' else 'not_started' end,
    stage = case category
      when 'planning' then 'discovery'
      when 'financing' then 'financing'
      when 'confidentiality' then 'screening'
      when 'financial' then 'diligence'
      when 'commercial' then 'diligence'
      when 'operations' then 'diligence'
      when 'people' then 'diligence'
      when 'technology' then 'diligence'
      when 'tax' then 'structure'
      when 'transition' then 'transition'
      when 'legal' then 'legal'
      when 'property' then 'diligence'
      when 'closing' then 'closing'
      else 'discovery'
    end;

create index if not exists deal_rooms_user_lifecycle_idx
  on public.deal_rooms(user_id, status, target_close_date, updated_at desc);
create index if not exists deal_room_tasks_stage_status_idx
  on public.deal_room_tasks(deal_room_id, stage, task_status, position);

comment on column public.deal_rooms.current_stage is
  'Current guided workflow stage selected by the deal owner.';
comment on column public.deal_room_tasks.blocker_note is
  'Short explanation of what prevents this task from moving forward.';
