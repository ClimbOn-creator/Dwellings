# DwellingIQ

DwellingIQ turns the Housing Moneyball workbook into a deployable property-decision web app. It supports both homebuyer and investor decisions and keeps the model explainable.

## Included

- Responsive Vite web app with address scanning and browser geolocation.
- All 12 opportunity factors and 10 risk factors from the workbook.
- Risk-adjusted opportunity score, outperformance probability, appreciation projection, mortgage payment, cap rate, and cash-flow estimates.
- Supabase magic-link authentication and saved analyses when configured.
- Safe offline/demo mode using local browser storage before Supabase is connected.
- Supabase SQL migration with Row Level Security.
- Cloudflare Pages Functions health endpoint and authenticated R2 upload endpoint.
- Cloudflare Pages and R2 configuration through Wrangler.

## Local setup

```bash
npm install
cp .env.example .env.local
cp .dev.vars.example .dev.vars
npm run dev
```

Without environment variables, the app still runs in demo mode and saves analyses on the current device.

## Connect Supabase

1. Open the Supabase project's **Connect** dialog.
2. Put the Project URL and publishable key into `.env.local`.
3. Put the same values into `.dev.vars` for local Cloudflare Functions.
4. In Supabase SQL Editor, run `supabase/migrations/202608080001_initial_schema.sql`.
5. Under **Authentication > URL Configuration**, add the local and deployed URLs as allowed redirect URLs.

Do not put a Supabase secret or legacy `service_role` key in browser variables. This app does not require one for ordinary user-owned analysis records.

## Connect Cloudflare Pages and R2

The Wrangler configuration is connected to the R2 bucket already present in the Cloudflare account:

- Production binding: `dwellings`
- Preview binding: `dwellings`

Production and preview currently share the bucket. Before accepting real customer documents, create a separate preview bucket and change `preview_bucket_name` in `wrangler.jsonc`.

In the Cloudflare Pages project, use:

- Repository: `ClimbOn-creator/Dwellings`
- Production branch: `main`
- Build command: `npm run build`
- Build output directory: `dist`
- Root directory: `/`

Add these environment variables for both Production and Preview builds:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Bind the production/preview R2 buckets to the variable `PROPERTY_FILES` under the Pages project's **Settings > Bindings**. The server endpoint `/api/property-files` validates a Supabase access token before storing a document and limits files to 15 MB.

## Commands

```bash
npm run dev       # Vite front-end development
npm run build     # Production build
npm run preview   # Preview the production build
npm run deploy    # Direct Cloudflare Pages deployment through Wrangler
```

The recommended deployment path is Cloudflare's Git integration. Every push to `main` will then produce a new production deployment, while other branches can create preview deployments.

## Before real financial use

The included market profiles are illustrative seed data. A production release needs licensed/current sources for comparable sales, listings, zoning, permits, hazards, insurance, mortgage rates, demographics, employment, transit, and rents. The model weights also require time-based historical calibration and out-of-sample testing.

DwellingIQ is a research and decision-support tool, not financial, mortgage, legal, tax, appraisal, or insurance advice.
