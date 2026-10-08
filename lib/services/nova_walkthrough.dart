import 'nova_calculator_fields.dart';

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
    'Hi, I’m Pebble.',
    'I’ll show you around this page. Use Next and Back, or close the guide and request me again from the header.',
    '$role/home',
    NovaMood.welcome,
  ),
  ...switch (role) {
    'seller' => [
      NovaStep(
        'seller-home',
        'Your next chapter starts here',
        'Home brings your succession or sale progress together. The pipeline follows preparation, finding a successor, agreeing terms and handover.',
        'seller/home',
        NovaMood.planning,
        target: 'seller.workspace',
      ),
      ...novaDashboardSteps('seller'),
      NovaStep(
        'seller-value',
        'Explore your asking price',
        'Deal screen separates business value, assets and commercial property. Start with your own figures and use the results as a starting point for adviser review.',
        'seller/value',
        NovaMood.studying,
        target: 'seller.calc.panel.1',
      ),
      ...novaCalculatorSteps('seller'),
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
    _ => [
      NovaStep(
        'buyer-home',
        'Keep an eye on your pipeline',
        'Your cards show active deals, deadlines and items needing attention. Use Search businesses to explore, or Enter a private deal to bring your own opportunity into the app.',
        'buyer/home',
        NovaMood.planning,
        target: 'buyer.workspace',
      ),
      ...novaDashboardSteps('buyer'),
      NovaStep(
        'buyer-screen',
        'Screen the opportunity',
        'Deal screen has separate calculators for a business, assets and commercial real estate. Enter your own numbers; the little info buttons explain each input.',
        'buyer/dealScreen/business',
        NovaMood.studying,
        target: 'buyer.calc.tabs',
      ),
      ...novaCalculatorSteps('buyer'),
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
    'You’ve finished the app walkthrough. Pebble will stay tucked away after this. You can replay any guide from Pebble walkthrough in the menu or from your profile.',
    '$role/home',
    NovaMood.celebrating,
  ),
];

/// Each input has its own step and target; no financial figures are filled in.
List<NovaStep> novaCalculatorSteps(String role) {
  final seller = role == 'seller';
  final fields = seller
      ? novaSellerCalculatorFields
      : novaBuyerCalculatorFields;
  final groups = seller
      ? <(String, List<NovaCalculatorField>, String, String)>[
          (
            'business',
            fields.take(6).toList(),
            'Business value range',
            'Maintainable EBITDA adds verified add-backs and owner pay to reported EBITDA, then subtracts replacement leader pay. The low and high multiples produce the enterprise-value range. Cash, debt and working-capital adjustments are separate.',
          ),
          (
            'assets',
            fields.skip(6).take(4).toList(),
            'Net asset reference',
            'Included equipment, inventory and collectible receivables minus assumed liabilities gives the net asset reference. This is a separate comparison; adding it to earnings value can double-count assets.',
          ),
          (
            'closing',
            fields.skip(10).toList(),
            'Cash at closing',
            'Subtract vendor financing, selling fees and debt paid at closing from the expected price. The result is before tax; holdbacks, earn-outs and working-capital adjustments need separate review.',
          ),
        ]
      : <(String, List<NovaCalculatorField>, String, String)>[
          (
            'business',
            fields.where((f) => f.mode == 'business').toList(),
            'Read the business results',
            'The earnings bridge explains maintainable EBITDA. Multiples give an indicative price range, and the price gap compares it with the ask. Debt service, coverage and cash after debt depend on the financing assumptions and maintenance investment.',
          ),
          (
            'assets',
            fields.where((f) => f.mode == 'assets').toList(),
            'Read the asset results',
            'The asset bridge adds included assets and cash, then subtracts liabilities and deferred maintenance. Compare adjusted net assets with the ask. Buyer cost includes transaction costs; the liquidation floor uses the recovery rate for noncash assets.',
          ),
          (
            'realEstate',
            fields.where((f) => f.mode == 'realEstate').toList(),
            'Read the property results',
            'Potential income minus vacancy, operating costs and replacement reserves gives stabilized NOI. NOI divided by the market cap rate gives income value. Debt coverage and cash after debt use your financing terms; hold and exit assumptions drive the projected sale value and stress view.',
          ),
        ];
  return [
    for (var group = 0; group < groups.length; group++) ...[
      for (final field in groups[group].$2)
        NovaStep(
          '$role-input-${field.key}',
          field.label,
          '${field.help} Example → ${field.example}.',
          seller ? 'seller/value' : 'buyer/dealScreen/${field.mode}',
          NovaMood.studying,
          target: '$role.calc.${field.key}',
        ),
      NovaStep(
        '$role-result-${groups[group].$1}',
        groups[group].$3,
        '${groups[group].$4} Results appear when the required fields are complete.',
        seller ? 'seller/value' : 'buyer/dealScreen/${groups[group].$1}',
        NovaMood.planning,
        target: seller
            ? 'seller.calc.result.${group + 1}'
            : 'buyer.calc.${groups[group].$1}.results',
      ),
    ],
  ];
}

List<NovaStep> novaDashboardSteps(String role) {
  final seller = role == 'seller';
  final metrics = seller
      ? const [
          (
            'Active transfers',
            'This counts the transfer you have set up. Start a transaction plan to identify your business and transfer path.',
          ),
          (
            'Plan complete',
            'Completed checklist tasks drive this percentage. Use your transaction plan to work through the remaining steps and keep progress current.',
          ),
          (
            'Due soon',
            'These unfinished steps have suggested dates in the next seven days. Review the dates in your plan and make time for the next actions.',
          ),
          (
            'Needs attention',
            'These unfinished steps are past their suggested dates. Review what is blocking them with the responsible adviser.',
          ),
        ]
      : const [
          (
            'Active deals',
            'This counts deals currently in your pipeline. Completed, archived and cancelled deals are kept out of the active count.',
          ),
          (
            'Under review',
            'These deals are being screened or financed. Open a deal to check assumptions and the evidence still needed before moving forward.',
          ),
          (
            'Due soon',
            'These deal deadlines fall in the next seven days. Upcoming meetings and tasks also appear in your follow-up area when you have active deals.',
          ),
          (
            'Needs attention',
            'This flags blockers and overdue work. Open the relevant deal or transaction plan to see the task, owner and next action.',
          ),
        ];
  final stages = seller
      ? const [
          (
            'Preparation',
            'Define your transfer path and prepare the business, records and adviser team. Your transfer appears here while preparation is the next stage.',
          ),
          (
            'Successor search',
            'Find and assess a buyer or successor. Keep confidential information protected while checking fit and capacity.',
          ),
          (
            'Terms / diligence',
            'Agree the commercial terms and coordinate the buyer’s review of the business. Use the transaction plan to track the evidence and decisions.',
          ),
          (
            'Closing / handover',
            'Complete the closing work and transfer responsibilities. Your transaction plan includes the ownership transition after the agreement.',
          ),
        ]
      : const [
          (
            'Sourcing',
            'Early opportunities start here. Open a deal card to review its details, then use the deal screen to evaluate whether to proceed.',
          ),
          (
            'Under review',
            'Screening and finance work sit here. Compare the evidence, price and funding capacity before agreeing the next stage.',
          ),
          (
            'LOI / diligence',
            'These deals are in the letter-of-intent or diligence stages. Track requests, deadlines, owners and blockers in the transaction plan.',
          ),
          (
            'Closing',
            'These deals are moving through closing or transition. Confirm remaining legal, financing and handover actions with your team.',
          ),
        ];
  return [
    for (var i = 0; i < metrics.length; i++)
      NovaStep(
        '$role-home-metric-$i',
        metrics[i].$1,
        metrics[i].$2,
        '$role/home',
        NovaMood.planning,
        target: '$role.home.metric.$i',
      ),
    NovaStep(
      '$role-home-search',
      seller ? 'Find your transfer' : 'Find a deal in your pipeline',
      seller
          ? 'Search narrows the displayed transfers by business name. This searches your own pipeline.'
          : 'Search narrows your existing pipeline by name or location. Use Search businesses to look for a new opportunity.',
      '$role/home',
      NovaMood.curious,
      target: '$role.home.search',
    ),
    NovaStep(
      '$role-home-start',
      seller
          ? 'Set up your transfer plan'
          : 'Bring an opportunity into the app',
      seller
          ? 'Set up plan opens your seller transaction plan. Identify your business, choose the succession or sale path and set your timing. Edit plan lets you keep that information current.'
          : 'Search businesses opens available opportunities. Enter a private deal adds an opportunity you found yourself. Compare what fits me helps you compare options before committing.',
      '$role/home',
      NovaMood.welcome,
      target: '$role.home.start',
    ),
    for (var i = 0; i < stages.length; i++)
      NovaStep(
        '$role-home-stage-$i',
        stages[i].$1,
        stages[i].$2,
        '$role/home',
        NovaMood.planning,
        target: '$role.home.stage.$i',
      ),
    NovaStep(
      '$role-home-team',
      'Your personal team',
      'Your saved advisers appear here. Manage opens My team. Professionals on your personal team do not automatically get access to every private deal; review each deal’s permissions.',
      '$role/home',
      NovaMood.reassuring,
      target: '$role.home.team',
    ),
  ];
}
