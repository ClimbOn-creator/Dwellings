// Run with PGLITE_MODULE pointing to a temporary @electric-sql/pglite installation.
// No live database or credentials are used.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const { PGlite } = await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
await db.exec(`
create role anon; create role authenticated;
create schema auth; create schema storage;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as
$$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create table public.affinity_admins(user_id uuid primary key);
create function public.is_affinity_admin() returns boolean language sql stable as
$$ select exists(select 1 from public.affinity_admins where user_id = auth.uid()) $$;
create table public.member_deal_opportunities(id uuid primary key);
create table public.member_saved_deals(user_id uuid, opportunity_id uuid);
create table public.affinity_audit_events(actor_user_id uuid,event_type text,entity_type text,entity_id uuid,metadata jsonb);
create table public.business_sale_bulletins(
 id uuid primary key default gen_random_uuid(), created_by_user_id uuid references auth.users,
 title text, industry text, region text, asking_price_band text, summary text,
 source_label text, source_url text, status text default 'active',
 converted_opportunity_id uuid, posted_at timestamptz default now(), updated_at timestamptz default now());
create table public.test_notifications(user_id uuid, action_module text, entity_id uuid);
create function public.create_affinity_notification(uuid,text,text,text,text,text,uuid)
returns void language sql as $$ insert into public.test_notifications values($1,$5,$7) $$;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(bucket_id text,name text);
create function storage.foldername(text) returns text[] language sql immutable as $$ select string_to_array($1,'/') $$;
`);
const migration = await readFile(new URL('../../supabase/migrations/202609050024_bulletin_listing_updates.sql', import.meta.url), 'utf8');
await db.exec(migration);
await db.exec(migration); // safe to rerun
const admin = '00000000-0000-0000-0000-000000000001';
const user = '00000000-0000-0000-0000-000000000002';
const member = '00000000-0000-0000-0000-000000000003';
const outsider = '00000000-0000-0000-0000-000000000004';
for (const id of [admin,user,member,outsider]) await db.query('insert into auth.users values($1)', [id]);
await db.query('insert into affinity_admins values($1)', [admin]);
const asUser = id => db.query("select set_config('request.jwt.claim.sub',$1,false)", [id]);
await asUser(admin);
const listing = {title:'Example service business',industry:'Services',region:'Victoria',asking_price_band:'$500,000',
 summary:'Established service business with a strong operating team.',details:{photos:[],revenue:'$1,000,000'}};
const save = (id,payload) => db.query('select save_business_sale_bulletin($1,$2::jsonb) id', [id,JSON.stringify(payload)]);
const id = (await save(null, listing)).rows[0].id;
const current = async () => (await db.query('select * from browse_business_sale_bulletins_v2($1)',[id])).rows[0].browse_business_sale_bulletins_v2;
const notifications = async () => (await db.query('select * from test_notifications')).rows;
assert.equal((await notifications()).length,0, 'creation must not broadcast');
for (const account of [user,member]) {
 await asUser(account);
 await db.query('select set_business_sale_bulletin_saved($1,true)',[id]);
 await db.query('select set_business_sale_bulletin_saved($1,true)',[id]); // idempotent save
 assert.equal((await current()).is_saved,true);
 assert.equal((await current()).can_edit,false);
}
await asUser(outsider);
assert.equal((await current()).is_saved,false);
await assert.rejects(save(id,{...listing,expected_updated_at:(await current()).updated_at}), /cannot edit/);
await assert.rejects(save(null,listing), /Administrator access/);
await asUser(admin);
const initial = await current();
await save(id,{...listing,expected_updated_at:initial.updated_at});
assert.equal((await notifications()).length,0,'no-op edits must not notify');
await save(id,{...listing,summary:listing.summary+' New contracts.',expected_updated_at:initial.updated_at});
assert.deepEqual((await notifications()).map(n=>n.user_id).sort(),[user,member].sort(), 'only savers, not owner or outsiders');
assert.ok((await notifications()).every(n=>n.action_module==='bulletin-board' && n.entity_id===id));
await assert.rejects(save(id,{...listing,expected_updated_at:initial.updated_at}), /changed since/);
await asUser(user);
await db.query('select set_business_sale_bulletin_saved($1,false)',[id]);
await asUser(admin);
await save(id,{...listing,expected_updated_at:(await current()).updated_at,asking_price_band:'$450,000'});
assert.equal((await notifications()).length,3);
assert.equal((await notifications())[2].user_id, member, 'unsaved account receives no future update');
await assert.rejects(save(id,{...listing,expected_updated_at:(await current()).updated_at,details:{photos:['javascript:alert(1)']}}), /complete http/);
await asUser('');
await assert.rejects(db.query('select set_business_sale_bulletin_saved($1,true)',[id]), /Sign in/);
await assert.rejects(save(id,listing), /Sign in/);
assert.equal((await current()).can_edit,false);
assert.equal((await current()).is_saved,false);
// Verify row policies separately from the privileged RPC execution context.
await db.exec('grant usage on schema auth to authenticated;');
await asUser(member);
await db.exec('set role authenticated;');
assert.deepEqual((await db.query('select user_id from saved_business_sale_bulletins')).rows.map(r=>r.user_id), [member]);
await db.exec('reset role;');

// Existing anonymous opportunities follow the same saved-only content rule.
await db.exec(`alter table member_deal_opportunities
  add column owner_user_id uuid, add column status text, add column headline text,
  add column summary text, add column industry text, add column region text,
  add column stage text, add column purchase_price_band text, add column capital_required_band text,
  add column public_details jsonb, add column support_needed jsonb,
  add column affinity_score numeric, add column last_reposted_at timestamptz;`);
const opportunity = '00000000-0000-0000-0000-000000000010';
await db.query("insert into member_deal_opportunities(id,owner_user_id,status,headline,summary) values($1,$2,'published','Anonymous opportunity','Original summary')",[opportunity,admin]);
await db.query('insert into member_saved_deals values($1,$2)',[member,opportunity]);
await db.exec('create trigger opportunity_audit after update on member_deal_opportunities for each row execute function audit_member_studio_opportunity();');
const count = (await notifications()).length;
await asUser(admin);
await db.query("update member_deal_opportunities set summary='Updated summary' where id=$1",[opportunity]);
assert.equal((await notifications()).length,count+1);
assert.equal((await notifications())[count].user_id,member);
await db.query("update member_deal_opportunities set summary='Updated summary' where id=$1",[opportunity]);
assert.equal((await notifications()).length,count+1);
await db.query('delete from member_saved_deals where opportunity_id=$1',[opportunity]);
await db.query("update member_deal_opportunities set summary='Another update' where id=$1",[opportunity]);
assert.equal((await notifications()).length,count+1);
await db.close();
console.log('PASS: migration reruns, permissions, conflict detection, saved-only notifications, no-op and unsave behaviour, URL validation.');
