import 'nova_walkthrough.dart';

/// Explicit page identities are passed by headers; release builds never infer them
/// from minified widget class names.
const pebbleMainPageCopy = <String, List<(String, String, String, String?)>>{
  'resources': [
    (
      'search',
      'Find relevant support',
      'Search for a program, provider or funding purpose. Resources connects you with government and community support; it is separate from your professional team.',
      'resources.search',
    ),
    (
      'filters',
      'Narrow the programs',
      'Choose grants, loans, community support or a funding directory, then select your region. Your search, category and region work together; clear a filter if you see no matches.',
      'resources.filters',
    ),
    (
      'providers',
      'Explore a provider',
      'Open an organization card to see its programs. Compare eligibility, eligible costs, deadlines and application details. Affinity connects you to the provider; the provider decides eligibility.',
      'resources.providers',
    ),
    (
      'save',
      'Keep useful programs close',
      'Use a card’s save control to keep an organization, or save an individual program from its profile. Follow the official link to confirm current requirements before applying.',
      'resources.providers',
    ),
  ],
  'comparison': [
    (
      'progress',
      'A comparison round',
      'This quiz puts two example businesses beside each other. Each choice helps clarify what you value in an acquisition; it does not save a purchase decision or commit you to a deal.',
      'comparison.progress',
    ),
    (
      'documents',
      'Read both businesses',
      'Compare earnings, price, industry, location and operating details on both cards. Consider the whole business rather than choosing only the cheapest asking price.',
      'comparison.documents',
    ),
    (
      'choose',
      'Keep your preferred business',
      'Choose the business you prefer. Your favourite stays while a new challenger replaces the other one. Keep comparing until the round is complete.',
      'comparison.documents',
    ),
    (
      'result',
      'Review your preferences',
      'At the end, review the result and the characteristics you repeatedly chose. Use it as a starting point for your real search, then evaluate an actual deal with supporting records.',
      'comparison.results',
    ),
  ],
  'consulting': [
    (
      'intro',
      'Personal consulting',
      'This page explains how a focused conversation can help with buying, preparing a sale or planning succession. Read the introduction to decide whether that support fits your situation.',
      'consulting.hero',
    ),
    (
      'approach',
      'Understand the approach',
      'The approach section explains how your goals and circumstances shape the conversation. Bring the questions and decisions you are working through, even if your plans are still early.',
      'consulting.perspective',
    ),
    (
      'focus',
      'Choose what to discuss',
      'Review the focus areas and identify the topics where you need help. You can use the consultation to clarify readiness, deal evaluation, transaction planning or ownership transition.',
      'consulting.focus',
    ),
    (
      'booking',
      'Book a conversation',
      'Use the consultation booking button to open the calendar, choose an available time and provide your booking details. Review the slot before confirming; the calendar remains part of this experience.',
      'consulting.booking',
    ),
  ],
  'profile': [
    (
      'identity',
      'Your account profile',
      'Your profile brings together your account details and saved progress. The name and photo identify you; professional experience and public member reviews are managed on your professional profile.',
      'profile.identity',
    ),
    (
      'progress',
      'Your acquisition path',
      'Review your Blueprint and readiness progress to see what you have already completed. Saved drafts belong to your account and can be continued when your plans change.',
      'profile.path',
    ),
    (
      'deals',
      'Return to your deals',
      'The deal section helps you find your saved work. Open the relevant deal to manage its own documents, financials and transaction plan; changing your account profile does not change a deal’s access settings.',
      'profile.deals',
    ),
    (
      'edit',
      'Update your details',
      'Use the profile form to update your account information and save it. Keep your contact details accurate. Pebble training status is also available here if you want to request a guide again.',
      'profile.editor',
    ),
  ],
  'auth': [
    (
      'signin',
      'Sign in to your account',
      'Enter your email and password to continue with your saved deals and profile. Signing in restores the work attached to that account.',
      'auth.form',
    ),
    (
      'create',
      'Create an account',
      'Choose the account-creation option if you are new to Affinity. Use an email you can access and follow the verification instructions shown after registration.',
      'auth.form',
    ),
    (
      'recover',
      'Recover access',
      'If you cannot remember your password, use password recovery with the email for your account. Follow the recovery message and then sign in again.',
      'auth.form',
    ),
  ],
  'transaction-rooms': [
    (
      'overview',
      'Your transaction rooms',
      'A transaction room is the private workspace for one deal. It keeps the financials, documents, checklist, team and sharing permissions together.',
      'transaction.title',
    ),
    (
      'open',
      'Open the right deal',
      'Select a saved deal card to enter its actual room. The title and stage help distinguish your opportunities; opening a room does not create a duplicate deal.',
      'transaction.first',
    ),
    (
      'start',
      'When you do not have a room yet',
      'Sign in to see the rooms available to your account. If your list is empty, start a private deal from the buyer dashboard and return here to work on it.',
      'transaction.title',
    ),
  ],
  'notifications': [
    (
      'updates',
      'Your private updates',
      'This page shows activity intended for your account, such as deal changes, professional introductions and replies. It is separate from the conversation inbox.',
      null,
    ),
    (
      'open',
      'Follow an update',
      'Open an update to continue in the relevant part of the app. Read and unread styling helps you see which updates you have already checked.',
      null,
    ),
    (
      'messages',
      'Read conversations',
      'Open Messaging from your dashboard to read and reply to conversations. Creator-only example threads are marked Example and allow you to preview the inbox without contacting anyone.',
      null,
    ),
  ],
  'resource-provider': [
    (
      'organization',
      'About this provider',
      'Review the organization and its service area. Saving the provider keeps it with your resources; it does not add a professional to your deal team.',
      null,
    ),
    (
      'programs',
      'Compare the programs',
      'Search the programs offered by this provider. Read eligibility, supported costs, deadlines and application details before choosing which programs to save.',
      null,
    ),
    (
      'official',
      'Confirm with the provider',
      'Follow the official program link for current requirements and application instructions. Affinity helps you find the connection; the organization manages the program.',
      null,
    ),
  ],
};

List<NovaStep>? pebbleMainPageSteps(String page) {
  final lookup = page == 'buyer/resources' || page == 'seller/resources'
      ? 'resources'
      : page;
  final copy = pebbleMainPageCopy[lookup];
  if (copy == null) return null;
  return [
    for (final (id, title, body, target) in copy)
      NovaStep(
        'pebble-$lookup-$id',
        title,
        body,
        page,
        id == copy.first.$1 ? NovaMood.curious : NovaMood.planning,
        target: target,
      ),
  ];
}
