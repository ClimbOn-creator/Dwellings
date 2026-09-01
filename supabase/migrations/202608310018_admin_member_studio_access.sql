-- Gives Affinity administrators the same privacy-safe opportunity feed that
-- verified members can browse, without exposing buyer identity or raw records.

create or replace function public.browse_admin_member_deals()
returns table (
  id uuid,
  headline text,
  industry text,
  region text,
  summary text,
  stage text,
  purchase_price_band text,
  capital_required_band text,
  affinity_score integer,
  score_label text,
  support_needed text[],
  published_at timestamptz,
  match_score integer,
  match_reason text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_affinity_admin() then
    raise exception 'Affinity administrator access required';
  end if;

  return query
  select opportunity.id,
         opportunity.headline,
         opportunity.industry,
         opportunity.region,
         opportunity.summary,
         opportunity.stage,
         opportunity.purchase_price_band,
         opportunity.capital_required_band,
         opportunity.affinity_score,
         opportunity.score_label,
         opportunity.support_needed,
         opportunity.published_at,
         100::integer as match_score,
         'Affinity administrator access'::text as match_reason
  from public.member_deal_opportunities opportunity
  where opportunity.status = 'published'
  order by opportunity.published_at desc;
end;
$$;

revoke all on function public.browse_admin_member_deals() from public;
grant execute on function public.browse_admin_member_deals() to authenticated;
