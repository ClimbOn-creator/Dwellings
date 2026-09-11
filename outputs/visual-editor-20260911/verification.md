# Affinity visual editor — 11 September 2026

Production: https://dwelling-iq-app.pages.dev/
Final deployment: https://3cfa073c.dwelling-iq-app.pages.dev/
Cloudflare project: dwelling-iq-app, production branch main.
Supabase project: tjcrxnqnzaheytzmbyri (DwellingIQ).

Implemented click → Edit → Save for source-owned text and images across the app, an app-wide editing toolbar, image uploads, background selection, empty-text selection, live-value templates, and existing-record editor routing for business listings. Content Studio opens the visual workflow.

Applied 202609110025_visual_site_editor.sql to the live database. Both supplied accounts were verified, and both successfully saved via the real RPC in one transaction that was rolled back. Confirmed afterward: zero test content left behind, site-media bucket ready, editor save RPC ready.

Validation:
- Full Flutter suite: 49 passed; four mock-backend-specific tests skipped in this run.
- Separate configured mock-backend persistence suite: all four passed, including changing bundled text and image defaults, remounting the app, and preserving saved overrides.
- Local PostgreSQL policy tests passed for both editors, future first sign-in, anonymous/outsider/unverified denial, conflicts, resets, and storage policies.
- Desktop (1280px) and phone (390px) editor layouts passed.
- Release web build and prebuilt-bundle verification passed.
- Live browser showed Edit this page for the signed-in editor and opened the correct text and picture dialogs. Cancelled these checks without modifying live copy or pictures.
- Full static analysis had no compile errors; lint warnings and informational diagnostics remain.

Owner requirement for future work: published text and uploaded pictures must survive redesigns, rebuilds and deployments unless the user explicitly requests replacing/resetting them. AGENTS.md records this standing instruction. Preserve widget contentKey/contentId values and copy-catalog IDs. Image identities do not depend on asset filenames.

Deployment used the current working tree. No git commit or push was made; retain this working tree when continuing development. Supabase content and uploaded media live outside the generated dist folder.
