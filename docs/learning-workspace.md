# Learning workspace

Learning keeps its feed, seminars, comparison quiz and resources. The map,
contributor-approval navigation and private pipeline are replaced by Transaction
Room and Acquisition Journey. Deprecated view values and old URLs redirect to
the replacements rather than resurrecting the old UI. Owner-controlled learning
publisher permissions and their stored records are unchanged.

Transaction Room uses one shared panel, both embedded in Learning and in the
existing standalone TransactionLearningPage routes. It keeps the 11 document
models, 22 original Word/Excel files, 11 previews and stable document copy/image
IDs. The room heading keeps transaction.library.title, and any published banner image keeps image.transaction.hero. Desktop shows a searchable library next to a guide; narrow screens offer a
searchable document picker. Each guide includes purpose, timing, review roles,
a fictional worked example, and separate example/template downloads.

Acquisition Journey follows five buyer stages: finding a business, valuation,
making an offer, diligence, and financing/closing. Existing phase explanations,
questions and their saved public-copy IDs carry forward. Progress uses existing
learning_progress rows and original concept IDs; it never completes tasks or
publishes data in a real deal. Guests retain device progress. Signed-in learners
use the existing account-scoped backend with a local fallback and explicit sync
failure notices. Document links open the matching guide inside Learning.

New links:
- ?module=learning-transaction-room
- ?module=acquisition-journey

Compatibility links:
- ?module=learning-pipeline -> Transaction Room
- ?module=learning-map -> Acquisition Journey
- ?module=transaction-room and ?module=document-guides -> shared standalone room

Checks: acquisition_journey_test.dart, learning_dashboard_test.dart,
dashboard_pipeline_test.dart, transaction_learning_test.dart, full Flutter suite,
and configured site_editor_persistence_test.dart. No database migration is
required; document assets stay bundled with the web build.
