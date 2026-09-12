# Blueprint and My Profile refresh

- Blueprint: dark teal editorial header, rounded question cards and fields, slide/fade question transitions, chapter-dependent color wash, parallax background under the original permanent image slot.
- Profile: plum/slate photographic parallax header retaining its original image slot, warm atmospheric background with scroll-responsive orbit lines, tinted hover-responsive statistic cards.
- Shared motion preference remains affinity.landing.motion. Explicit choice overrides system reduced motion; editing pauses motion.
- Existing account/profile operations and Blueprint draft/cloud-save logic retained. No public content or media reset.
- Added phone-sized question navigation/answer-retention test and explicit motion-preference test. The phone test exposed dropdown and action-row overflow; fixed with expanded dropdowns and wrapping buttons.

Validation: 56 existing Flutter tests passed, plus 2 new focused tests and 4 configured editor-persistence tests (62 total). Release web build and prebuilt bundle check passed. Desktop/390px Blueprint browser review passed. Deployment: https://c771353d.dwelling-iq-app.pages.dev (production dwelling-iq-app).
