create table if not exists public.calendar_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('google', 'outlook')),
  access_token_encrypted text not null,
  refresh_token_encrypted text,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, provider)
);

alter table public.calendar_connections enable row level security;

-- Intentionally no client policies: OAuth tokens are accessible only through
-- authenticated Cloudflare functions using the Supabase service role.
revoke all on public.calendar_connections from anon, authenticated;
