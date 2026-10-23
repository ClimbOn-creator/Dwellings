# Pact PHP2Shell exposure review — 22 October 2026

## Finding and scope

The reviewed deployment is `dwelling-iq-app` on Cloudflare Pages. The browser app is compiled Flutter/Dart JavaScript. Its request handlers in `functions/` and the push worker in `workers/` are JavaScript. `wrangler.jsonc` binds R2 buckets and does not configure a PHP origin. No PHP executable, PHP application files, Composer installation, PHP-CGI/FPM, Apache PHP module, or WordPress/Drupal/Joomla application was found in these deployable roots. The existing account/database calls use the configured hosted Supabase APIs. This review does not inspect managed providers' internal infrastructure or unrelated hosting/accounts.

The PHP project's advisory identifies CVE-2026-109618 and CVE-2026-109619 as PHP runtime remote-code-execution issues. Fixed supported releases are 8.5.12, 8.4.27, 8.3.36 and 8.2.35. PHP states that only updating is a complete fix, and exploitation can occur before application code runs. [Official advisory](https://www.php.net/archive/2026.php), [Canadian Cyber Centre alert](https://www.cyber.gc.ca/en/alerts-advisories/al26-026-critical-vulnerabilities-impacting-php-cve-2026-109618-cve-2026-109619).

No affected PHP runtime is part of the reviewed Pact deployment. This is an exposure finding, not a declaration that the entire site is invulnerable or an investigation of historical compromise.

## Added safeguards

- Navigation/API requests to obsolete PHP and CGI entry paths receive a small uncached 404 before downstream handlers execute. Case variants, path-info suffixes and bounded percent-decoding are covered. Query strings and bodies are not scanned or rewritten, preserving opaque OAuth state, binary uploads and legitimate filenames.
- JavaScript responses receive `nosniff` and a referrer policy. Existing CSP, CORS, authentication failures, redirects, range status and streaming bodies are preserved. Static responses receive equivalent baseline headers through `_headers`.
- `_routes.json` keeps Flutter assets, fonts, CanvasKit, icons and named bootstrap files on static hosting rather than invoking a function for every asset. This means the probe guard deliberately does not run inside those excluded static paths. They have no PHP execution capability; the release inventory guard covers their deployed files.
- The build checks `functions/`, `workers/`, `web/` and `dist/` for PHP/Composer/configuration artifacts and rejects deployment symlinks. It also checks the freshly compiled output before replacing the previous local bundle. The existing prebuilt verification invokes the same inventory check. This is a file inventory rule, not a general malware scanner or an assessment of future external service bindings.

These are extra safeguards for a non-PHP application. The path rejection is not a PHP2Shell patch, does not detect every exploit, and cannot replace a patched PHP runtime if a separate PHP service is deployed later. No changes were made to Supabase permissions, existing users/messages, saved site copy or R2 document access.

## Verification

Node tests exercise encoded/legacy probe rejection, HEAD responses, release inventory failures, static routing exclusions, untouched binary uploads and redirects, and preservation of authentication/CORS/CSP/range behavior. Existing image, learning-media and push-worker tests are included. Only benign path/health checks are used against production; no PHP exploit requests or real-user messages are sent.

Production verification after release `dc343588`: `/` and `/api/health` return 200; `/index.php`, `/%69ndex%2ephp` and `/cgi-bin/php-cgi` return 404; unauthenticated `/api/property-files` remains 401. Each checked response has `X-Content-Type-Options: nosniff`. The deployed main JavaScript SHA-256 matches the tested local bundle. The source and compiled output inventory checks pass, and 34 security/API/media/push tests pass. No exploit payloads were submitted.
