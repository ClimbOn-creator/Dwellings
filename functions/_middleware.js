// Pact serves JavaScript at the edge, not PHP. This rejects obsolete PHP/CGI
// entry-point probes; it is NOT a PHP2Shell runtime patch or a general WAF.
export function unsupportedRuntimePath(pathname) {
  let path = pathname;
  try {
    for (let i = 0; i < 4 && path.includes('%'); i++) {
      const decoded = decodeURIComponent(path);
      if (decoded === path) break;
      path = decoded;
    }
  } catch { return true; }
  if (/%[0-9a-f]{2}/i.test(path)) return true; // Ambiguous nested encoding.
  path = path.replaceAll('\\', '/');
  return /\.(?:php\d*|phtml|phar|phps)(?:[./;\u0000]|$)/i.test(path)
    || /(?:^|\/)(?:cgi-bin|php-cgi(?:\.exe)?)(?:[\/;\u0000]|$)/i.test(path);
}
export async function onRequest(context) {
  if (unsupportedRuntimePath(new URL(context.request.url).pathname)) {
    return new Response(context.request.method === 'HEAD' ? null : 'Not found', {
      status: 404,
      headers: {'Content-Type':'text/plain; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'},
    });
  }
  // Do not inspect, buffer or rewrite uploaded documents or OAuth query data.
  const upstream = await context.next();
  const response = new Response(upstream.body, upstream);
  response.headers.set('X-Content-Type-Options', 'nosniff');
  if (!response.headers.has('Referrer-Policy')) {
    response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  }
  return response;
}
