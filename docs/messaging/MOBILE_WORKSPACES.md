# Pact mobile workspaces — build 6

`lib/main_mobile.dart` opens the authenticated Pact mobile shell. It has a light lavender/white surface, rounded cards, coloured action tiles and five fixed bottom destinations. The shared web dashboard and published owner content are preserved.

- Buyer: Home, Businesses, Messages, Help, Profile.
- Seller: Home, My Listing, Messages, Find Buyers, Profile.
- Member: Home, Clients, Messages, Leads, Profile.

## Accounts and permissions

Membership is recognized through the existing `pact_messaging('capabilities')` RPC, which checks professional-record ownership in the database. Editable profile role labels and OAuth metadata grant no access. Failed recognition blocks workspace data and offers retry/sign out. Buyer/Seller is a workspace choice available through the header; its preference is stored per account on this device. Members can also use a Buyer/Seller workspace. Changing workspaces never changes backend permissions.

Messages use the existing authoritative conversation API, private realtime channel, account-scoped secure outbox and UUID retries. A customer can find a professional and send the first request message; members cannot initiate unsolicited messages to buyers/sellers. Pending request recipients can preview the actual inquiry and accept before replying. Read cursors advance only while the conversation is visible. Sign-out clears account data and dismisses mobile detail/editor routes.

The existing profile panel still edits shared photos, cover, biography and professional specialties, reads real reviews and sends profile pictures to the existing authenticated R2 media endpoint. Login, Google callback and device push integration are preserved. Firebase/APNs production setup and live push delivery remain separate unfinished configuration, as documented in SETUP.md.

## Shared data

Business browsing and bookmarks call the same RPCs as the website. Only published real listings appear; no fictional example businesses or simulated messages are substituted. Home reads existing authorized transactions and task completion. Clients opens existing accepted conversations. Leads reads owned professional inquiries and supports status/private-note updates through `respond_to_introduction`, preserving follow-up date and closed reason.

Complex transaction management and listing publication/editing open the existing web workspace in the browser; mobile does not duplicate those financial tools. The browser may require its own login to the same Pact account. Seller Find Buyers supports incoming conversations and listing visibility; it does not expose a directory of private buyer identities.

Data refreshes on foreground/resume and pull-to-refresh. The messaging refresh/reconnect loop remains active. Failed reads show a retry notice; charts are hidden when their source fails.

## Listing insights

The deployed migration `20261023024557_pact_mobile_listing_insights.sql` adds an owner-only read RPC, `pact_seller_listing_insights(days)`, with 7/30/90-day windows. Its public wrapper is security invoker; the private helper checks `auth.uid()` and filters listing ownership before aggregating. Anonymous execution is revoked. Only dated aggregate bookmark counts are returned, never buyer identities.

My Listing displays current saves, active listings and a bar chart of current bookmarks grouped by their UTC save date. Removing a bookmark removes it from the chart; this is not a historical activity log or unique visitor metric. Views, listing-specific enquiries, market comparisons and paid boosts are not yet recorded and are explicitly labelled unavailable. This change creates no event table and uploads no extra Supabase media. Database usage after migration was about 17.2 MB, well below the requested 1 GB ceiling.

## Verification

- `test/pact_mobile_workspace_test.dart`: role tabs, editable-role spoof resistance, phone/tablet layouts, actual bookmark data, bounded date windows, failed recognition and failed insight rendering.
- `test/pact_messenger_test.dart`: shared login/Google callback, visible-only mobile read state, account clearing, request/reply, outbox retry, profile concurrency and web messaging regressions.
- `test/sql/pact_mobile_listing_insights_test.sql`: run inside BEGIN/ROLLBACK, checks owner isolation, bookmark totals, unsupported interval, missing identity and anonymous grants. Verified against the connected project; fixtures rolled back.
- Saved site-content persistence suite with mock Supabase defines remains required.

The Supabase advisor returned no finding for the new invoker RPC. Existing legacy definer-function notices and the pre-existing leaked-password-protection warning remain outside this mobile UI change; do not describe this as a complete security certification.

Device delivery: CoreDevice confirmed build 6 installed on the connected iPhone 15 Plus. Automatic launch was blocked by the phone lock screen; the owner must unlock and open Pact.
