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
