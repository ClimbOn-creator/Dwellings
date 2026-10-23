import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {onRequest, unsupportedRuntimePath} from '../functions/_middleware.js';
import {verifyNoPhpArtifacts} from '../tool/verify_edge_runtime.mjs';

test('obsolete PHP/CGI paths are rejected before downstream work', async () => {
  for (const route of ['/index.php', '/WP-LOGIN.PHP', '/api/run.php/extra', '/cgi-bin/php-cgi', '/php-cgi.exe', '/x.phtml', '/x.phar', '/%69ndex%2ephp', '/%2569ndex%252ephp', '/x.php%3banything']) {
    let called = false;
    const response = await onRequest({request: new Request(`https://app.test${route}`, {method:'POST',body:'untrusted'}), next: () => {called=true;}});
    assert.equal(response.status, 404, route);
    assert.equal(called, false, route);
    assert.equal(response.headers.get('Cache-Control'), 'no-store');
    assert.equal(await response.text(), 'Not found');
  }
  assert(unsupportedRuntimePath('/broken%zz'));
  assert.equal((await onRequest({request:new Request('https://app.test/x.php',{method:'HEAD'}),next:()=>assert.fail()})).body,null);
});
test('uploads, OAuth queries and streamed/range responses remain intact', async () => {
  const body = new Uint8Array([0,255,1,2]);
  const request = new Request('https://app.test/api/profile-media?filename=example.php', {method:'POST',body});
  let called = false;
  const response = await onRequest({request, next: async () => {
    called=true;
    assert.deepEqual(new Uint8Array(await request.arrayBuffer()),body);
    return new Response(body,{status:206,headers:{'Content-Range':'bytes 0-3/4','Content-Type':'image/png','Access-Control-Allow-Origin':'*','Content-Security-Policy':"default-src 'none'; sandbox"}});
  }});
  assert(called);
  assert.equal(response.status,206);
  assert.equal(response.headers.get('Content-Range'),'bytes 0-3/4');
  assert.equal(response.headers.get('Access-Control-Allow-Origin'),'*');
  assert.equal(response.headers.get('Content-Security-Policy'),"default-src 'none'; sandbox");
  assert.equal(response.headers.get('X-Content-Type-Options'),'nosniff');
  assert.deepEqual(new Uint8Array(await response.arrayBuffer()),body);
  for (const route of ['/api/calendar/callback?code=opaque%25&state=return.php', '/?module=buyer-dashboard', '/api/health']) {
    assert.equal((await onRequest({request:new Request(`https://app.test${route}`),next:async()=>new Response(null,{status:302,headers:{Location:'/next'}})})).headers.get('Location'),'/next');
  }
});
test('API authentication failures and HEAD semantics are preserved', async () => {
  const response=await onRequest({request:new Request('https://app.test/api/property-files',{method:'HEAD'}),next:async()=>new Response(null,{status:401,headers:{'Cache-Control':'no-store'}})});
  assert.equal(response.status,401);
  assert.equal(response.body,null);
  assert.equal(response.headers.get('Cache-Control'),'no-store');
});
test('release guard rejects PHP artifacts including files inside static bypass routes', () => {
  const root=fs.mkdtempSync(path.join(os.tmpdir(),'pact-edge-inventory-'));
  try {
    fs.mkdirSync(path.join(root,'dist/assets'),{recursive:true});
    fs.writeFileSync(path.join(root,'dist/assets/safe.png'),'image');
    assert(verifyNoPhpArtifacts(root));
    for (const filename of ['shell.PHP','shell.php.jpg','legacy.phtml','plugin.phar','composer.json','php.ini','php-fpm8.4','php-cgi.exe']) {
      const target=path.join(root,'dist/assets',filename);
      fs.writeFileSync(target,'fixture');
      assert.throws(()=>verifyNoPhpArtifacts(root),/PHP artifacts require/);
      fs.unlinkSync(target);
    }
    fs.symlinkSync('/tmp',path.join(root,'dist/assets/link'));
    assert.throws(()=>verifyNoPhpArtifacts(root),/Review deployment symlink/);
  } finally {fs.rmSync(root,{recursive:true,force:true});}
});
test('static assets avoid function invocations; all API/navigation routes are guarded', () => {
  const routes=JSON.parse(fs.readFileSync(new URL('../web/_routes.json',import.meta.url),'utf8'));
  assert.deepEqual(routes.include,['/*']);
  assert(routes.exclude.includes('/assets/*'));
  assert(routes.exclude.includes('/main.dart.js'));
  assert(!routes.exclude.some(route=>route.startsWith('/api')));
  assert(verifyNoPhpArtifacts());
});
