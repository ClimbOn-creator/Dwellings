# Dwellings / Affinity: preserve owner edits

The owners explicitly require that published text and uploaded pictures survive all future redesigns, refactors, rebuilds, deployments, and database migrations. Preserve them unless the user explicitly asks to replace/reset those saved edits. A general request to revamp the app is NOT permission to discard saved content.

- `public.site_content` and the `site-media` storage bucket are the persistent source of truth. Bundled copy/assets are fallbacks only; published overrides always win.
- Never delete, truncate, reseed, overwrite, or mass-reset saved content/media during normal development or deployment. Do not replace these with local-only state.
- Preserve the `contentKey` values already assigned to widgets even if files, routes, components, or layouts are renamed or moved. Carry the same key to the replacement widget.
- The keys in `lib/services/site_copy_catalog.dart` are immutable IDs. Image widget `contentKey` / `contentId` values are permanent slot identities, independent of filenames. To revise a default, change its value under the existing ID. Do not generate a fresh ID from new wording or a new asset filename. Update both the widget fallback and registry value together.
- Give new content a new stable ID. Do not reuse retired keys for unrelated content. Retain saved records for removed components so their content can be recovered or restored later.
- Preserve the editor RPC's concurrency checks and failure behavior. Failed/network-interrupted saves must not replace the last confirmed published value. Authentication changes must revoke the edit UI immediately.
- Keep private messages, account data and calculated live values out of the public copy store. Editable sentences use live-value placeholders.
- Before completing future changes involving these components, run `flutter test --no-pub`; run `test/site_editor_persistence_test.dart` with the mock Supabase defines documented in README. Confirm that changing a bundled text/image fallback under the same permanent key still displays the previously published override.
