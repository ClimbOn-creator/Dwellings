# Pact messaging audit — 21 October 2026

Read-only inspection of `/Users/willrussell/Desktop/Pact` and its configured Supabase project `tjcrxnqnzaheytzmbyri` (DwellingIQ).

## Verified baseline

- Flutter 3.44.2 / Dart 3.12.2 project, with web, iOS and Android targets. Existing accounts use Supabase Auth and `profiles`; professional identities are separate `provider_profiles`.
- Live database: 16,157,843 bytes (~16.2 MB decimal); 2 Auth accounts, 2 profiles, 0 member conversations, 0 member messages. This is a point-in-time measurement, not a capacity guarantee.
- Supabase object metadata: 157,348 bytes in profile-photos and 112,682 bytes in site-media. R2 object usage was not measured.
- `MemberNetworkService.messagingEnabled = false` disables messaging across the old member UI. Old conversations are tied to two provider IDs and verified active/trial professional memberships. They cannot represent general-account or group chat.
- Old tables have RLS enabled and no policies: direct client access is denied. Existing SECURITY DEFINER RPCs implement membership checks. This is not evidence of public message disclosure.
- Several old RPCs retain anonymous EXECUTE grants. Revoke unnecessary grants while retaining internal authorization checks.
- Old send RPC has no client idempotency key. A timeout after commit followed by retry can duplicate messages.
- Old load fetches all messages, then marks the entire conversation read at server NOW. This can mark unseen messages as read. UI polls every 15 seconds.
- Existing read state is server-backed and can sync across devices; reuse the principle, with a displayed-message cursor.
- Profile photo uploads currently use public Supabase Storage. Do not claim all images already use R2.
- `property-files.js` uses private R2 with Supabase authorization, 15 MB limits, type/extension/magic-byte checks and metadata. It does NOT perform malware scanning; `validated` only means basic file validation. Audit event errors are swallowed. It cannot be advertised as a scanned chat attachment system.
- Current OAuth and magic-link redirects use `Uri.base.origin`, requiring native redirect configuration before enabling those flows on mobile. Existing email/password sign-in can be reused.
- Android release currently uses debug signing. No Firebase/APNs setup has been verified. Installing via Xcode does not establish push readiness.

## Safe reuse / replacement

Reuse Flutter targets, existing Auth identities, existing profile data, brand and preserved content keys, and R2 authorization patterns. Preserve all existing records and owner-edited public content. Replace the provider-pair-only messaging foundation with account membership, explicit requests, retry-safe sends, bounded reads and exact read cursors. Keep old APIs disabled in the UI until the shared implementation is verified.

## Security follow-up

Supabase advisors also flag 47 anonymously executable SECURITY DEFINER functions across the wider app, public-schema citext, and disabled leaked-password protection. These need review by function, not blanket revocation: some public functions are intentional. Authenticated definer-function advisories likewise are not proof of an exploit.

- https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable
- https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Storage / release rules

Keep message bodies bounded, paginate history, store one read cursor per membership, never store files/base64 in Postgres, and expire push delivery records. Monitor total database size including indexes. Target <700 MB with intervention before 850 MB for a self-imposed 1 GB ceiling; Supabase Free has a separate 500 MB DB allowance. Retention and archive policies must be agreed before production growth; never silently delete transaction history.

Release requires cross-account access tests, safe retry tests, read-race tests, reconnect tests, physical-device notification verification, release signing and backup/restore verification. No claim of end-to-end encryption or an impregnable system.

## Visual direction

Use the supplied references as design inspiration only. Mobile uses bottom navigation. Profile uses image 5's wide cover, overlapping portrait, centered identity and clear actions, adapting to actual Pact profile data; no fabricated ratings/reviews. Inbox uses image 1's restrained spacing, avatars and readable bubbles. Future transaction cards can borrow image 2's hierarchy. Calls, voice notes and review creation are outside this phase.
