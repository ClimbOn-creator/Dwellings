const MAX_BYTES=90*1024*1024;
const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const formats={jpg:'image/jpeg',jpeg:'image/jpeg',png:'image/png',webp:'image/webp',gif:'image/gif',mp4:'video/mp4',webm:'video/webm',mov:'video/quicktime',mp3:'audio/mpeg',wav:'audio/wav',m4a:'audio/mp4',pdf:'application/pdf'};
function starts(bytes,values,offset=0){return values.every((v,i)=>bytes[offset+i]===v);}
function ascii(bytes,text,offset=0){return starts(bytes,[...text].map(c=>c.charCodeAt(0)),offset);}
export function validMedia(bytes,mime){
 switch(mime){
 case 'image/jpeg':return starts(bytes,[255,216,255]);
 case 'image/png':return starts(bytes,[137,80,78,71,13,10,26,10]);
 case 'image/webp':return ascii(bytes,'RIFF')&&ascii(bytes,'WEBP',8);
 case 'image/gif':return ascii(bytes,'GIF87a')||ascii(bytes,'GIF89a');
 case 'video/mp4':case 'audio/mp4':return ascii(bytes,'ftyp',4);
 case 'video/quicktime':return ['ftyp','moov','mdat','wide'].some(t=>ascii(bytes,t,4));
 case 'video/webm':return starts(bytes,[26,69,223,163]);
 case 'audio/mpeg':return ascii(bytes,'ID3')||(bytes[0]===255&&(bytes[1]&224)===224);
 case 'audio/wav':return ascii(bytes,'RIFF')&&ascii(bytes,'WAVE',8);
 case 'application/pdf':return ascii(bytes,'%PDF-');default:return false;
 }
}
function headers(request,env,{anon=false}={}){const token=anon?'':request.headers.get('Authorization');return {apikey:env.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json',...(token?{Authorization:token}:{})};}
async function rest(request,env,table,params,options={}){
 const endpoint=new URL(`${env.SUPABASE_URL}/rest/v1/${table}`);for(const [key,value] of Object.entries(params))endpoint.searchParams.set(key,value);
 const r=await fetch(endpoint,{...options,headers:{...headers(request,env),Prefer:'return=representation'}});if(!r.ok)throw new Error('Database access denied');return r.status===204?[]:r.json();
}
async function user(request,env){if(!request.headers.get('Authorization')?.startsWith('Bearer '))return null;const r=await fetch(`${env.SUPABASE_URL}/auth/v1/user`,{headers:headers(request,env)});return r.ok?r.json():null;}
async function permission(request,env){const r=await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/learning_permissions`,{method:'POST',headers:headers(request,env),body:'{}'});return r.ok?r.json():{};}
function error(message,status){return Response.json({error:message},{status});}
function ready(env){return env.LEARNING_MEDIA&&env.SUPABASE_URL&&env.SUPABASE_PUBLISHABLE_KEY;}
async function upload({request,env}){
 if(!ready(env))return error('Learning media storage is unavailable',503);
 const origin=request.headers.get('Origin');if(origin&&origin!==new URL(request.url).origin)return error('Origin not allowed',403);
 const actor=await user(request,env);if(!actor)return error('Sign in to upload',401);
 if(!(await permission(request,env)).can_publish)return error('Creator approval is required to publish',403);
 if(Number(request.headers.get('Content-Length'))>MAX_BYTES+65536)return error('Maximum file size is 90 MB',413);
 const form=await request.formData();const file=form.get('file'),postId=String(form.get('postId')||''),position=Number(form.get('position')??0);
 if(!uuid.test(postId)||!Number.isInteger(position)||position<0||position>9)return error('Choose a valid draft post',400);
 const posts=await rest(request,env,'learning_posts',{id:`eq.${postId}`,author_id:`eq.${actor.id}`,status:'eq.draft',select:'id,author_id,status'});
 if(posts.length!==1)return error('Draft access denied',403);
 if(!(file instanceof File)||file.size===0)return error('Select a file',400);
 if(file.size>MAX_BYTES)return error('Maximum file size is 90 MB',413);
 const extension=file.name.split('.').pop().toLowerCase(),mime=formats[extension];
 if(!mime||(!['','application/octet-stream',mime].includes(file.type)))return error('Unsupported file type',415);
 const peek=new Uint8Array(await file.slice(0,32).arrayBuffer());if(!validMedia(peek,mime))return error('The file contents do not match its format',415);
 const attachments=await rest(request,env,'learning_media',{post_id:`eq.${postId}`,select:'id'});if(attachments.length>=10)return error('A post supports up to 10 files',400);
 const path=`${actor.id}/${postId}/${crypto.randomUUID()}.${extension}`,key=`learning/${path}`;
 await env.LEARNING_MEDIA.put(key,file.stream(),{httpMetadata:{contentType:mime},customMetadata:{authorId:actor.id,postId}});
 try{
 const [attachment]=await rest(request,env,'learning_media',{}, {method:'POST',body:JSON.stringify({post_id:postId,object_path:path,filename:file.name.replace(/[\r\n]/g,'_').slice(-180),mime_type:mime,byte_size:file.size,position,storage_backend:'r2'})});
 if(!attachment?.id)throw new Error('Attachment registration failed');
 return Response.json({id:attachment.id,filename:attachment.filename,mimeType:mime},{status:201});
 }catch(_){await env.LEARNING_MEDIA.delete(key);return error('The attachment could not be registered',403);}
}
export function parseRange(header,size){
 if(!header)return null;const m=/^bytes=(\d*)-(\d*)$/.exec(header);if(!m||(!m[1]&&!m[2]))return false;
 let start,end;if(!m[1]){const suffix=Number(m[2]);if(!Number.isSafeInteger(suffix)||suffix<=0)return false;start=Math.max(0,size-suffix);end=size-1;}else{start=Number(m[1]);end=m[2]?Number(m[2]):size-1;}
 if(!Number.isSafeInteger(start)||!Number.isSafeInteger(end)||start<0||start>=size||end<start)return false;end=Math.min(end,size-1);return {offset:start,length:end-start+1};
}
async function media({request,env}){
 if(!ready(env))return error('Learning media storage is unavailable',503);
 const id=new URL(request.url).searchParams.get('id');if(!uuid.test(id||''))return error('Attachment not found',404);
 // Requests without a JWT use anonymous RLS: only media on published, approved posts is visible.
 let rows;try{rows=await rest(request,env,'learning_media',{id:`eq.${id}`,select:'id,post_id,object_path,filename,mime_type,storage_backend'});}catch(_){return error('Attachment not found',404);}
 const attachment=rows[0];if(!attachment||attachment.storage_backend!=='r2'||!Object.values(formats).includes(attachment.mime_type))return error('Attachment not found',404);
 if(!/^[0-9a-f-]{36}\/[0-9a-f-]{36}\/[0-9a-f-]{36}\.[a-z0-9]+$/i.test(attachment.object_path))return error('Attachment not found',404);
 const key=`learning/${attachment.object_path}`,head=await env.LEARNING_MEDIA.head(key);if(!head)return error('Attachment not found',404);
 const range=parseRange(request.headers.get('Range'),head.size);if(range===false)return new Response(null,{status:416,headers:{'Content-Range':`bytes */${head.size}`}});
 const object=request.method==='HEAD'?null:await env.LEARNING_MEDIA.get(key,range?{range}:{});if(request.method!=='HEAD'&&!object)return error('Attachment not found',404);
 const name=attachment.filename.replace(/[\r\n"\\]/g,'_');
 return new Response(object?.body??null,{status:range?206:200,headers:{'Content-Type':attachment.mime_type,'Content-Length':String(range?range.length:head.size),'Accept-Ranges':'bytes',...(range?{'Content-Range':`bytes ${range.offset}-${range.offset+range.length-1}/${head.size}`} :{}),'Content-Disposition':`${attachment.mime_type==='application/pdf'?'attachment':'inline'}; filename="${name}"`,'Cache-Control':'private, no-store','X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'none'; sandbox"}});
}
async function cleanup({request,env}){
 if(!ready(env))return error('Learning media storage is unavailable',503);
 const actor=await user(request,env);if(!actor)return error('Authentication required',401);
 const id=new URL(request.url).searchParams.get('id');if(!uuid.test(id||''))return error('Attachment not found',404);
 const rows=await rest(request,env,'learning_media',{id:`eq.${id}`,select:'id,post_id,object_path,storage_backend'});const attachment=rows[0];if(!attachment||attachment.storage_backend!=='r2')return error('Attachment not found',404);
 const posts=await rest(request,env,'learning_posts',{id:`eq.${attachment.post_id}`,author_id:`eq.${actor.id}`,status:'eq.draft',select:'id'});if(posts.length!==1)return error('Only your own draft uploads can be removed',403);
 if(!attachment.object_path.startsWith(`${actor.id}/${attachment.post_id}/`))return error('Attachment not found',404);
 const removed=await rest(request,env,'learning_media',{id:`eq.${id}`},{method:'DELETE'});if(removed.length!==1)return error('Draft cleanup denied',403);
 await env.LEARNING_MEDIA.delete(`learning/${attachment.object_path}`);return Response.json({removed:true});
}
function guard(handler){return async context=>{try{return await handler(context);}catch(_){return error('Learning media request failed. Please try again.',503);}};}
export const onRequestPost=guard(upload);
export const onRequestGet=guard(media);
export const onRequestHead=guard(media);
export const onRequestDelete=guard(cleanup);
