# Shared professional profiles and deal matching — build 7

## Interface and entry points

Mobile paints the Pact lavender background outside SafeArea, behind the status bar and device cutouts. Content stays inside safe insets. The shared professional header uses a cover, overlapping circular portrait, name/headline, company, service areas and specialties, with Pact’s rounded cards and purple/pink accents. Saved account media continues to use R2 and the same profile-media endpoint. Existing example portraits still use their permanent site-image slots.

Owners use Profile → Edit experience on mobile. On web, Profile → Edit profile → Edit experience & matching details opens the same editor; save existing profile drafts first. General identity/description/specialty editing and reviews remain available. Public member profiles display the shared header and structured experience. Existing About/write-up content, permanent copy IDs and uploaded media are preserved.

The professional finder opens from Buyer mobile Help → Match professionals to a deal, and web Buyer/Seller My team → Match professionals to a deal. The same account can switch mobile workspaces. A user may choose an existing authorized deal to prefill amount/currency and a recognizable Canadian province; unmatched fields remain explicit choices. No arbitrary city-to-jurisdiction guess is made. Users choose profession, required service, industry, transaction type and jurisdiction, with optional amount and credential requirement. Changing criteria clears old results.

Opening a candidate profile does not send private deal information. Message opens the existing server-authorized conversation flow; members still cannot cold-contact buyers/sellers.

## Shared records and saves

`provider_profiles.professional_background` holds bounded public structured data: services, industries, transaction types, jurisdiction codes, typical deal-size bounds/currency, availability, employment, anonymous deal examples and credential claims. Maximum encoded JSON is 24 KB; up to 16 entries per taxonomy list and 12 records per history/credential group. Descriptions are bounded. Existing provider descriptions, free-text specialties, contact details, photos, review records and account identities are not reseeded.

The existing `pact_save_profile` RPC remains the save path. An additive change validates structured data, preserves omitted fields and keeps account timestamp concurrency checks. Background updates invalidate the account edit revision. Failed/stale saves keep the editor contents. Availability maps to the existing accepting-leads flag when confirmed; unknown does not silently opt a member into recommendations.

`pact_professional_matches(criteria)` is an authenticated invoker wrapper around a private server scorer. Candidate records must be verified, non-example, active/trialing members of the requested profession, excluding the caller’s own provider identity. Existing provider_type/verified indexes support candidate filtering. Results keep only the best 40, with deterministic ID tie ordering; all qualifying candidates are considered, rather than taking the first 40 before scoring.

## Matching rules

- Service specialty: 35 points for an exact structured service match.
- Industry: 30 points for an exact structured industry match.
- Transaction experience: 15 points for transaction type, plus 10 if the optional amount is inside the stated same-currency range.
- Location: 10 points for exact declared service-jurisdiction coverage.

About wording, keyword frequency, subscription tier, sponsorship and review count earn no ranking points. There is no embedding service or external AI call. Currency conversion is not guessed. Missing evidence earns no points, and missing required service/jurisdiction/availability/credential or requested range information is explicitly flagged as more information needed.

“Strong fit” requires eligibility, at least 85 points, matching service and industry, and a matching transaction type. Other qualified results show Relevant experience or Limited alignment. Incomplete/ineligible records show More information needed and the actual reasons. These are relevance labels, not probabilities of success, legal endorsements or guarantees that a professional is the best choice.

## Credential verification

A Pact-verified profile is distinct from a verified professional credential. Credential claims include a type (professional licence, designation, certification or education), issuer, public registration number, jurisdiction and optional expiry. They are self-reported until independently reviewed.

Verification records live in `pact_private.professional_credentials`, with RLS and no direct client table grants. The private verification helper requires an existing Affinity administrator, rejects self-review, checks the provider revision and snapshots the reviewed claim with a SHA-256 fingerprint and reviewed profession. Administrators see verification/revocation controls on credential cards and must independently check the issuing register before approving. The app does not automatically verify licences or create approval records from About text or profile badges.

Editing any claim field, changing its profession, expiry or administrative revocation prevents it from continuing to qualify. Public credential reads return only current approvals matching the current public claim and profession; reviewer identities are not returned. Anonymous reads are allowed only for public verified profiles (owners may read their own). The public matching endpoint rejects anonymous requests.

For lawyers, M&A lawyers, realtors and mortgage brokers, the product always requires a verified professional licence for the selected jurisdiction. An education credential or unrelated designation cannot satisfy this rule. For other professions the user can require a verified professional credential; education alone does not satisfy that filter. This is Pact’s matching policy, not a comprehensive statement of each jurisdiction’s legal requirements.

## Storage and verification

The migrations add structured profile text and compact approval records, not an event log or photo blobs. Media stays in R2. Database size after deployment was approximately 17.3 MB, below the requested 1 GB ceiling; ongoing growth still requires monitoring.

- Full regression: 331 passed, 18 existing skips.
- Configured mobile/profile/messaging/saved-content checks: 23 passed; phone previews reviewed, including status-bar safe area and overlapping portrait.
- Scoped analysis: clean.
- `test/sql/pact_professional_matching_test.sql` passed in rolled-back live transactions: exact weighted ranking, no About/paid-tier boost, jurisdiction rejection, verified-credential requirement, blocked self-verification, changed-claim/profession invalidation, licence vs designation distinction, stale-save rejection, shared biography sync, bounded validation and anonymous permissions. All temporary accounts rolled back.
- Actual anonymous HTTP calls: public credential lookup 200; matching denied 401.
- Existing Supabase advisor notices remain; no new public definer endpoint was introduced. The private verification table’s no-policy notice is intentional because it is accessible only through the checked private helpers.

SQL migrations: `20261023032708_pact_professional_experience_matching.sql` and `20261023035638_pact_credential_profession_binding.sql`.
