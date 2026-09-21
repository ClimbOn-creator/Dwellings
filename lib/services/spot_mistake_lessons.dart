class MistakeLesson {
  const MistakeLesson(
    this.topic,
    this.title,
    this.scenario,
    this.claims,
    this.answer,
    this.explanation,
    this.action,
  );
  final String topic, title, scenario, explanation, action;
  final List<String> claims;
  final int answer;
}

// Fictional exercises: the numbers and businesses are teaching examples.
const mistakeLessons = <MistakeLesson>[
  MistakeLesson(
    'Cash flow',
    'The disappearing profit',
    'A café reports 180,000 dollars in annual operating cash flow before debt payments. The proposed acquisition loan requires 120,000 dollars a year.',
    [
      'Debt payments leave 60,000 dollars before other cash needs.',
      'The buyer can take home all 180,000 dollars each year.',
      'The buyer should budget for taxes, reinvestment and reserves.',
    ],
    1,
    'The loan consumes 120,000 dollars of cash. The remaining 60,000 dollars is still before taxes, capital spending and other cash needs.',
    'Build a cash-flow bridge from operating results to debt payments and cash available to the owner.',
  ),
  MistakeLesson(
    'Diligence',
    'One customer, most of the sales',
    'A distributor earns 65% of its revenue from one customer. Their contract can end on 30 days’ notice.',
    [
      'Stress-test losing that customer.',
      'Ask about the customer relationship and contract renewal.',
      'Last year’s strong sales make the revenue secure.',
    ],
    2,
    'Historical sales do not guarantee future revenue. Customer concentration and a short termination period can materially change the risk.',
    'Review concentration, retention and contracts, then model a downside case.',
  ),
  MistakeLesson(
    'Valuation',
    'The owner works for free',
    'A seller adds back their entire 100,000-dollar salary to show adjusted earnings. The buyer will hire a manager to do that work.',
    [
      'All of the salary is extra profit available to the buyer.',
      'A replacement manager is an ongoing operating expense.',
      'The buyer needs evidence for each earnings adjustment.',
    ],
    0,
    'Work that continues needs to be paid for. Adding back the salary without allowing for a replacement manager overstates the buyer’s earnings.',
    'Normalize owner compensation using a realistic replacement cost.',
  ),
  MistakeLesson(
    'Financing',
    'A grant in the closing budget',
    'A buyer has applied for a grant but has no approval or funding agreement. Closing is next month.',
    [
      'Confirm what costs the program can fund.',
      'Count the application as guaranteed cash for closing.',
      'Build a financing plan that can close without unapproved funding.',
    ],
    1,
    'An application is not an award or available cash. Eligibility, permitted costs and payment timing must be confirmed.',
    'Separate confirmed financing from applications and contingent funding.',
  ),
  MistakeLesson(
    'Working capital',
    'The price is not the whole budget',
    'A seasonal business needs inventory and payroll before customers pay. The buyer has budgeted only for the purchase price.',
    [
      'Model the cash gap before customer receipts.',
      'Discuss the working-capital amount included at closing.',
      'The purchase price covers every future cash need.',
    ],
    2,
    'The business can need additional cash after closing. Inventory, payroll, receivables and seasonal timing affect the amount required.',
    'Prepare a closing sources-and-uses schedule and a short-term cash forecast.',
  ),
  MistakeLesson(
    'Contracts',
    'The handshake lease',
    'The seller says the premises lease transfers automatically. The buyer has not read it or spoken with the landlord.',
    [
      'Accept the seller’s assurance and skip the lease review.',
      'Have an adviser review assignment and consent requirements.',
      'Confirm occupancy arrangements before committing to close.',
    ],
    0,
    'The seller’s assurance does not establish the buyer’s rights under the lease. The actual terms and required consents need review.',
    'Make lease review and required consents part of the transaction checklist.',
  ),
  MistakeLesson(
    'Transition',
    'All the knowledge leaves Friday',
    'The owner alone knows key suppliers, pricing and daily processes. They plan to leave immediately after closing.',
    [
      'Document the critical processes.',
      'The buyer can safely assume the knowledge will transfer itself.',
      'Agree on handover support and introductions.',
    ],
    1,
    'Ownership transfer does not automatically transfer the owner’s knowledge or relationships.',
    'Agree a transition plan with responsibilities, introductions and a practical handover schedule.',
  ),
  MistakeLesson(
    'Evidence',
    'The spreadsheet is the proof',
    'The seller provides an attractive forecast but no supporting historical records.',
    [
      'Ask for records that support sales and expenses.',
      'Test forecast assumptions against evidence.',
      'Treat the forecast as verified historical performance.',
    ],
    2,
    'A forecast is an estimate. It does not verify past results or prove future performance.',
    'Reconcile historical reporting with source records and independently test the forecast assumptions.',
  ),
];
