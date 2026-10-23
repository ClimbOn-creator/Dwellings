-- Read-only, bounded aggregation of existing bookmarks. No event log or media.
create or replace function pact_private.seller_listing_insights(days integer default 7)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
  if days not in (7,30,90) then raise exception 'Choose 7, 30 or 90 days'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'listing_id', b.id,
    'daily_saves', (select coalesce(jsonb_agg(jsonb_build_object('day', d.day, 'count', d.n) order by d.day), '[]'::jsonb)
      from (select (s.saved_at at time zone 'UTC')::date as day, count(*) as n
        from public.saved_business_sale_bulletins s
        where s.bulletin_id=b.id and s.saved_at >= ((now() at time zone 'UTC')::date - (days-1))::timestamp at time zone 'UTC'
        group by 1) d)
    ) order by b.updated_at desc), '[]'::jsonb) into result
  from public.business_sale_bulletins b where b.created_by_user_id=auth.uid();
  return result;
end $$;
revoke all on function pact_private.seller_listing_insights(integer) from public,anon;
grant execute on function pact_private.seller_listing_insights(integer) to authenticated;
create or replace function public.pact_seller_listing_insights(days integer default 7)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select pact_private.seller_listing_insights(days);
$$;
revoke all on function public.pact_seller_listing_insights(integer) from public,anon;
grant execute on function public.pact_seller_listing_insights(integer) to authenticated;
