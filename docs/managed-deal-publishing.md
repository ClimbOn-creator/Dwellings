# Pact-managed deal publication

Buyer private saved deals and assessments are not seller listings. Saving a buyer
pipeline record does not submit, publish, or expose its contents to members.

The retired `submit_deal_to_member_studio(uuid)` RPC has no anon/authenticated
EXECUTE grant. Its existing records remain intact. Clients also have no direct
mutation grants on member_deal_opportunities or business_sale_bulletins; checked
Pact management RPCs remain responsible for listing creation and anonymization.
The existing seller listing management API still requires Pact administrator
access to create public listings. This change does not introduce self-service
seller publication or a new seller onboarding flow.

Learning authorship uses existing owner-approved learning_publishers records,
not paid membership, account metadata, or a workspace selector. Approved authors
(and the owner) see the feed's floating plus button. Permissions refresh after
auth changes, every thirty seconds, and immediately before opening the composer;
existing backend permissions are checked again when publishing. The feed uses
two columns at content widths of at least 700 pixels, and one below that.

Header content-editor and message shortcuts are removed. Dashboard Messages
navigation, the content-studio route, and saved owner content remain intact.

Verification: test/sql/pact_managed_deal_submission_test.sql; full Flutter suite;
configured site_editor_persistence_test.dart; learning layout and dashboard tests.
