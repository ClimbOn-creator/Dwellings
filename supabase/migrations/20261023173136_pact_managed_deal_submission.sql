-- Retire self-service publication of private buyer assessments. Seller listings
-- and their anonymous briefs remain managed through Pact's checked admin RPCs.
-- Keep existing submissions and saved private deals intact.
revoke execute on function public.submit_deal_to_member_studio(uuid)
  from public, anon, authenticated;
-- Client writes must use the existing authorized management functions. SELECT
-- and its ownership policy remain available for existing records.
revoke insert, update, delete, truncate, references, trigger
  on public.member_deal_opportunities, public.business_sale_bulletins
  from anon, authenticated;
