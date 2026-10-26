# Shared sign-in, profiles and member Friends

The web app and native phone app now use `AuthPage` and `PactAuthSurface` for
sign-in. The image spans the full upper screen; desktop extends the same layout
with a wider card. Account creation progresses through three short steps. Native
sign-up confirmation links use the app callback, matching native Google sign-in.
Existing editable copy IDs, account roles, uploaded photos and site content remain.

`PactProfilePanel` is shared by mobile and the desktop profile. Profile cover
photos fill the upper region, with an overlapping portrait, Overview/Experience/
Friends sections and a collapsed account-preferences area. Advanced desktop
account tools remain accessible from Account details & tools.

Friends requires a saved Member workspace. Discover searches member names and
companies; it does not expose private usernames or email addresses. A member
sends a request, and its recipient explicitly accepts. One canonical relationship
supplies the accepted friend to both profiles. Requests can be declined/cancelled,
and either participant can remove a friendship. Profiles and Friends refresh on
return and periodically while open; pending/accepted state persists across devices.

`20261026171737_member_friendships.sql` adds the protected relationship table and
narrow authenticated RPCs. Privileged implementations live in `pact_private` and
check the current actor and both accounts' membership. Clients can read only their
own relationships and cannot directly create/update/delete them. Request creation
is serialized per pair, so crossed or repeated requests cannot silently accept or
duplicate a friendship. Existing professional approvals and messaging rules remain.

The connector's migration endpoint returned expired-request errors. The tested
migration was applied transactionally using the SQL connector and recorded under
its CLI-generated version in migration history. `test/sql/member_friendships_access.sql`
verifies mutual persistence, consent, duplicates, non-members, outsiders, private
field filtering and removal with temporary fixtures ending in ROLLBACK.

Version 0.3.0 build 8 contains this update. The signed mobile target is
`lib/main_mobile.dart`; web uses `lib/main.dart`.
