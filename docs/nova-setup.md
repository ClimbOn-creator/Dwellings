# Nova app walkthrough

Nova is now a deterministic, click-through product guide using the supplied transparent character atlas. There is no chat composer, question input, AI provider, private financial analysis or API-key requirement. The former `/api/nova` chat endpoint returns 410 and never reads request context or calls an external provider. Its old usage-counter migration remains in history but is not needed for this guide.

## Behaviour

- On first app load Nova introduces the guide. Visitors can choose Buying, Selling / succession, or Professional member using buttons.
- Next and Back navigate through real app screens, with highlights where the relevant screen area is available. The guide includes the dashboard, calculators/plan, team, government programs, transaction room, documents, privacy, Blueprint, readiness, document guides and consulting/calendar.
- The transaction room used for training is explicitly fictional. Its bundle is supplied locally; no example is inserted into Supabase. It does not change the real recent-deal preference. While the tour is open, the underlying app is read-only, preventing accidental edits, bookings, document actions or messages.
- Only Finish training marks completion. Closing or Later pauses the guide and keeps the saved step. Replay does not erase earlier completion.
- For signed-in accounts, the private account profile metadata `nova_training` stores version, role, step and completion timestamp through the existing Supabase Auth user endpoint, using that account’s captured token. This needs no new database columns or migration. All other profile data is left intact.
- Guest progress stays on this device. Account-scoped local caches are separate. Failed profile synchronization preserves completion locally and retries on a later load; the profile training card distinguishes a confirmed profile save from pending sync.
- A completed account does not get an automatic introduction on another device. Nova can be requested again via Nova walkthrough in the menu, Show me around with Nova on the pages, or Replay app training on My profile.
- All six moods render directly from the original transparent atlas: welcome, studying, planning, curious, reassuring and celebrating. The supplied PNG is copied unchanged. Pose transitions respect reduced motion; no looping animation is required to use the tour.

## Verification

`flutter test --no-pub test/nova_panel_test.dart` covers first-load welcome, completion across devices, account switching during a save, offline retry, pause/resume, replay, mobile/desktop navigation, all moods and safe fictional room views. `node --test tool/nova_api_test.mjs` verifies the old chat endpoint cannot read private context or call a provider. Run the full Flutter and content-persistence suites before deployment.

Metadata API reference: https://supabase.com/docs/reference/dart/auth-updateuser
