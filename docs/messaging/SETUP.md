# Messaging implementation and release setup

## Run

iOS 15 or later is required by the installed Firebase libraries.

- Web: existing entry point, open `?module=messages` or the signed-in navigation Messages button.
- Native mobile: `flutter run -t lib/main_mobile.dart --dart-define-from-file=.env.flutter.json`.
- Xcode: first run `flutter build ios --config-only -t lib/main_mobile.dart --dart-define-from-file=.env.flutter.json`, then open `ios/Runner.xcworkspace`. Select your development team and connected iPhone. Do not ship the existing Android debug release signing configuration.

The new two-tab MVP is Messages / Profile. Transaction features remain in the existing web app for this phase. Uses existing email/password accounts. Native OAuth and magic links remain a separate redirect-configuration task. User-facing errors never echo raw server/database errors.

## Backend

Both additive messaging migrations have been applied to the configured project. Apply both messaging migrations when setting up another environment. Legacy message records are retained. Audit found zero old threads/messages, so no history copy was required for this project; recheck before deployment if accounts have since become active.

The new RPC is invoker-only; its privileged implementation is in the unexposed `pact_private` schema. Every request validates account and membership. Raw table access is revoked and RLS enabled. Do NOT add `pact_private` to exposed PostgREST schemas. No client gets a service key.

Private per-account realtime events refresh the inbox and conversation promptly. Events contain only a thread ID; membership-checked RPCs load the content. A five-second foreground refresh and resume refresh recover missed events. The server persists messages independently of realtime or push. Read cursors only advance from displayed history. Recent history is 50 messages per page; inbox currently caps at 100 conversations. Add inbox pagination before allowing accounts to exceed that cap.

Native unsent messages use secure storage and UUID retries. Failed sends require explicit Retry. Web unsent drafts live in memory and do not survive browser close. Sessions use secure native storage, migrating an existing local session before removing its plaintext copy. This is not end-to-end encryption.

## Push — external setup required

The user has installed apps using Xcode but has not confirmed Firebase or APNs configuration. No production push delivery is claimed.

1. Confirm production iOS bundle ID and Android application ID. Existing identifiers are `com.dwellingiq.dwellingIq` (iOS) and `com.dwellingiq.dwelling_iq` (Android); do not invent replacements that disconnect signing/provisioning.
2. Register those apps in Firebase. Use FlutterFire configuration, add platform config files, enable the required Firebase Android Gradle integration, and upload an APNs authentication key to Firebase using the console's secret controls.
3. Enable iOS Push Notifications and Background Modes / Remote notifications in the Xcode signing target. Keychain entitlements have been added for secure storage. Use real provisioning for push testing.
4. Deploy `workers/pact-push` as a separate scheduled Cloudflare Worker. Configure server-side secrets `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`. Never put these server credentials in Flutter defines, git, public Pages variables or chat.
5. Enable notifications from Profile on a physical device. Test foreground, background, terminated app, notification tap, logout/account switch, rejected permission, invalid token and provider outage.

Notifications contain no message bodies or names. Device registration is bound to a live Supabase session; token rows cascade away when the session is deleted. Tokens older than 30 days are not sent. Jobs are versioned and leased to avoid concurrent workers completing newer updates. Providers may still deliver duplicates: notifications are advisory, and inbox state remains authoritative. Failed jobs stop after eight attempts and need operational monitoring. Completed jobs are cleaned up after seven days when the worker processes a nonempty batch; add independent periodic housekeeping before a larger rollout.

## Images and attachments

This phase audits existing handling but does not add chat attachment upload. No new pictures or PDFs are stored in Supabase. Existing profile-photo/site-media objects remain preserved. Move future profile/cover uploads to R2 through an authenticated endpoint; never expose private message media through public image buckets. Existing property-file magic-byte validation is not malware scanning.

## Remaining release gates

- Physical iOS/Android installation and push test; production signing.
- Confirm appropriate MFA/session/recovery configuration and leaked-password protection in Supabase.
- Restore drill for database and R2 backups.
- Concurrent two-device/offline testing with test accounts.
- Monitor total DB bytes and growth; notify at 700 MB and intervene by 850 MB. New sends guard at 850 MB, but other modules can grow independently, so this is not a global quota guarantee.
- Add operational alerting for failed push jobs and agreed record-retention policy.

## Validation recorded

- Existing full Flutter regression suite: 306 passed, 18 skipped.
- Owner content persistence with mock backend: 5 passed.
- New secure outbox / mobile interaction tests with fixture accounts: 4 passed (retry identity, process restart before and after a failed send, committed-history reconciliation, account isolation, mobile profile layout, sign-out clearing).
- Push Worker unit tests cover generic payloads, worker lease contention, removed recipients and temporary provider failure.
- Database request / retry / membership / read / privilege tests passed in rolled-back transactions before and after applying the schema.
- Mobile UI browser build and iOS simulator build succeeded. iOS deployment target raised to 15.0 for Firebase compatibility. Android and physical-device push were not verified.
- Security advisors show no new ERROR/WARN findings for the new messaging API. INFO findings for the six tables with no RLS policies are intentional: clients have no raw table grants, and the RPC is their sole API. Wider pre-existing app warnings remain listed in the audit.
- New chat attachments, public professional reviews and Transaction Room UI are outside this phase.

## Physical iPhone installation — 21 October 2026

Pact 0.3.0 (build 3) was signed with the existing development team, installed and launched on the connected iPhone 15 Plus running iOS 26.6.1. Installation was verified through CoreDevice and Xcode's installed-app list. This does not verify push delivery; Firebase/APNs configuration remains outstanding.

On this Mac, iCloud's Desktop integration was repeatedly adding `com.apple.FinderInfo` metadata to generated frameworks, causing Apple code signing to fail. The generated `build` directory now links to `/Users/willrussell/Library/Caches/Pact/device-build-output`, outside iCloud. Project source stays in the Pact folder. The cache is local and ignored by Git. If it is cleared, recreate its target directory before building again. For a new checkout, keeping development projects outside iCloud-managed folders avoids this signing issue.


## Google sign-in and app icon (build 4)

The mobile login screen includes **Continue with Google** and uses Supabase's hosted Google OAuth flow in the system browser with PKCE. Existing website accounts share the same Supabase user ID. Tokens continue to use native secure storage.

The exact mobile callback `com.dwellingiq.dwellingiq://login-callback/` is registered in iOS URL Types, Android's VIEW intent filter, and the live project's Authentication → URL Configuration redirect allowlist (added October 21, 2026). Flutter's built-in deep-link routing is disabled so Supabase's app_links handler can consume the auth callback. The website still uses its origin as its callback. Existing website redirect entries and Google provider settings were preserved.

The owner-supplied `chic.png` is preserved as `assets/brand/pact-app-icon.png` and resized into the iOS and Android launcher icon catalogs. Build 4 uses the black PACT wordmark on white. No public website media or saved owner edits were changed.

Verification: mobile OAuth URL contains the app callback and an S256 PKCE challenge; messenger/outbox tests (5) and scoped static analysis pass. A user still needs to complete Google's account selection and consent on their device to verify a full live login.

Physical-device verification: iOS release build 0.3.0 (4) compiled successfully and CoreDevice confirmed it installed on the connected iPhone 15 Plus. Flutter's automatic launch returned an error after installation; a separate `devicectl device process launch` succeeded. Google account selection/consent remains a user-driven live check.


## Shared profile editing (build 5)

`20261021192246_pact_shared_profiles.sql` is applied to the live project. The account and professional profile retain their existing table identities. Private, trigger-only synchronization copies changed names, job titles, companies, descriptions, portraits and covers in both directions. Existing values are not overwritten during migration. Specialties, service areas, business phone and website remain in the existing professional record; reviews use the existing review table and policies. No verification or subscription privileges are editable in the new form.

The shared editor saves through the security-invoker `pact_save_profile` RPC and passes the profile's original timestamp. A stale editor is rejected without overwriting the newer save or clearing typed text. Profile views refresh when opened, when the phone resumes, and every 20 seconds while visible; a desktop profile keeps unsaved input through refreshes.

Portrait and cover uploads use `/api/profile-media`, backed by the existing private `PROPERTY_FILES` R2 binding (`dwellings` bucket) under `profiles/<owner>/<slot>/<random-id>.png`. The native system photo picker handles library formats; the client preserves aspect ratio, normalizes supported photos to PNG, strips source metadata, and bounds dimensions (768px portrait, 1800px cover). Unsupported images receive an error. Uploads are authenticated against Supabase; the worker independently checks image headers, dimensions and an 8MB streamed size cap. Uploaded profile images are deliberately public, with a namespace-restricted serving endpoint; private documents never use it. Supabase stores only two current image metadata rows per user, not image bytes. Existing Supabase-hosted photos are retained until the owner chooses replacements.

A definite registration rejection deletes only the new R2 object. Lost confirmations retain a possibly committed object rather than breaking the profile, and failed old-file cleanup never reverses a successful save. Review fields remain read-only for the professional receiving reviews.

Validation: live SQL rollback checks pass for identity synchronization in both directions, specialties, covers, stale saves, owner isolation and anonymous restrictions. Nine new API tests plus existing media/push tests pass (22 total). The complete Flutter suite passes (310 passed, 18 skipped); the saved-content regression with mock Supabase settings passes (5). Dedicated mobile tests cover the profile layout, failed-editor text retention, shared specialty payloads, Google OAuth/PKCE and sign-out. New profile/mobile files pass scoped static analysis. Database size after migration is approximately 16MB.

Web build reliability: `tool/build_web.sh` now builds into a fresh temporary output, verifies the HTML/bootstrap/application bundle, and stages the result before replacing `dist`. An incomplete build preserves the previous bundle.

Deployment verification: build 0.3.0 (5) is installed on the connected iPhone 15 Plus and launched successfully through CoreDevice. Production web and Pages Functions deployed as `c49d24b9.dwelling-iq-app.pages.dev` on the existing main branch. The production health endpoint confirms both R2 bindings and Supabase configuration. Native Dart-style requests reach the upload API and are correctly rejected without authentication (401); default Python urllib requests are separately blocked by Cloudflare's browser-integrity check (1010), which does not affect the tested native client identity or browser. A real photo-library upload remains a user-driven device check.


## Existing web dashboard messaging and contact direction

The web-only `PactWebMessages` component is embedded in the original buyer (`DealRoomsPage`), seller (`SellerDashboardPage`) and member (`MemberDealMarketplacePage`) dashboards. Each has a Messages navigation entry. Real member profile contact buttons and the global web Messages shortcut open the same account inbox. The original `MemberNetworkService.messagingEnabled` flag remains off; legacy writes are revoked rather than reactivating a separate, provider-only chat system. No mobile entrypoint or mobile messenger layout was changed in this pass.

Applied migration: `20261021204826_pact_dashboard_message_policy.sql`. Account classification uses owned professional records, including drafts; editable account-role/JWT labels and the editable example flag do not grant contact permissions. New contacts can only target verified, non-example, active/trialing members. A member cannot create a conversation addressed to a buyer or seller, including through raw RPC calls. Replies to customers require an actual message from that customer in the same conversation. Members may still contact other eligible members. All operations retain membership and blocking checks.

`open_member` resolves the selected public provider to its account and reuses one direct thread for the pair of accounts across dashboards. Empty direct drafts do not notify or appear in the recipient inbox. The initiator can send one first request message; the member can read that request, then accept to reply or decline. Further messages wait for acceptance. First-message retries reuse the message UUID and return the original committed message. Authoritative `can_send` flags drive the composer but the SQL authorization check remains mandatory on every send.

The web conversation uses an iMessage-style split inbox, search, contact photos, centered conversation identity, blue outgoing/grey incoming bubbles, calendar grouping, read state, Enter-to-send and Shift+Enter for new lines. Light/dark appearance is local to this web view. It has no decorative call, audio or attachment controls that do not work. Accepted messages and request previews are only returned to their conversation participants. The server sends private invalidations, not message bodies, over Realtime. Pending bubbles stay visible until authoritative history reconciles them, and failed drafts can be retried or removed.

Authoritative policy regression: run `test/sql/pact_dashboard_messaging_test.sql` inside BEGIN/ROLLBACK. It creates temporary buyer/seller/member fixtures and verifies initiation direction, member-first rejection even after manually accepting a draft, role/example spoof resistance, first-request handling, deduplication, shared direct-thread reuse, privacy and blocking. The tests passed before and after applying the migration and leave no fixture accounts or messages behind. Existing `pact_messaging_test.sql` now uses the first-request-message behavior and requires two available member accounts when run separately.

Web dashboard release validation: the full regression suite passed with 312 tests and 18 existing skips. The final focused messenger/outbox run passed 8 tests with mock Supabase configuration, including desktop/narrow layouts, Enter-to-send, retry identity, failed-draft removal, request acceptance and sign-out clearing. The saved-content persistence suite passed 5 tests. The production web bundle builds and passes the prebuilt-bundle check. No mobile build or installation was performed for this web-only pass. Existing full-project analyzer notices include generated native dependency examples and earlier unused code; the new web messaging component has no scoped analyzer issues. Security review found no new exposed-definer findings for the private contact-policy helpers; the pre-existing no-policy INFO on messaging tables is the deliberate RPC-only/default-deny design.

Final web deployment: `041f8ce5.dwelling-iq-app.pages.dev` is published on the existing `main` alias at `https://dwelling-iq-app.pages.dev`. Live browser checks confirmed Messages inside the original buyer, seller and member dashboard shells. The final contrast correction passed both web widget tests, including the dashboard light-theme context and request/reply flow; the production JavaScript hash matches the final local bundle. Directory inspection exposed only eligible professional contacts. No live conversations or outreach messages were created during browser QA.

## Full-page web inbox and buyer demos

Messages now replaces the buyer, seller or member dashboard shell for the duration of the conversation, with an explicit Back to dashboard control. The normal workspace sidebar remains black on the other pages; the buyer sidebar also remains available while saved deals load or fail to load. Public copy/content keys and owner media are retained.

Outgoing web bubbles animate around the rainbow on a 16-second loop, with contrasting text. The animation pauses when the page is inactive and respects the device's reduced-motion preference. Incoming bubbles remain neutral. Read receipts use the existing server read cursor and appear in red; a successful send alone is labelled Sent.

The buyer inbox includes Alex Morgan (Demo broker) and Jamie Chen (Demo lender). These are explicitly fictional, browser-memory conversations, not Supabase users or professional directory records. Text sent to their reserved demo IDs is intercepted locally before any backend call. A simulated contact reads after about 0.9 seconds and replies after about 2.2 seconds; retrying the same message ID cannot duplicate the reply. Demo history is scoped to the signed-in account in memory and resets on a full page refresh. Real conversations continue using the existing permissions, shared message store and outbox. No new database rows, image storage, credentials or outreach messages are required for the demos.

Validation for this change: all six configured messenger/profile tests pass, including the new demo-only send/reply/read test; the final three web tests also pass without updating the golden image. Scoped analysis reports no issues for the inbox, demo service and navigation helper. The full regression run passed 311 tests with 18 existing skips before stalling on its last compiler step; clearing generated test compiler data and running the final two listing tests independently passed. All five configured saved-content persistence checks also pass, including published image/text overrides surviving fallback changes. The production web bundle builds and passes the prebuilt-bundle check.

Live QA also found the owner-only public-copy editor overlapping Send in the full-page view. Messaging now hides that overlay through scoped lifecycle tokens and restores it on exit, without changing edit preferences or permissions. All 11 configured messaging/profile and saved-content tests pass after this correction; scoped analysis has no errors (the existing inline editor retains seven unrelated brace-style notices). Final deployment: `3354f62e.dwelling-iq-app.pages.dev`, served by the existing production alias. The production JavaScript hash matches the built bundle. Live buyer checks confirmed the full-page inbox, local demo send, read receipt and automatic broker response, and black navigation on Resources. No real users received test messages.

## Dashboard-contained messaging and softer gradient

The dashboard Messages destinations now keep their existing header and black workspace navigation. Buyer and seller messaging occupies the remaining dashboard body; the member inbox uses the remaining bounded height directly instead of the previous scrollable/height-capped panel. Compact member layouts retain the dashboard view selector above the inbox. The standalone Messages route is retained for existing direct/profile links.

Sent bubbles use a diagonal gradient through three neighboring hues, moving continuously through the rainbow over 48 seconds. All gradient stops stay below 0.16 relative luminance so white text remains legible throughout the transition. Reduced-motion and background-page pause behavior remain intact. Incoming bubbles, read cursors, demo contacts, account permissions and stored message data use the existing behavior.

The dashboard header's Messages shortcut now calls the current workspace's Messages destination too. Public and standalone profile links keep the standalone route; opening Messages from a dashboard's header or sidebar retains that dashboard shell.

Validation of the completed dashboard-contained gradient release: the full project suite passes with 317 tests and 18 existing skips. The configured messaging/profile and saved-content suites pass all 11 tests; the three web messaging tests also pass against the updated golden without regeneration. Layout regressions verify the buyer, seller and member headers remain visible and the inbox fills their remaining content bounds at phone and desktop widths. The release bundle builds and passes the prebuilt verification.

Published as `b5f9ede0.dwelling-iq-app.pages.dev` on the existing production alias `https://dwelling-iq-app.pages.dev`. The live JavaScript hash matches the final tested bundle. Browser verification confirms the header Messages shortcut retains the Buyer dash header and black workspace sidebar, with the inbox using the remaining dashboard area. Demo chat remains clearly labelled and local-only.

## Vertical message-order gradient and PHP exposure safeguards

Outgoing web bubbles now form a continuous top-to-bottom colour progression through sent-message order: start hue 330 (pink), advance four degrees per outgoing message, with each bubble spanning the same four degrees vertically. Received messages do not advance the gradient. Message text no longer hashes to an arbitrary colour, and there is no clock-driven animation. The top colour of the next sent bubble exactly matches the bottom colour of the previous one. Colours retain the existing white-text contrast bound. The dashboard frame and shared account/message data are unchanged.

Configured tests verify vertical alignment, stable colours after 30 idle seconds and continuity across two unrelated sent texts. All 11 configured messaging/profile and saved-content checks pass, and the three final web tests pass against the updated golden without regeneration. The full Flutter suite passes 317 tests with 18 existing skips; 34 Node security/API/media/push tests pass. The web inbox has no scoped analyzer issues. The release also passes source and built-output no-PHP artifact checks. See `../security/php2shell-2026-10.md` for the audited exposure, safeguards and limitations.

Published as `dc343588.dwelling-iq-app.pages.dev` on the existing production alias. The main bundle hash matches the tested release. Live benign checks confirm the PHP/CGI guard and protected API authentication responses; the app and health route continue to load normally.

## Role-based mobile workspaces — build 6 (22 October 2026)

Pact 0.3.0 (6) builds successfully for iOS release with the existing development team. CoreDevice confirmed installation on the connected iPhone 15 Plus (`com.dwellingiq.dwellingIq`). Automatic launch was rejected because the phone had locked; unlock it and tap Pact to open build 6. The app now includes the lavender/white mobile shell, Buyer/Seller/Member navigation, shared business bookmarks, seller save charts, authorized client conversations and native professional inquiry status/notes. See MOBILE_WORKSPACES.md for data sources and remaining web handoffs. Live Firebase/APNs push delivery remains unverified.

Verification: full Flutter regression 326 passed (18 existing skips); final configured mobile/messaging/saved-content run 18 passed; targeted Dart analysis clean. Owner-only analytics SQL tests passed in a rolled-back live transaction, anonymous access is revoked, and the database measured approximately 17.2 MB.

## Full-screen styling and professional matching — build 7 (22 October 2026)

The iOS release build 0.3.0 (7) compiles and installs on the connected iPhone 15 Plus. It includes the full-screen lavender background, overlapping portrait/cover member profiles, shared experience editing, protected credential-review controls and the deal-specific professional finder. CoreDevice successfully launched build 7. The final contrast polish uses dark web profile navigation on the light background.

Production web deployment: `be19a579.dwelling-iq-app.pages.dev` on the existing project/main branch. Production `main.dart.js` matches the final local bundle. The previous PHP/CGI edge guard still returns 404, and health returns 200. Browser verification confirmed the redesigned member header, preserved example portrait, web My team finder entry, criteria submission and honest empty results. No real member was contacted, and no real profile experience or credential was fabricated/verified during testing.

See PROFESSIONAL_MATCHING.md for entry points, scoring, public data limits, qualification checks and test coverage. Existing user text, uploaded images and private deal records were preserved. Firebase/APNs delivery configuration remains unchanged.
