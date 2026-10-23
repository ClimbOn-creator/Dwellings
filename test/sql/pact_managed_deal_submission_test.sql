begin;
do $$
begin
  if has_function_privilege('anon', 'public.submit_deal_to_member_studio(uuid)', 'execute')
     or has_function_privilege('authenticated', 'public.submit_deal_to_member_studio(uuid)', 'execute') then
    raise exception 'Retired submission API remains available to clients';
  end if;
  if has_table_privilege('authenticated', 'public.member_deal_opportunities', 'insert')
     or has_table_privilege('authenticated', 'public.business_sale_bulletins', 'insert')
     or has_table_privilege('anon', 'public.member_deal_opportunities', 'truncate') then
    raise exception 'Clients can bypass managed publication';
  end if;
  if not has_function_privilege('authenticated', 'public.save_business_sale_bulletin(uuid,jsonb)', 'execute') then
    raise exception 'Checked Pact management API became unavailable';
  end if;
end $$;
set local role authenticated;
do $$
begin
  begin
    perform public.submit_deal_to_member_studio('00000000-0000-0000-0000-000000000000'::uuid);
    raise exception 'Retired API unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.save_business_sale_bulletin(null, '{}'::jsonb);
    raise exception 'Anonymous actor unexpectedly published a listing';
  exception when raise_exception then
    if sqlerrm = 'Anonymous actor unexpectedly published a listing' then raise; end if;
    if sqlerrm <> 'Sign in to edit a business' then raise; end if;
  end;
end $$;
rollback;
