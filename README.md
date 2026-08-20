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
- Pages project: `dwellings-iq`
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
