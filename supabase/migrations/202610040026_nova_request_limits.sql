-- Private, atomic per-account request budget. No conversations or deal facts are stored.
create table if not exists public.nova_request_limits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  hour_start timestamptz not null,
  hour_count integer not null default 0,
  day_start date not null,
  day_count integer not null default 0
);
alter table public.nova_request_limits enable row level security;
revoke all on public.nova_request_limits from anon, authenticated;
create or replace function public.consume_nova_request()
returns boolean language plpgsql security definer set search_path = public as $$
declare
  who uuid := auth.uid();
  hour_now timestamptz := date_trunc('hour', now());
  day_now date := (now() at time zone 'UTC')::date;
  limits public.nova_request_limits%rowtype;
begin
  if who is null then return false; end if;
  insert into public.nova_request_limits(user_id, hour_start, day_start)
    values(who, hour_now, day_now) on conflict (user_id) do nothing;
  select * into limits from public.nova_request_limits where user_id = who for update;
  if limits.hour_start <> hour_now then limits.hour_count := 0; end if;
  if limits.day_start <> day_now then limits.day_count := 0; end if;
  if limits.hour_count >= 20 or limits.day_count >= 100 then return false; end if;
  update public.nova_request_limits set hour_start = hour_now, hour_count = limits.hour_count + 1,
    day_start = day_now, day_count = limits.day_count + 1 where user_id = who;
  return true;
end;
$$;
revoke all on function public.consume_nova_request() from public, anon;
grant execute on function public.consume_nova_request() to authenticated;
