# Profile stability, desktop profile and member ROI

Profiles no longer poll and reconstruct their account section every 20 seconds.
Independent account, workspace and professional reads run concurrently with an
8-second limit. Optional reviews have a 3-second limit; the overall profile read
ends within 12 seconds and retains confirmed identity on failure. Refresh is
explicit, on resume and after edits. Account changes revoke the previous identity.
The account section uses a bounded, immediate disclosure instead of ExpansionTile.
Role recognition also has a 12-second limit and a retry state.

The phone profile keeps its existing header and content layout. Desktop profile
surfaces opt into a landscape banner, overlapping portrait, horizontal identity
row and two-column content with compact tabs. Saved profile photos, biographies,
professional details and editable site content retain their original identities.

Member Studio includes Return on Pact, also accessible from the phone Member
home screen and the `member-roi` web module. The dashboard has 30/90/365-day
periods, profile views, qualified inquiries, consultations, transactions, reported
Pact-attributed fees, membership cost and net ROI. Annual cost is user-entered;
shorter periods prorate it by days/365. ROI = (revenue - period cost) / period cost.
Missing/zero cost never produces a misleading percentage. No example earnings or
subscription prices are seeded into real accounts.

Profile views count signed-in visitors once per owner/viewer/UTC day; self views
are excluded. Tracking is non-blocking and begins with the migration. Lead
milestones are retained when an inquiry reaches qualified/contacted, consultation
or won, and remain counted if its later status changes. The owner can add private
Pact-attributed outcomes and link an inquiry to avoid double-counting that workflow
milestone. Recorded fees are explicitly member-reported, not audited billing.
Removing a recorded outcome voids it and corrects the revenue total.

`20261026213157_member_roi_dashboard.sql` is applied to DwellingIQ. Client RLS
restricts costs and outcomes to their owner. Private visitor identities and lead
milestones are accessible only through actor-checked aggregate RPCs. Private
internal tables deliberately have no client RLS policies/grants. The SQL checks
in `test/sql/member_roi_access.sql` use temporary fixtures ending in ROLLBACK.

Tests cover profile stability after a minute, stalled reads, phone/desktop layout,
ROI arithmetic, missing/zero cost, failed reads, owner isolation, member-only
access, repeated views, milestone persistence, linked-outcome deduplication and
voided revenue. Mobile build 9 includes these changes.
