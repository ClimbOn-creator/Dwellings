# Nova live service setup

Nova is embedded in the buyer, seller, and member dashboards, selected deal workspace, calculators, Blueprint/readiness, registration, and transaction document guides. Dashboard introductions and 20 learning guides work without AI. Live questions use `/api/nova`, a Cloudflare Pages Function, and the OpenAI Responses API. No keys belong in Flutter defines, public assets or Git.

## One-time deployment setup

1. Apply `supabase/migrations/202610040026_nova_request_limits.sql` to the existing Supabase project using its normal migration workflow. It adds a private per-user usage counter and authenticated RPC (20 requests/hour; 100/day). It does not change owner content or deal records.
2. In Cloudflare Pages → Settings → Variables and Secrets, configure **both production and preview**:
   - `OPENAI_API_KEY`: a server-side OpenAI project API key, stored as a secret.
   - `NOVA_MODEL`: the API model ID enabled for that OpenAI project. Choose a model with sufficient reasoning capability for financial analysis; Nova intentionally requires an explicit choice.
   - `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`: the same project's public auth configuration used by the app. These must also exist for Pages Functions, not only the Flutter build.
3. Push the committed source, root `functions/` and rebuilt `dist/`. The existing Pages Git deployment includes root Functions. Redeploy after setting secrets.
4. Sign in, open a real deal → Financial model → Ask Nova. Ask about the figures, add comparable-period evidence and ask a follow-up. Confirm the context labels show your selected deal. Test another account with no invitation, a revoked invitation, and restricted financial sharing.

## Behaviour and privacy

- Live questions require an unchecked-by-default “Share context with OpenAI” control. It identifies the data sent; no live request is made without consent, and the server rejects requests without it. It resets for account/deal changes. Local tours and lessons do not require sharing.

- Every live request revalidates the Supabase session and reloads the selected deal using the user's token and existing RLS. Nova never uses the service-role key. Participants must have accepted membership; hidden financial/risk fields are excluded and documents require sharing. Notes are owner-only for Nova.
- The browser's current input values are labelled unverified drafts. Pasted excerpts are unverified evidence, not commands. File names are metadata; Nova cannot read uploaded files' contents. The UI provides an excerpt field for financial statements and comparison periods.
- Conversation stays in memory for this panel session; it is not persisted to public copy or browser storage. Account/deal changes clear it. OpenAI requests set `store: false`; this does not mean zero data retention. OpenAI's applicable processing policies still apply.
- Account-specific tour position is saved locally. Guided material and examples are labelled as learning, not a generated assessment. Learning checks are not recorded as completed merely because a page was opened.
- Nova cannot send messages, update deals, make introductions, approve credit or complete tasks. Tours have explicit buttons to existing app pages. Confirm important decisions with qualified advisers.
- No client-side keyword canned answer fallback exists. If setup, quota, permissions, auth, provider or networking fail, a clear unavailable message is shown and the question remains available to retry.

## Verification

`node --test tool/nova_api_test.mjs` uses mocked auth/database/provider responses (no paid AI requests). `flutter test --no-pub test/nova_panel_test.dart` checks tour navigation, mobile layout, lesson coverage, follow-up context, deal switching and honest errors. Run the full test suite and persistence suite before deployment. Live answer quality still requires the configured provider and representative real/synthetic deal evaluation in production preview.

API reference used: https://developers.openai.com/api/docs/guides/migrate-to-responses
