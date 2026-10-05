import 'transaction_learning.dart';

class NovaLesson {
  const NovaLesson(
    this.id,
    this.title,
    this.explanation,
    this.example,
    this.check,
  );
  final String id, title, explanation, example, check;
}

const novaCoreLessons = [
  NovaLesson(
    'blueprint',
    'Start with your Blueprint',
    'Describe the business you want, why you want it, the role you can take on, and your hard limits. Separate a preference from a condition you cannot compromise. A clear Blueprint helps you compare opportunities consistently.',
    'An experienced operator wants a local service business, can invest 250,000, and needs a manager to stay. “Local” is a preference; adequate cash reserves and a credible management plan are conditions.',
    'Which one condition would make you walk away from a deal?',
  ),
  NovaLesson(
    'readiness',
    'Understand your buying capacity',
    'Separate money available for the purchase from fees, working capital and the reserve you need after closing. A funding estimate does not mean a lender has approved the deal. Check your own role, time and operating experience as well as capital.',
    'With 300,000 available, a 60,000 reserve and 25,000 of fees leave 215,000 before funding opening working capital.',
    'What costs would you keep outside your purchase deposit?',
  ),
  NovaLesson(
    'valuation',
    'Compare price with sustainable earnings',
    'EBITDA is earnings before interest, tax, depreciation and amortization. Verify every proposed add-back and subtract replacement management costs where necessary. SDE and EBITDA serve different buyer profiles. A multiple is a comparison tool; cash flow, assets, risk and evidence still matter.',
    'Reported EBITDA of 240,000 + 30,000 of verified non-recurring costs − 50,000 of replacement management = 220,000 adjusted EBITDA. At a 1,100,000 price, the implied multiple is 5×.',
    'Why might a seller’s claimed add-back fail your review?',
  ),
  NovaLesson(
    'concentration',
    'Assess customer concentration',
    'Measure the largest customer’s share of revenue and profit, then review contract duration, renewal, termination rights and whether the relationship depends on the seller. A large share alone cannot establish whether a deal is safe. Stress-test losing or shrinking that account.',
    'A customer providing 35% of revenue may produce more than 35% of profit. A lost contract could reduce earnings faster than sales; fixed costs might not fall with it.',
    'What evidence would help you assess a large customer relationship?',
  ),
  NovaLesson(
    'balance-sheet',
    'Read a balance sheet',
    'The balance sheet shows assets, liabilities and equity at a point in time. Check receivables for collectability, inventory for obsolescence, debt for liens and payables for overdue balances. Identify what transfers in an asset sale or share sale and what is excluded.',
    'Receivables 120,000 + inventory 80,000 − operating payables 70,000 = 130,000 of simplified operating working capital. This example excludes cash, debt and other negotiated items.',
    'Why can a profitable business still need more cash at closing?',
  ),
  NovaLesson(
    'financing',
    'Test debt support',
    'Debt-service coverage is cash available for debt service divided by annual debt payments. Account for taxes, recurring capital spending, working-capital needs and management cost. Use lender-specific assumptions and a downside case. Maximum support is a scenario, not an approval.',
    'If verified cash available for debt service is 180,000 and the assumed coverage requirement is 1.5×, annual debt service must stay at or below 120,000. Interest rate, amortization and loan structure determine principal.',
    'What changes if sustainable cash flow falls 20%?',
  ),
  NovaLesson(
    'seller',
    'Choose your transfer path',
    'A sale to an outside buyer, family succession and a management buyout can have different timelines, funding needs and handover duties. Define your desired exit date, future role, minimum proceeds and priorities for staff. Bring tax and legal advisers in before committing to a structure.',
    'An owner who wants to reduce hours over two years may need a staged leadership handover and funding plan rather than an immediate full exit.',
    'What would you want your role to look like one year after transfer?',
  ),
  NovaLesson(
    'member',
    'Build a useful professional profile',
    'Explain your role, relevant experience, service area and the specific decisions you help with. Use the personal experience section for a concrete account of your work. Request honest reviews of real work. Use deal-team permissions before accessing private information.',
    'An accountant can describe evaluating earnings adjustments and working capital for owner-operated businesses, including where legal or lending advice is needed.',
    'Which decision can a buyer or seller confidently ask you to help with?',
  ),
  NovaLesson(
    'resources',
    'Find government programs',
    'Use Resources to explore government grants, financing and community programs. Eligibility depends on location, sector, ownership and the use of funds. Verify current rules with the program administrator before including support in a funding plan.',
    'A regional program may support equipment but exclude the purchase price. Separate eligible costs from the acquisition budget and confirm timing before spending.',
    'What should you verify before treating a program as funding?',
  ),
];

List<NovaLesson> get novaLessons => [
  ...novaCoreLessons,
  for (final lesson in transactionLessons)
    NovaLesson(
      'document-${lesson.id}',
      lesson.title,
      '${lesson.purpose}\n\nWhen to use it: ${lesson.whenToUse}\n\nWhat to complete: ${lesson.whatToComplete}',
      lesson.example,
      'Who should review this? ${lesson.reviewedBy}',
    ),
];

List<(String, String, String)> novaTour(String role) => switch (role) {
  'seller' => [
    (
      'Home',
      'Follow your transfer progress and preparation from your existing dashboard.',
      'overview',
    ),
    (
      'Deal screen',
      'Estimate the business, assets or property separately. Verify inputs before choosing an asking price.',
      'value',
    ),
    (
      'Transaction plan',
      'Choose your succession or sale path, assign preparation tasks and coordinate your handover.',
      'plan',
    ),
    (
      'Resources',
      'Find government programs and community support; confirm eligibility with the administrator.',
      'resources',
    ),
    (
      'My team',
      'Bring in the professionals who can help with valuation, tax, legal terms and transition.',
      'team',
    ),
  ],
  'member' => [
    (
      'Home',
      'Your opportunity board brings together new, recommended and saved opportunities.',
      'home',
    ),
    (
      'Profile',
      'Introduce your expertise, service area and personal experience so buyers and sellers know how you can help.',
      'profile',
    ),
    (
      'Opportunities',
      'Review the available brief and explain the value you can bring. Private information stays behind permissions.',
      'opportunities',
    ),
    (
      'Deal responses',
      'Follow your introductions and agreed next steps; join a team when the deal owner invites you.',
      'dealResponses',
    ),
  ],
  _ => [
    (
      'Home',
      'Your cards and pipeline show active deals, upcoming deadlines and attention needed.',
      'home',
    ),
    (
      'Deal screen',
      'Estimate a business, assets or commercial property, then investigate the assumptions.',
      'dealScreen',
    ),
    (
      'Transaction plan',
      'Select your deal, follow the stages and track owners, deadlines and blockers.',
      'transactionPlan',
    ),
    (
      'Resources',
      'Explore government programs and community support alongside your funding plan.',
      'resources',
    ),
    (
      'My team',
      'Build your adviser team, then give people appropriate access within each deal.',
      'team',
    ),
  ],
};
