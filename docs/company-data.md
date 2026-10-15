# Private company data dashboard

Open `/?module=owner-data` while signed in with either existing `affinity_admins` account whose role is `owner`, or open the navigation menu and choose **Company data · owners only**. Reviewers, content editors and ordinary members do not gain access. No allow-list entries were added or changed.

`load_affinity_company_data` checks the current database owner role on every call. It returns aggregate JSON only. The page clears its payload on authentication events, ignores obsolete requests and rechecks access every minute. The server denies direct report requests after role revocation. Summary downloads are owner-initiated CSV files with spreadsheet formula escaping.

## Coverage and definitions

- All-time operational totals, current roles, profile location preferences, professional titles, current team selections, membership states, pipeline stages and learning activity.
- Date filter (7/30/90/365 UTC days, inclusive of today) applies to account registration trends and optional feature visits. Other totals are explicitly all-time/current-state. Location/profession/team rankings show the top 20.
- Real professional totals/team rankings exclude `is_example` profiles; example profile count is displayed separately. Table inventory includes examples and system records.
- Saved locations describe preferences, not verified residence. Team selections do not prove a hire, registrations do not prove attendance, stages do not verify a closing, and membership states are not collected payments.
- Database volume includes rows/indexes in 27 explicitly tracked tables. Uploaded bytes use current deal-document and learning-media metadata; neither number is a complete hosting bill, backup measurement or all-bucket inventory.
- Existing records stay in their authoritative tables. This dashboard creates no duplicate archive of private documents, messages or financial inputs. Operational deletion still removes records from current summaries.

## Optional usage measurement

`affinity_usage_daily` stores only UTC date, one of six fixed feature categories, and an incrementing visit count. It has no account ID, visitor ID, IP, session ID, full URL, location, message/document body or form value. RLS and revoked table grants prohibit direct access; narrowly scoped functions handle counters and owner reporting.

The app records navigation counts only after explicit opt-in, only while signed in, and excludes owners. Consent is stored per account on that browser, with **Usage privacy** available in the header to change it. Visits within 30 seconds in the same area are deduplicated in memory. Anonymous daily aggregates persist across deployments and cannot be linked back to users. They are neither unique-user counts nor verified business outcomes. Caller-supplied counters can be noisy and are not suitable for billing.

No historical click backfill, signed-out tracking, quiz-answer tracking, search tracking, attendance verification, external conversion tracking or payment integration is included. The dashboard identifies these gaps. Local-only drafts do not appear in company totals.

## Validation

- `test/company_data_test.dart`: locked direct access, hidden entry, readable phone/desktop reports, date selector and CSV safety.
- `test/company_data_session_test.dart` with the mock backend defines: owner sign-out clears data; no tracking before opt-in/after opt-out or sign-out; owners excluded; only fixed category field sent.
- `test/sql/company_data_access.sql`: live backend transaction, rolled back: both owners allowed; anon, ordinary user, reviewer, forged user metadata and revoked owner denied; bounded date ranges; aggregate report shape; analytics field allowlist.
- Security advisors: the new counter table intentionally has no direct RLS policy or client grants (RPC-only). New security-definer RPCs have fixed search paths, no anonymous execution, explicit authorization and minimal output. Existing project-wide advisor warnings were not changed by this feature.

## Dataset explorer and comparisons

The owner workspace now has a dark dataset explorer with a persistent left list on desktop and a dataset sheet on smaller screens. Thirty-five datasets have separate graph/detail views, including independent location, role, profession, membership-status and pipeline-stage snapshots. Choose **Compare two datasets** to select A and B, switch between grouped bars and lines, and inspect values by hovering or tapping a point. Breakdowns, daily counts and definitions are separate detail tabs.

`load_affinity_data_explorer` calls the existing owner-checked reporting function and adds 26 dense daily UTC histories, period totals and preceding-period totals. Source queries are a fixed server-side allowlist; no caller can supply table names or SQL. No raw profile records, messages, documents or financial contents are returned. The older RPC remains available for older deployed clients.

Charts show daily counts through 31 days, aligned seven-day sums through 90 days, and calendar-month sums for longer windows. Bucket sums retain the selected-period totals. Previous-period percent changes are unavailable when their denominator is zero. These are retained-record creation/completion dates, not a reconstructed ledger of deleted records or historical status changes.

Current breakdowns and the sidebar are labelled as current totals; app-area breakdowns use the selected period. Attachments without timestamps and storage-size datasets show current snapshot graphs. Comparing a snapshot to a historical dataset switches both to current values. Mixed byte/count comparisons use explicitly labelled separate scales. Two metrics shown together do not establish a conversion rate or causal relationship.

CSV reports include daily histories and current/selected/previous-period totals. A periodic refresh preserves the dataset and comparison selections; authentication changes still clear private data immediately.

Security tests in `test/sql/company_data_explorer_access.sql` cover the new RPC, including both owners, denied roles, revoked access, bounded windows, complete histories and reconciliation of daily sums to period totals. The Supabase authenticated SECURITY DEFINER advisory is intentional for this aggregate owner endpoint: its body checks the database owner allowlist before reading across users' records, has a fixed search path, and has no anonymous execution grant.
