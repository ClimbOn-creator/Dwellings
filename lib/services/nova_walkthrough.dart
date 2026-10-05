enum NovaMood { welcome, studying, planning, curious, reassuring, celebrating }

class NovaStep {
  const NovaStep(
    this.id,
    this.title,
    this.body,
    this.destination,
    this.mood, {
    this.target,
  });
  final String id, title, body, destination;
  final NovaMood mood;
  final String? target;
}

List<NovaStep> novaWalkthrough(String role) => [
  NovaStep(
    'welcome',
    'Hi, I’m Nova.',
    'I’ll show you where everything lives, one screen at a time. Use Next and Back to explore. This tour will not create listings, change deals or contact anyone.',
    '$role/home',
    NovaMood.welcome,
  ),
  ...switch (role) {
    'seller' => const [
      NovaStep(
        'seller-home',
        'Your next chapter starts here',
        'Home brings your succession or sale progress together. The pipeline follows preparation, finding a successor, agreeing terms and handover.',
        'seller/home',
        NovaMood.planning,
        target: 'seller.workspace',
      ),
      NovaStep(
        'seller-value',
        'Explore your asking price',
        'Deal screen separates business value, assets and commercial property. Start with your own figures and use the results as a starting point for adviser review.',
        'seller/value',
        NovaMood.studying,
      ),
      NovaStep(
        'seller-plan',
        'A plan for your transfer path',
        'Choose an outside sale, family succession, management buyout or partial sale. Your transaction plan adapts to that path; keep tasks and your target date current.',
        'seller/plan',
        NovaMood.planning,
      ),
      NovaStep(
        'seller-team',
        'Bring the right people together',
        'My team connects you with professionals. Add the expertise you need, then agree responsibilities and access inside the deal room.',
        'seller/team',
        NovaMood.reassuring,
      ),
      NovaStep(
        'seller-resources',
        'Explore support programs',
        'Resources contains government programs and community support. Check location, eligible uses and application timing with the program administrator.',
        'seller/resources',
        NovaMood.curious,
      ),
    ],
    'member' => const [
      NovaStep(
        'member-home',
        'Your opportunity board',
        'Home organizes available, recommended and saved opportunities. The cards help you keep track of where your expertise could help.',
        'member/home',
        NovaMood.planning,
        target: 'member.workspace',
      ),
      NovaStep(
        'member-profile',
        'Introduce your experience',
        'Your profile explains your role, service area and personal experience. A clear write-up and genuine reviews help buyers and sellers understand your work. Sign in to edit your own profile.',
        'member/profile',
        NovaMood.reassuring,
      ),
      NovaStep(
        'member-opportunities',
        'Explore an opportunity',
        'Review the approved anonymous brief and support needed before introducing yourself. Private buyer information is not part of this feed.',
        'member/opportunities',
        NovaMood.curious,
      ),
      NovaStep(
        'member-responses',
        'Follow your conversations',
        'Deal responses keeps introductions and replies together. Agree next steps with the deal owner and join a team when invited.',
        'member/dealResponses',
        NovaMood.planning,
      ),
      NovaStep(
        'member-resources',
        'Find support for clients',
        'Use the government programs directory to explore support relevant to a client’s location and planned use of funds.',
        'resources',
        NovaMood.curious,
      ),
    ],
    _ => const [
      NovaStep(
        'buyer-home',
        'Keep an eye on your pipeline',
        'Your cards show active deals, deadlines and items needing attention. Use Search businesses to explore, or Enter a private deal to bring your own opportunity into the app.',
        'buyer/home',
        NovaMood.planning,
        target: 'buyer.workspace',
      ),
      NovaStep(
        'buyer-screen',
        'Screen the opportunity',
        'Deal screen has separate calculators for a business, assets and commercial real estate. Enter your own numbers; the little info buttons explain each input.',
        'buyer/dealScreen',
        NovaMood.studying,
      ),
      NovaStep(
        'buyer-plan',
        'Know what comes next',
        'Select a deal in Transaction plan to see its stages, tasks, owners and deadlines. A blocked task is a signal to resolve the missing information before proceeding.',
        'buyer/transactionPlan',
        NovaMood.planning,
      ),
      NovaStep(
        'buyer-team',
        'Build your adviser team',
        'My team connects you with professionals who can help with accounting, financing, legal work and the handover. Add people here and manage access within each deal.',
        'buyer/team',
        NovaMood.reassuring,
      ),
      NovaStep(
        'buyer-resources',
        'Find grants and community support',
        'Resources is the directory of government programs. Explore the relevant program, then verify eligibility and timing with its administrator.',
        'buyer/resources',
        NovaMood.curious,
      ),
    ],
  },
  const NovaStep(
    'room',
    'One room for each deal',
    'This is a fictional training deal, not a saved acquisition. In your own room, the navigation keeps the financial model, tasks, team, documents and privacy settings together.',
    'room/overview',
    NovaMood.welcome,
    target: 'room.navigation',
  ),
  const NovaStep(
    'financials',
    'Keep the source figures together',
    'Financial model records the deal’s purchase price, annual revenue, EBITDA and available capital. Update your real room when evidence changes; check assumptions with your advisers.',
    'room/financials',
    NovaMood.studying,
    target: 'room.workspace',
  ),
  const NovaStep(
    'room-plan',
    'Move the deal forward',
    'The room’s transaction plan turns the deal into concrete tasks. Track completion, due dates, responsibilities and blockers instead of relying on memory.',
    'room/plan',
    NovaMood.planning,
    target: 'room.workspace',
  ),
  const NovaStep(
    'documents',
    'Keep documents with the deal',
    'The private document vault is where authorized participants can upload and review deal files. This example has no real files; the tour never uploads or downloads anything.',
    'room/documents',
    NovaMood.studying,
    target: 'room.workspace',
  ),
  const NovaStep(
    'privacy',
    'Decide what gets shared',
    'Privacy settings control what approved professionals can see. Anonymous opportunities and private deal records have different audiences. Review permissions before sharing information.',
    'room/privacy',
    NovaMood.reassuring,
    target: 'room.workspace',
  ),
  const NovaStep(
    'blueprint',
    'Start with your goals',
    'Blueprint defines the kind of business you want, your role and your limits. Use the existing steps to save your goals to your account when you are ready.',
    'blueprint',
    NovaMood.curious,
  ),
  const NovaStep(
    'readiness',
    'Get ready to act',
    'Buyer readiness helps separate buying capital from fees, working capital and reserves. It frames your preparation; it is not a financing approval.',
    'readiness',
    NovaMood.planning,
  ),
  const NovaStep(
    'learning',
    'Learn what the documents do',
    'Document guides explains each transaction document, when to use it and who should review it. Open a worked example or download an editable template from the page.',
    'learning',
    NovaMood.studying,
  ),
  const NovaStep(
    'consulting',
    'Get personal support',
    'Personal consulting explains the support available and keeps the consultation calendar on the page. Use the booking options when you are ready to arrange help.',
    'consulting',
    NovaMood.reassuring,
  ),
  NovaStep(
    'finish',
    'You’re ready to explore.',
    'You’ve finished the app walkthrough. Nova will stay tucked away after this. You can replay any guide from Nova walkthrough in the menu or from your profile.',
    '$role/home',
    NovaMood.celebrating,
  ),
];
