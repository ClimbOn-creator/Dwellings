alter table public.profiles
  add column if not exists preferred_city text;

alter table public.profiles
  add column if not exists preferred_province text;

alter table public.profiles
  add column if not exists preferred_country_code text not null default 'CA';

alter table public.profiles
  drop constraint if exists profiles_preferred_province_check;

alter table public.profiles
  add constraint profiles_preferred_province_check check (
    preferred_province is null or preferred_province in (
      'AB','BC','MB','NB','NL','NS','NT','NU','ON','PE','QC','SK','YT'
    )
  );

create index if not exists profiles_preferred_market_idx
  on public.profiles (preferred_country_code, preferred_province, preferred_city);
