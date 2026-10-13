import {validMedia} from './learning-media.js';
const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const formats={jpg:'image/jpeg',jpeg:'image/jpeg',png:'image/png',webp:'image/webp'};
const MAX=5*1024*1024;
const headers=(request,env)=>({apikey:env.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json',...(request.headers.get('Authorization')?{Authorization:request.headers.get('Authorization')}:{})});
const error=(message,status)=>Response.json({error:message},{status});
async function rest(request,env,table,params,options={}){
 const url=new URL(`${env.SUPABASE_URL}/rest/v1/${table}`);for(const [k,v]of Object.entries(params))url.searchParams.set(k,v);
 const r=await fetch(url,{...options,headers:{...headers(request,env),Prefer:'return=representation,resolution=merge-duplicates'}});if(!r.ok)throw new Error('Access denied');return r.json();
}
async function upload({request,env}){
 const origin=request.headers.get('Origin');if(origin&&origin!==new URL(request.url).origin)return error('Origin not allowed',403);
 if(!request.headers.get('Authorization')?.startsWith('Bearer '))return error('Sign in to publish',401);
 const auth=await fetch(`${env.SUPABASE_URL}/auth/v1/user`,{headers:headers(request,env)});if(!auth.ok)return error('Sign in to publish',401);const actor=await auth.json();
 const permission=await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/learning_permissions`,{method:'POST',headers:headers(request,env),body:'{}'});
 if(!permission.ok||!(await permission.json()).can_publish)return error('Creator approval is required',403);
 if(Number(request.headers.get('Content-Length'))>MAX+65536)return error('Maximum image size is 5 MB',413);
 const data=await request.formData(),file=data.get('file'),id=data.get('eventId');if(!uuid.test(id||''))return error('Choose a valid event',400);
 const events=await rest(request,env,'learning_seminars',{id:`eq.${id}`,host_id:`eq.${actor.id}`,select:'id'});if(events.length!==1)return error('Only your own event image can be uploaded',403);
 if(!(file instanceof File)||!file.size||file.size>MAX)return error('Select an image up to 5 MB',400);
 const ext=file.name.split('.').pop().toLowerCase(),mime=formats[ext];
 if(!mime||!['',mime,'application/octet-stream'].includes(file.type)||!validMedia(new Uint8Array(await file.slice(0,32).arrayBuffer()),mime))return error('Use a genuine JPG, PNG or WebP image',415);
 const previous=await rest(request,env,'learning_event_images',{seminar_id:`eq.${id}`,select:'object_path'});
 const path=`${actor.id}/${id}/${crypto.randomUUID()}.${ext}`,key=`events/${path}`;
 await env.LEARNING_MEDIA.put(key,file.stream(),{httpMetadata:{contentType:mime}});
 try{
 const [saved]=await rest(request,env,'learning_event_images',{on_conflict:'seminar_id'},{method:'POST',body:JSON.stringify({seminar_id:id,object_path:path,filename:file.name.replace(/[\r\n]/g,'_').slice(-180),mime_type:mime,byte_size:file.size})});
 if(!saved?.id)throw new Error('Registration failed');
 // A replacement cleans only this host's previous event cover, after registration succeeds.
 const old=previous[0]?.object_path;if(old?.startsWith(`${actor.id}/${id}/`))try{await env.LEARNING_MEDIA.delete(`events/${old}`);}catch(_){}
 return Response.json({id:saved.id},{status:201});
 }catch(_){await env.LEARNING_MEDIA.delete(key);return error('The event image could not be registered',403);}
}
async function read({request,env}){
 const id=new URL(request.url).searchParams.get('id');if(!uuid.test(id||''))return error('Image not found',404);
 let rows;try{rows=await rest(request,env,'learning_event_images',{id:`eq.${id}`,select:'object_path,mime_type'});}catch(_){return error('Image not found',404);}
 const row=rows[0];if(!row||!Object.values(formats).includes(row.mime_type)||!/^[0-9a-f-]{36}\/[0-9a-f-]{36}\/[0-9a-f-]{36}\.(jpg|jpeg|png|webp)$/i.test(row.object_path))return error('Image not found',404);
 const object=await env.LEARNING_MEDIA.get(`events/${row.object_path}`);if(!object)return error('Image not found',404);
 return new Response(object.body,{headers:{'Content-Type':row.mime_type,'Content-Length':String(object.size),'Cache-Control':'private, no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'none'; sandbox"}});
}
const guard=handler=>async context=>{if(!context.env.LEARNING_MEDIA||!context.env.SUPABASE_URL||!context.env.SUPABASE_PUBLISHABLE_KEY)return error('Event image storage unavailable',503);try{return await handler(context);}catch(_){return error('The event image request failed',503);}};
export const onRequestPost=guard(upload);export const onRequestGet=guard(read);
