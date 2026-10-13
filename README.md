# DwellingIQ Flutter MVP

DwellingIQ converts the Housing Moneyball workbook into an explainable, cross-platform Flutter application for homebuyers and property investors.

## MVP features

- Flutter source for web, iOS and macOS, following the same cross-platform approach as Climb On.
- Homebuyer and investor decision modes.
- Location-aware demo market profiles for Vancouver, Victoria, Kelowna, Calgary and Toronto.
- Twelve opportunity factors and ten risk factors from the workbook.
- Risk-adjusted score, outperformance probability, appreciation projection, mortgage cost, cap rate and investment cash flow.
- Explainable factor contributions and decision-specific diligence questions.
- Supabase magic-link authentication and user-owned saved analyses when configured.
- Safe device-local saving when Supabase is not configured.
- Free, template-based acquisition email and member newsletter tools in a dedicated Marketing Studio.
- A public membership overview and application for buyers, professionals and featured partners.
- Cloudflare Pages Functions and authenticated R2 upload endpoint.
- Supabase SQL migration with Row Level Security.

## Flutter development

```bash
flutter pub get
flutter run -d chrome
flutter test
```

To enable Supabase locally, copy `.env.flutter.example.json` to `.env.flutter.json`, add the Project URL and publishable key, then build with:

```bash
npm run build:flutter
```

The private `.env.flutter.json` file is ignored by Git. Never place a Supabase secret/service-role key in the Flutter build.

## Cloudflare deployment

Flutter is built locally and the static `dist/` bundle is committed for Cloudflare Pages. The Git-connected Cloudflare project uses:

- Repository: `ClimbOn-creator/Dwellings`
- Production branch: `main`
- Build command: `npm run build`
- Output directory: `dist`
- Pages project: `dwelling-iq-app`
- R2 binding: `PROPERTY_FILES` → `dwellings`

The Cloudflare build command verifies the committed Flutter bundle. Before pushing a Flutter source change, run `npm run build:flutter` so `dist/` stays synchronized.

### Consulting request email

The consulting form verifies the signed-in Supabase user and sends the request through Resend. Add these encrypted Cloudflare Pages variables:

- `RESEND_API_KEY`
- `CONSULTING_EMAIL` — the founder inbox
- `CONSULTING_FROM_EMAIL` — a sender on a Resend-verified domain

Requests include the authenticated user's name/email plus their supplied phone, consulting focus, desired outcome and current challenge.

### Member Studio private beta

Apply `supabase/migrations/202608200017_private_beta_operations.sql` for professional matching, private notifications, buyer shortlisting, audit history, and beta metrics. In-app notifications work through Supabase. To also deliver transactional email, configure:

- `SUPABASE_SERVICE_ROLE_KEY` — server-side only
- `RESEND_API_KEY`
- `AFFINITY_FROM_EMAIL` — a sender on a Resend-verified domain
- `APP_BASE_URL` — the production Affinity URL

The founding-member onboarding flow does not charge a card. Paid billing remains a separate, explicit activation step after the private beta.

Apply `supabase/migrations/202608310018_admin_member_studio_access.sql` and
`supabase/migrations/202609010019_professional_deal_matching.sql` after the
private-beta migration. The latter centralizes the recommendation score across
the Member Studio: requested profession (25 points), location (20), member
background and specialties (20), deal-type relevance (10), the deal’s
Affinity review score (20), and member experience/reputation (5). It also adds
the public-safe Deal Room team roster, turns accepted
pitches into Deal Room memberships, and prevents a second accepted member of
the same profession from contacting that buyer about the same deal.

Apply `supabase/migrations/202609010020_member_networking.sql` for the Member
Studio social layer: private one-to-one member conversations, unread and
last-message ordering, deal-context chat, member referrals, buyer/referral
notifications, and enforcement that referrals cannot bypass a filled deal
role.

Apply `supabase/migrations/202609030022_message_read_receipts.sql` after the
networking migration so profile-owned conversations follow members across
devices, message notifications clear when their conversation is viewed, and
outgoing messages show timestamped read receipts.

Apply `supabase/migrations/202609010021_creator_marketplace_access.sql` to
provision the Affinity creator account as an owner/member, restrict its
recommendations to Victoria, and enable deal search, traffic-aware monthly
discovery, engagement counts, and owner reposting after 30 days.

### Google and Outlook calendar sync

Apply `supabase/migrations/202608150013_calendar_connections.sql`, then configure these encrypted Cloudflare Pages variables:

- `SUPABASE_SERVICE_ROLE_KEY` — server-side only; may contain Supabase's recommended `sb_secret_…` key or the legacy `service_role` key
- `APP_BASE_URL` — for example `https://dwellings-iq.pages.dev`
- `OAUTH_STATE_SECRET` — a long random value
- `CALENDAR_TOKEN_KEY` — a base64url-encoded random 32-byte key
- `GOOGLE_CALENDAR_CLIENT_ID` and `GOOGLE_CALENDAR_CLIENT_SECRET`
- `MICROSOFT_CALENDAR_CLIENT_ID` and `MICROSOFT_CALENDAR_CLIENT_SECRET`
- `MICROSOFT_TENANT_ID` — use `common` for multi-tenant Microsoft accounts

Register this exact redirect URI with both providers:

```text
https://YOUR_APP_DOMAIN/api/calendar/callback
```

In Google Cloud, enable the Google Calendar API, configure the OAuth consent screen, and add the Calendar scope. In Microsoft Entra, add delegated `Calendars.ReadWrite` permission and allow public users only if that matches the intended membership model. Provider refresh and access tokens are AES-GCM encrypted before being written to the server-only table; no client table policy is created.

For local Pages testing, use the local callback URL and copy `.dev.vars.example` to the ignored `.dev.vars` file. Generate a token-encryption key with a cryptographically secure 32-byte random source and base64url encode it.

## Supabase

Run `supabase/migrations/202608080001_initial_schema.sql` in the new project's SQL Editor. The migration creates profiles and property analyses with Row Level Security so each user can only access their own records.

Add the deployed Pages URL under Supabase Authentication URL Configuration for magic-link redirects.

## Important limitation

The included location profiles are illustrative seed data. Production use requires current and licensed sources for comparable sales, listings, zoning, permits, hazards, insurance, mortgage rates, demographics, employment, transit and rents. Model weights require historical calibration and out-of-sample testing.

DwellingIQ is a research and decision-support tool, not financial, mortgage, legal, tax, appraisal or insurance advice.


## Visual page editor

Verified `rw0882308@gmail.com` and `dfisch5@gmail.com` accounts can use **Edit this page** on every route, including the public pages, buyer tools, property pages and member screens. Click an outlined text block or image, choose **Edit**, then **Save**. Switch to **Done editing** to follow links and use ordinary controls. Content Studio now opens this visual workflow.

- Changes are published in Supabase and load on other devices, including a refresh every 30 seconds for open pages.
- Text edits support complete rewrites and line breaks. Live-value sentences expose placeholders rather than copying account data into public content. Empty text stays selectable in editing mode.
- JPG, PNG and WebP uploads are limited to 10 MB. Backgrounds have an **Edit background** control. **Restore original** removes the override.
- Saving checks the previously published value. A stale draft cannot overwrite another editor's change. Failed saves keep the draft and never appear as successful local publication.
- Business listing content uses its existing listing editor and permissions. Private records, messages, actual profile photos and calculated values retain their normal data workflows.

### Activate on the live app

Apply `supabase/migrations/202609110025_visual_site_editor.sql` after `202608190016_site_content_editor.sql`, then publish the rebuilt `dist/` through the existing Cloudflare Pages project. The migration creates the site-media bucket, restricts writes to content editors, and checks verified accounts at sign-in so future first-time sign-ins work too. Never put a service-role key in the web bundle.

### Verify

Run `flutter test --no-pub`. The persistence tests additionally run with a mock backend:

```sh
flutter test --no-pub --dart-define=SUPABASE_URL=https://editor.test --dart-define=SUPABASE_PUBLISHABLE_KEY=test-public-key test/site_editor_persistence_test.dart
```

Run `test/sql/site_visual_editor_test.mjs` with `PGLITE_MODULE` pointing to an installed `@electric-sql/pglite` module. This checks permissions, concurrent edits, resets and media policies without touching live data. Optional `EDITOR_SCREENSHOT_DIR` and `EDITOR_FONT_PATH` enable visual snapshots in the layout tests.

Copy keys embedded in `SiteText`, `SiteCopyText`, `SiteImage` and `SiteBackground` are persistent IDs; do not renumber them. When adding data-driven interface labels, add source-owned fallback strings to `lib/services/site_copy_catalog.dart`. Do not add user-entered content to that catalog.

### Owner edits survive redesigns

Text keys and image slot keys are permanent and do not depend on wording, filenames or image bytes. Saved Supabase values always override bundled defaults. Changes to copy, layout or bundled assets must carry forward those same IDs. The persistence suite tests new text defaults, new asset paths and remounting the app while preserving the owner's saved text and image URL. See `AGENTS.md` for the standing owner instruction governing all future changes.

## Pebble app walkthrough

Pebble is a character-led, click-through guide to the dashboards, transaction room and other app tools. Completed training is saved to a signed-in account’s profile and stays hidden until replay is requested. No AI key or additional database migration is required. See [Pebble guide behaviour](docs/nova-setup.md).


### Buyer, seller and member paths

The landing page selects a navigation context; this is not an authorization role.
Shared deal and message permissions continue to be enforced by the backend.
The Affinity logo clears the selected path and returns to the landing page.

- Buyer: dashboard, resources, profile, transaction room, businesses for sale, deal comparison quiz.
- Seller: dashboard, transaction room, my posts and analytics, profile.
- Member: pricing, dashboard, profile, marketing.

Canonical previews include `?module=seller-posts`, `?module=seller-transaction-room`,
`?module=member-pricing`, and `?module=member-marketing`. Old network, property
calculator and game URLs return to the main landing; the old business calculator
URL opens the current buyer deal screen. Saved records and owner copy are retained.

Seller post analytics require the additive migration
`supabase/migrations/202610080001_seller_post_analytics.sql` on the hosted Supabase
project. Its authenticated RPC returns only the caller's own posts, including
archived posts and real current bookmark counts. It never exposes saver identities.
Until installed, the page displays a retryable load error rather than fabricated
analytics. Published paid membership prices are not configured; the Pricing page
compares existing plan descriptions and does not take payment.

Transaction Room in the main navigation opens the restored document learning library, including worked examples and editable templates. Private deal workspaces remain available from the dashboards.

## Learning Dashboard and private R2 media

The boxed **I want to learn** action opens a fourth, separate Learning workspace (`learning-dashboard`, `learning-seminars`, `learning-map`). Its menu contains Learning Dashboard, Live seminars, Buying & selling map, Deal comparison quiz, Transaction Room and Profile. Resources is embedded in the Learning dashboard sidebar. Saved lessons has been removed from the interface; historical saved records are retained. Anyone can read published lessons and explore the map; signed-in learners can like posts, comment, reply in threads, register for sessions and save concept progress. Eight buying stages and eight selling/transfer stages include explanations, related document guides and short understanding checks.

Only the confirmed creator account `rw0882308@gmail.com`, already an Affinity owner, can approve or revoke registered contributors under **Contributor approvals**. The approval is checked in database policies and again during R2 uploads. No example feed posts, public seminars or new accounts are seeded. Existing site copy, pictures and account data are preserved.

New pictures, videos, audio and PDF attachments use a dedicated **private** Cloudflare R2 bucket. For a new Cloudflare account, setup is:

```sh
npx wrangler login
npx wrangler r2 bucket create affinity-learning-media
```

`affinity-learning-media` has been created in the connected Cloudflare account. `wrangler.jsonc` binds it as `LEARNING_MEDIA`. Keep its public development URL and custom public domains disabled: downloads go through `/api/learning-media`, which reads Supabase metadata with the visitor's permissions before streaming R2 objects. Set the existing Pages variables `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` for both preview and production. No R2 access keys or service role key are exposed to the Flutter client. `/api/health` reports `learningMediaConfigured`.

Allow up to ten files per post, 90 MB per file: JPG/JPEG, PNG, WebP, GIF, MP4, WebM, MOV, MP3, WAV, M4A and PDF. Video/audio playback depends on the browser's codec support; MP4/WebM are preferable for browser video. PDF opens as a download. Larger video delivery and transcoding are not included. Storage remains private; approved published attachments are readable through the app endpoint. Failed uploads clean up only the new draft attachments. Existing Supabase learning attachments retain their storage backend and remain readable.

The additive migrations `20261012182447_learning_dashboard.sql` and `20261012185317_learning_media_r2.sql` introduce learning tables, approval policies and storage metadata. They have been applied to the configured project. `test/sql/learning_access.sql` tests privacy and approval rules with temporary fixtures inside a transaction ending in ROLLBACK. Run `node --test test/learning_media_api_test.mjs` for upload validation, draft privacy and video range requests.

Live seminars use the approved host's external HTTPS meeting link (for example Zoom) and optional replay. The app schedules sessions, RSVPs and calendar downloads; it does not broadcast video itself.

Map concepts are informed by BDC's [buying steps](https://www.bdc.ca/en/articles-tools/start-buy-business/buy-business/what-are-steps-buying-business), [due diligence](https://www.bdc.ca/en/articles-tools/start-buy-business/buy-business/buying-business-conducting-due-diligence), and [negotiating a sale](https://www.bdc.ca/en/articles-tools/change-ownership/sell-business/how-to-negotiate-the-sale-of-your-business).

### Nearby social feed and Pebble

Learning posts require a community selected by the approved publisher. Learners choose their community or explicitly request device location to find a nearby community. Device coordinates are discarded; only the community's broad coordinates rounded to 0.1 degree are used. Signed-in area preferences are private to the account through RLS. Guests keep their selection on the device. Coordinates with finer precision are rejected by the database. Posts without an area remain stored but do not enter the local feed.

The server filters published posts from currently approved contributors to a 200 km radius using the community area coordinates. Recommended order uses logarithmic likes and active comment counts, recency decay and a small proximity weight. The Newest option keeps the same radius and sorts by date. No follows graph is used. The radius is approximate because community areas are coarse; at most 100 ranked posts are fetched per refresh.

Comments are readable on published, approved posts. Signed-in learners may add comments and nested replies (up to eight reply levels), including learners who cannot publish posts. Cross-post replies and author impersonation are prevented by database rules. Twenty comments per five minutes is the posting limit. The author or creator may remove a comment; text is cleared and a tombstone preserves replies. The comment sheet fetches 100 comments initially and can load more. The transaction-only verification is in `test/sql/learning_social_access.sql`. The migration `20261013161150_learning_local_feed_comments.sql` has been applied to the configured project.

Pebble's small button is fixed at the bottom left across scroll, except on the landing page. Its X returns the help button to the header; requesting help there restores Pebble. Page-specific walkthroughs and profile completion behavior remain available.
