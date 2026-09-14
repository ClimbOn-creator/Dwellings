# Learning-first buyer workflow — 13 September 2026

## Changes
- Businesses for sale is the last dropdown destination. Buyer dashboard and Transaction Room are directly accessible.
- Blueprint links to a private deal intake for opportunities from Affinity, external websites, brokers or direct seller conversations.
- Intake records source/link, jurisdiction, currency, structure, financial evidence, earnings adjustments, working capital, customers, operations, legal questions, funding and decision gaps.
- Existing deal records retain additional facts in property_snapshot; no schema or public-content reset is required. Unknown financial amounts remain null. Negative earnings are supported; invalid price/revenue/capital inputs are rejected.
- Submitted intake is retained in the dashboard's memory for retry following a failed creation. It is not a browser-reload draft.
- Transaction Room supplies 11 original document guides across eight stages, with separate fictional examples and blank downloadable Markdown templates. Documents can also be copied. Owner-edited document text is used for downloads.
- Dashboard task cards now use light backgrounds with dark text; muted text and phone header layout are corrected. Dashboard loading errors offer retry.

## Verification
- Full Flutter suite: 64 passed, four configuration-dependent persistence tests skipped.
- Configured Supabase mock persistence suite: four passed, including owner text/image overrides surviving changed defaults and remounts.
- Total: 68 passing checks.
- Final release web build passed after the phone header fix; prebuilt Cloudflare bundle verification passed.
- Local browser verified navigation order, new Transaction Room, buyer dashboard entry points and external-deal questions.
- Browser download produced Downloads/deal-brief-example.md; inspected its fictional-example text and jurisdiction/currency fields.
- Static analysis reported no errors; existing repository warnings/style notices remain.
- git diff --check passed.

## Scope
- External listing links are recorded, not scraped/imported. No currency conversion is performed.
- Templates are learning/preparation materials, not universally required or ready-to-sign legal documents. Country, structure, lender and local advisers determine requirements.
- No test deal was inserted into the user's live account. Existing authenticated Supabase room/task/vault services remain the persistence path.
- Existing public copy keys and published media were preserved. No content or media reset was performed.

## Deployment
- Cloudflare Pages production deployment: https://94af3207.dwelling-iq-app.pages.dev
- Live site: https://dwelling-iq-app.pages.dev/?module=transaction-room
- Live authenticated browser verified Transaction Room content, saved-deal dashboard loading, and white readable cards in the existing guided transaction plan. No existing deal was edited during verification.
