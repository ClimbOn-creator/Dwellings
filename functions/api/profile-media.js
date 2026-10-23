// Public account portraits and covers only. Private files never use this route.
const MAX=8*1024*1024;
const uuid=/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i;
const production='https://dwelling-iq-app.pages.dev';
const fail=(message,status)=>Response.json({error:message},{status});
const headers=(request,env)=>({apikey:env.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json',...(request.headers.get('Authorization')?{Authorization:request.headers.get('Authorization')}:{})});
export function validProfilePng(bytes){
 if(bytes.length<33||![137,80,78,71,13,10,26,10].every((v,i)=>bytes[i]===v))return false;
 const view=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength);
 const width=view.getUint32(16),height=view.getUint32(20);
 return String.fromCharCode(...bytes.slice(12,16))==='IHDR'&&view.getUint32(8)===13&&width>0&&height>0&&width<=2400&&height<=2400&&width*height<=5760000;
}
async function limitedBytes(request){
 const reader=request.body?.getReader();if(!reader)return null;
 let size=0;const chunks=[];
 try{while(true){const {done,value}=await reader.read();if(done)break;size+=value.byteLength;if(size>MAX){await reader.cancel();return null;}chunks.push(value);}}finally{reader.releaseLock();}
 const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}return bytes;
}
async function upload({request,env}){
 const origin=request.headers.get('Origin');if(origin&&origin!==new URL(request.url).origin&&origin!==production)return fail('Origin not allowed',403);
 if(!request.headers.get('Authorization')?.startsWith('Bearer '))return fail('Sign in to upload a profile image',401);
 const actorResponse=await fetch(`${env.SUPABASE_URL}/auth/v1/user`,{headers:headers(request,env)});
 if(!actorResponse.ok)return fail('Sign in again to upload',401);
 const actor=await actorResponse.json();if(!uuid.test(actor.id||''))return fail('Invalid account',401);
 const slot=new URL(request.url).searchParams.get('slot');if(!['avatar','cover'].includes(slot))return fail('Choose portrait or cover',400);
 if(request.headers.get('Content-Type')!=='image/png')return fail('Choose an image using the photo picker',415);
 if(Number(request.headers.get('Content-Length'))>MAX)return fail('Image must be under 8 MB',413);
 const bytes=await limitedBytes(request);if(!bytes)return fail('Image must be under 8 MB',413);
 if(!validProfilePng(bytes))return fail('Invalid or oversized image',415);
 const id=crypto.randomUUID(),key=`profiles/${actor.id}/${slot}/${id}.png`;
 await env.PROPERTY_FILES.put(key,bytes,{httpMetadata:{contentType:'image/png'},customMetadata:{ownerId:actor.id,slot}});
 let saved,response;
 try{
  response=await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/pact_register_profile_media`,{method:'POST',headers:headers(request,env),body:JSON.stringify({p_slot:slot,p_id:id,p_bytes:bytes.length})});
 }catch(_){
  // A lost response may follow a committed transaction. Keep the new object;
  // deleting it could break the confirmed profile. The client reloads to reconcile.
  return fail('Upload confirmation was interrupted. Refresh your profile before trying again.',503);
 }
 if(!response.ok){await env.PROPERTY_FILES.delete(key);return fail('Image could not be saved. Your existing image is unchanged. Please retry.',409);}
 try{saved=await response.json();if(!saved?.url)throw new Error('Missing confirmation');}
 catch(_){return fail('Upload confirmation was interrupted. Refresh your profile before trying again.',503);}
 // Registration has committed. Never turn a cleanup error into a failed save.
 if(saved.previous_key&&saved.previous_key!==key&&saved.previous_key.startsWith(`profiles/${actor.id}/${slot}/`)){
  try{await env.PROPERTY_FILES.delete(saved.previous_key);}catch(_){/* Current image stays available; retry cleanup operationally. */}
 }
 return Response.json({url:saved.url},{status:201});
}
async function read({request,env}){
 const id=new URL(request.url).searchParams.get('id');if(!uuid.test(id||''))return fail('Image not found',404);
 const url=new URL(`${env.SUPABASE_URL}/rest/v1/pact_profile_media`);url.searchParams.set('id',`eq.${id}`);url.searchParams.set('select','owner_id,slot,id,object_key');
 // Deliberately use anonymous access, regardless of browser cookies or bearer tokens.
 const result=await fetch(url,{headers:{apikey:env.SUPABASE_PUBLISHABLE_KEY}});if(!result.ok)return fail('Image not found',404);
 const [row]=await result.json();if(!row||!uuid.test(row.owner_id||'')||!['avatar','cover'].includes(row.slot)||row.object_key!==`profiles/${row.owner_id}/${row.slot}/${id}.png`)return fail('Image not found',404);
 const object=await env.PROPERTY_FILES.get(row.object_key);if(!object)return fail('Image not found',404);
 return new Response(request.method==='HEAD'?null:object.body,{headers:{'Content-Type':'image/png','Access-Control-Allow-Origin':'*','Cross-Origin-Resource-Policy':'cross-origin','Cache-Control':'public, max-age=300','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'none'; sandbox",'Content-Length':String(object.size)}});
}
function guard(fn){return async context=>{if(!context.env.PROPERTY_FILES||!context.env.SUPABASE_URL||!context.env.SUPABASE_PUBLISHABLE_KEY)return fail('Profile image storage unavailable',503);try{return await fn(context);}catch(_){return fail('Profile image request failed. Please retry.',503);}};}
export const onRequestPost=guard(upload);
export const onRequestGet=guard(read);
export const onRequestHead=guard(read);
