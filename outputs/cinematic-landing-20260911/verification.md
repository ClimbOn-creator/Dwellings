# Affinity cinematic landing — 2026-09-11

Implemented full-screen native-scroll scenes following the user's Goonies reference: architectural camera push, independent headline movement, opening shutters, a second emerging statement, four sideways photographic chapters, and supporting section entrances. Preserved all existing public content keys and added permanent new image slots.

A visible motion preference is remembered locally. Default respects system reduced motion; explicit Enable motion overrides it. Editing and large-text layouts use the complete stationary version, with chapter pictures and copy editable. No site_content or site-media records were modified or reset.

Validation: full Flutter suite 54 passed, 4 backend-configured tests skipped; configured persistence suite 4 passed. Five focused motion tests passed again after the final image-boundary correction. Release Flutter build and prebuilt Cloudflare artifact validation passed.

Browser reviewed at desktop 1440x960 and phone 390x844. Existing owner headline and hero photograph appeared in the redesigned layout. Buyer CTA opened the Blueprint. Browser reports prefers-reduced-motion true; explicit motion was enabled through the page control and persists on reopening.

Published after the user instructed us to finish following the production approval block. Read-only Cloudflare project listing confirmed dwelling-iq-app and its existing domain. Wrangler reported deployment complete: https://55b7a4a3.dwelling-iq-app.pages.dev (production: https://dwelling-iq-app.pages.dev/). Release bundle SHA-256: 6a0db02d415447eda7b380978c780b5f8d71edaa1b2997aff6006b64a9b68e92. build/web and dist hashes matched before release. No database content was reset.

Source changes remain local; no commit or push performed.

Production browser verification complete: live Motion on control present and enabled, scroll progress advanced from 0 to 20 with visible independent photograph/headline motion, existing owner headline/photo retained, authenticated Edit this page toolbar present. Live page left at the opening with motion enabled.
