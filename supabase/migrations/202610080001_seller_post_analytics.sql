-- Private seller analytics. No public content or listings are modified.
create or replace function public.seller_business_posts()
returns setof jsonb
language sql stable security definer set search_path = public
as $$
  select (to_jsonb(b) - 'created_by_user_id') || jsonb_build_object(
    'can_edit', true,
    'save_count', (select count(*) from public.saved_business_sale_bulletins s where s.bulletin_id = b.id)
  )
  from public.business_sale_bulletins b
  where auth.uid() is not null and b.created_by_user_id = auth.uid()
  order by b.updated_at desc;
$$;
revoke all on function public.seller_business_posts() from public;
grant execute on function public.seller_business_posts() to authenticated;
