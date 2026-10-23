// Server-only secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
// FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY.
const encode = value => btoa(typeof value === 'string' ? value : String.fromCharCode(...new Uint8Array(value))).replace(/=/g,'').replace(/\+/g,'-').replace(/\//g,'_');
async function googleToken(env) {
  const seconds = Math.floor(Date.now()/1000);
  const unsigned = `${encode(JSON.stringify({alg:'RS256',typ:'JWT'}))}.${encode(JSON.stringify({iss:env.FIREBASE_CLIENT_EMAIL,scope:'https://www.googleapis.com/auth/firebase.messaging',aud:'https://oauth2.googleapis.com/token',iat:seconds,exp:seconds+3600}))}`;
  const pem = env.FIREBASE_PRIVATE_KEY.replace(/\\n/g,'\n').replace(/-----[^-]+-----/g,'').replace(/\s/g,'');
  const key = await crypto.subtle.importKey('pkcs8',Uint8Array.from(atob(pem),c=>c.charCodeAt(0)),{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['sign']);
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5',key,new TextEncoder().encode(unsigned));
  const response = await fetch('https://oauth2.googleapis.com/token',{method:'POST',body:new URLSearchParams({grant_type:'urn:ietf:params:oauth:grant-type:jwt-bearer',assertion:`${unsigned}.${encode(signature)}`})});
  if(!response.ok) throw new Error('Push provider authentication failed');
  return (await response.json()).access_token;
}
export async function run(env) {
  for(const key of ['SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY','FIREBASE_PROJECT_ID','FIREBASE_CLIENT_EMAIL','FIREBASE_PRIVATE_KEY']) if(!env[key]) throw new Error(`Missing ${key}`);
  const rest = async (path,method='GET',body) => {
    const response=await fetch(`${env.SUPABASE_URL}/rest/v1/${path}`,{method,headers:{apikey:env.SUPABASE_SERVICE_ROLE_KEY,Authorization:`Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,'Content-Type':'application/json',Prefer:'return=representation'},...(body?{body:JSON.stringify(body)}:{})});
    if(!response.ok) throw new Error('Push queue operation failed');
    return response.status===204?[]:response.json();
  };
  // Coalesced per-thread/per-recipient jobs keep storage bounded by memberships.
  const jobs=await rest(`pact_push_jobs?completed_at=is.null&attempts=lt.8&available_at=lte.${encodeURIComponent(new Date().toISOString())}&order=available_at&limit=20`);
  if(!jobs.length) return;
  const access=await googleToken(env);
  for(const job of jobs) {
    const filter=`id=eq.${job.id}&revision=eq.${job.revision}`;
    const lease=await rest(`pact_push_jobs?${filter}&available_at=eq.${encodeURIComponent(job.available_at)}`,'PATCH',{available_at:new Date(Date.now()+120000).toISOString()});
    if(!lease.length) continue;
    try {
      const members=await rest(`pact_thread_members?thread_id=eq.${job.thread_id}&user_id=eq.${job.user_id}&status=in.(accepted,pending)&select=user_id`);
      if(members.length) {
        const devices=await rest(`pact_push_devices?user_id=eq.${job.user_id}&updated_at=gte.${encodeURIComponent(new Date(Date.now()-30*86400000).toISOString())}&select=token`);
        for(const device of devices) {
          const response=await fetch(`https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`,{method:'POST',headers:{Authorization:`Bearer ${access}`,'Content-Type':'application/json'},body:JSON.stringify({message:{token:device.token,notification:{title:'Pact',body:'You have a new conversation update.'},data:{thread_id:job.thread_id},android:{collapse_key:job.thread_id,ttl:'3600s'},apns:{headers:{'apns-collapse-id':job.thread_id,'apns-expiration':String(Math.floor(Date.now()/1000)+3600)}}}})});
          if(!response.ok) {
            const error=await response.json();
            if(error.error?.details?.some(d=>d.errorCode==='UNREGISTERED')) await rest(`pact_push_devices?token=eq.${encodeURIComponent(device.token)}`,'DELETE');
            else throw new Error('Provider rejected push');
          }
        }
      }
      await rest(`pact_push_jobs?${filter}`,'PATCH',{completed_at:new Date().toISOString()});
    } catch (_) {
      await rest(`pact_push_jobs?${filter}`,'PATCH',{attempts:job.attempts+1,available_at:new Date(Date.now()+Math.min(3600000,30000*2**job.attempts)).toISOString()});
    }
  }
  await rest(`pact_push_jobs?completed_at=lt.${encodeURIComponent(new Date(Date.now()-7*86400000).toISOString())}`,'DELETE');
}
export default { async scheduled(_event,env,ctx) { ctx.waitUntil(run(env)); } };
