# Pebble page guides

Pebble is a click-through product guide using the supplied transparent character atlas. There is no chat composer or AI provider. The retired `/api/nova` endpoint returns 410.

## Behaviour

- The Pebble character button is in the shared page header. It explains the current page and selected dashboard view only, without pushing or replacing routes. Next, Back and Done stay on that page. Inline replay controls are retired.
- The first visit introduces the current page. Completing that automatic introduction saves completion to the existing private profile metadata `nova_training`; previously completed accounts stay completed. Completing a first page guide records completion. Replaying a page on an already completed account preserves its saved training progress.
- Calculator guides are short overviews. Clicking any blue info button opens the right-side Calculator guide with a definition, calculation method, example and source records. All 37 buyer fields and 14 seller fields are covered. The guide uses static examples and never changes entered figures. It closes when changing routes or starting Pebble.
- Pebble still moves beside highlighted content. The page is dimmed more strongly, with a gentle tint over the target and a softer speech bubble. Offscreen targets are brought into view.
- Motion switches have been removed from landing, consulting, personal pages, listings and the comparison quiz. Old off preferences no longer disable those pages. Editing still stabilizes moving content for reliable owner edits.
- Training storage keys, artwork paths and existing permanent content IDs retain their original names for compatibility. Published owner edits continue to override bundled fallbacks. No migration or AI key is needed.
- Guest completion stays on the device. Signed-in completion uses account-scoped caches and the private Supabase Auth user metadata; failed saves retain the local completion for retry.

## Verification

Run the full Flutter suite and the owner-content persistence suite documented in README. The Pebble tests cover page-only completion, staying on the same route, account state, sidebar explanations, field switching and preservation of entered figures. The existing motion tests verify that animations stay enabled with no toggle while editing remains stable.

The landing page has no Pebble entrypoint or automatic introduction. Pebble is requested through page headers, not the navigation dropdown. The Transaction Room navigation entry opens the dedicated saved-room list; opening a deal enters its actual private room. Main Resources, comparison, profile and consulting pages retain the Affinity header.
