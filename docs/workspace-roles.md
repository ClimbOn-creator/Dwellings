# Permanent account workspaces

Buyer, Seller and Member are account-level choices shared by mobile and desktop.
The mobile switcher and its device preference are no longer used. Accounts
without a saved workspace must confirm one of the three choices. Restored and
OAuth sessions use the same gate. Failed reads or saves never default to Buyer.

`public.account_workspaces` is the source of truth. Clients may read their own
row and insert it once, but cannot update or delete it. Concurrent choices use
the first saved role. This selection does not grant professional credentials,
membership approval or access to others' data; existing access checks remain.

The migration recognizes existing professional owners without seller listings.
Other legacy accounts choose once: the old `account_role = user` does not
distinguish Buyer and Seller. Local preferences and editable auth metadata are
not trusted for a permanent role. Published copy and media remain untouched.

Migration `20261026165837_permanent_workspace_role.sql` is applied to DwellingIQ.
`test/sql/workspace_role_access.sql` verifies permissions with temporary fixtures
and ROLLBACK. Run `flutter test --no-pub`, plus the configured tests:

```sh
flutter test --no-pub --dart-define=SUPABASE_URL=https://editor.test --dart-define=SUPABASE_PUBLISHABLE_KEY=test-public-key test/pact_mobile_workspace_test.dart test/site_editor_persistence_test.dart
```

Phones need an updated mobile binary. Rebuild the web bundle before publishing.
