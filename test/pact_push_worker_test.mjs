import test from 'node:test';
import assert from 'node:assert/strict';
import { run } from '../workers/pact-push/index.js';
const pair=await crypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
const privateKey=Buffer.from(await crypto.subtle.exportKey('pkcs8',pair.privateKey)).toString('base64');
const env={SUPABASE_URL:'https://db.test',SUPABASE_SERVICE_ROLE_KEY:'test',FIREBASE_PROJECT_ID:'test',FIREBASE_CLIENT_EMAIL:'test@example.test',FIREBASE_PRIVATE_KEY:`-----BEGIN PRIVATE KEY-----\n${privateKey}\n-----END PRIVATE KEY-----`};
const json=(value,init)=>Response.json(value,init);
function mock(mode) {
 const requests=[];
 globalThis.fetch=async(url,options={})=>{
  requests.push({url,options});
  if(url==='https://oauth2.googleapis.com/token')return json({access_token:'test'});
  if(url.startsWith('https://fcm.googleapis.com/'))return mode==='transient'?json({error:{status:'UNAVAILABLE'}},{status:503}):json({name:'sent'});
  const u=new URL(url),table=u.pathname.split('/').at(-1);
  if(table==='pact_push_jobs'&&(!options.method||options.method==='GET'))return json([{id:1,revision:2,thread_id:'thread',user_id:'user',attempts:0,available_at:'2026-10-21T12:00:00Z'}]);
  if(table==='pact_push_jobs'&&options.method==='PATCH')return json(mode==='leased'&&u.searchParams.has('available_at')?[]:[{id:1}]);
  if(table==='pact_thread_members')return json(mode==='removed'?[]:[{user_id:'user'}]);
  if(table==='pact_push_devices')return json([{token:'test-device'}]);
  if(options.method==='DELETE')return json([]);
  throw new Error('Unexpected request');
 };
 return requests;
}
test('push contains generic text and only the thread id',async()=>{
 const previous=globalThis.fetch;try{
  const requests=mock('ok');await run(env);
  const sent=requests.find(r=>r.url.startsWith('https://fcm.googleapis.com/'));
  const message=JSON.parse(sent.options.body).message;
  assert.deepEqual(message.data,{thread_id:'thread'});
  assert.equal(message.notification.body,'You have a new conversation update.');
  assert.ok(requests.some(r=>r.url.includes('revision=eq.2')&&r.options.body?.includes('completed_at')));
 }finally{globalThis.fetch=previous;}
});
test('another worker lease prevents a duplicate push',async()=>{
 const previous=globalThis.fetch;try{
  const requests=mock('leased');await run(env);
  assert.equal(requests.filter(r=>r.url.startsWith('https://fcm.googleapis.com/')).length,0);
 }finally{globalThis.fetch=previous;}
});
test('removed members receive no push',async()=>{
 const previous=globalThis.fetch;try{
  const requests=mock('removed');await run(env);
  assert.equal(requests.filter(r=>r.url.startsWith('https://fcm.googleapis.com/')).length,0);
 }finally{globalThis.fetch=previous;}
});

test('a temporary provider failure schedules a retry without completing the job',async()=>{
 const previous=globalThis.fetch;try{
  const requests=mock('transient');await run(env);
  const retry=requests.find(r=>typeof r.options.body==='string' && r.options.body.includes('"attempts":1'));
  assert.ok(retry);assert.ok(retry.url.includes('revision=eq.2'));
  assert.equal(requests.some(r=>typeof r.options.body==='string' && r.options.body.includes('completed_at')),false);
 }finally{globalThis.fetch=previous;}
});
