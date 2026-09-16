class TransactionLesson {
  const TransactionLesson(
    this.id,
    this.stage,
    this.title,
    this.purpose,
    this.fields,
    this.example,
  );
  final String id, stage, title, purpose, fields, example;

  static const _wordLessonIds = {
    'deal-brief',
    'nda-brief',
    'loi-brief',
    'agreement-review',
    'closing',
  };

  String get fileExtension => _wordLessonIds.contains(id) ? 'docx' : 'xlsx';
  String get fileTypeLabel => fileExtension == 'docx' ? 'Word' : 'Excel';
  String get previewAsset => 'assets/transaction_previews/$id.png';
  String assetPath({required bool filled}) =>
      'assets/transaction_templates/$id-${filled ? "example" : "template"}.$fileExtension';
  String fileName({required bool filled}) =>
      '$id-${filled ? "example" : "template"}.$fileExtension';

  String get whenToUse => switch (id) {
    'deal-brief' =>
      'Use it as soon as a listing, broker package or direct opportunity looks interesting—before an NDA, offer or paid diligence work. Update it when the seller clarifies the price, structure or inclusions.',
    'nda-brief' =>
      'Use it before financial statements, customer information, employee records or other confidential material changes hands. Send the completed brief to local counsel so the NDA reflects the actual parties and access plan.',
    'request-list' =>
      'Start it immediately after confidentiality is in place and keep it active throughout diligence. Every requested file, missing answer and follow-up should have one row, one owner and a current status.',
    'earnings' =>
      'Use it after receiving reliable income statements and general-ledger support, before relying on seller-disclosed SDE or EBITDA for valuation, financing or an offer.',
    'working-capital' =>
      'Use it while defining what the price includes and again when negotiating the closing adjustment. It becomes essential before finalizing sources and uses or estimating the cash needed on Day 1.',
    'loi-brief' =>
      'Use it after the initial facts support a serious proposal but before anyone drafts or sends an LOI. Resolve the commercial instructions with your advisers first.',
    'risk-log' =>
      'Use it from the first diligence review until conditions are waived or the buyer walks away. Add a finding when evidence changes the economics, timing, legal exposure or operating plan.',
    'funding' =>
      'Use it before approaching lenders, refresh it when price or structure changes, and reconcile it to the final agreement and closing statement. A balanced model is still not loan approval.',
    'agreement-review' =>
      'Use it when counsel circulates the first definitive agreement and maintain it through signing. It helps the buyer confirm that negotiated economics, conditions, schedules and consents appear in the correct draft.',
    'closing' =>
      'Use it once a target closing date exists. Review it repeatedly during the final week and use it on closing day to coordinate evidence—never to declare legal completion yourself.',
    'transition' =>
      'Begin it before closing so Day 1 is not improvised. Use it with the seller and operating team through the first 100 days, then compare actual results with the acquisition assumptions.',
    _ => '',
  };

  String get whatToComplete => switch (id) {
    'deal-brief' =>
      'Source, business model, proposed structure, asking price, included assets, buyer role, capital limits, return criteria, hard limits, known gaps and the initial proceed/pause/decline decision.',
    'nda-brief' =>
      'Exact legal names, permitted purpose, authorised advisers, expected information, access controls, contact restrictions, return or deletion needs, duration questions and governing-law instructions.',
    'request-list' =>
      'Request ID, category, document and period, person responsible, request and due dates, received date, review owner, evidence location, follow-up, status and decision impact.',
    'earnings' =>
      'Reported revenue and earnings, each proposed adjustment, its signed EBITDA effect, recurring versus non-recurring treatment, supporting evidence, replacement-management cost and reviewer conclusion.',
    'working-capital' =>
      'Receivables, inventory, prepaids, payables, accruals, normalized target, debt and lien payouts, included assets, condition, estimated value, title evidence and opening cash reserve.',
    'loi-brief' =>
      'Buyer and seller entities, asset/share structure, price, payment mix, working-capital treatment, diligence and financing conditions, consents, dates, exclusivity and intended binding-term questions.',
    'risk-log' =>
      'One evidence-based finding per row with category, source, likelihood, impact, mitigation, owner, deadline, decision, status and the evidence required to close it.',
    'funding' =>
      'All uses of funds, all proposed sources, unfunded gap, debt amount, rate and term, annual debt service, adjusted earnings, coverage, downside assumptions and lender-package evidence.',
    'agreement-review' =>
      'Draft name and date, price and adjustments, included/excluded assets, representations, indemnities, conditions, post-closing obligations, lease/licence/contract consents and tax-allocation review.',
    'closing' =>
      'Execution versions, authority, conditions, consents, closing statement, adjustments, payouts, releases, verified payment instructions, system and physical handover, communications and completion evidence.',
    'transition' =>
      'Phase, workstream, action, owner, due date, dependency, measurable result, status, completion evidence and notes across pre-close, Day 1, days 2–30 and days 31–100.',
    _ => '',
  };

  String get reviewedBy => switch (id) {
    'deal-brief' =>
      'Buyer first; accountant, lender or lawyer where a criterion depends on their advice.',
    'nda-brief' =>
      'A lawyer qualified in the transaction’s jurisdiction before anyone signs or sensitive records are released.',
    'request-list' =>
      'Buyer diligence lead, accountant and lawyer; specialists should own requests in their field.',
    'earnings' =>
      'Transaction accountant or qualified financial adviser, with evidence traced to the seller’s records.',
    'working-capital' =>
      'Accountant for normalization and closing mechanics; lawyer for ownership, liens and releases.',
    'loi-brief' =>
      'Buyer, accountant and local transaction lawyer. Counsel should draft or approve the actual LOI.',
    'risk-log' =>
      'Buyer and the adviser responsible for each finding—legal, financial, tax, operational, environmental or technical.',
    'funding' =>
      'Accountant or financial adviser and the prospective lender. Legal counsel reviews security, guarantees and conditions.',
    'agreement-review' =>
      'Buyer’s transaction lawyer, with the accountant reviewing economic, allocation and tax-related schedules.',
    'closing' =>
      'Buyer’s lawyer and lender lead the legal and funds-flow process; the buyer verifies operational handover.',
    'transition' =>
      'Buyer/operator, functional owners and the seller where transition support is part of the agreement.',
    _ => '',
  };

  String get buyerWatchOut => switch (id) {
    'deal-brief' =>
      'Treat listing claims as unverified. The brief is a screening record, not a valuation, offer or reason to relax a hard limit.',
    'nda-brief' =>
      'An NDA can contain binding restrictions. Do not copy boilerplate blindly or assume it permits sharing with a lender, partner or adviser.',
    'request-list' =>
      'Received is not reviewed, and reviewed is not verified. Keep the original source, version and unresolved follow-up visible.',
    'earnings' =>
      'Do not mix SDE, EBITDA and free cash flow. An add-back needs evidence; debt service, tax, working capital and capital spending still matter.',
    'working-capital' =>
      'A cash-free/debt-free headline does not explain the operating cash delivered at closing. Obsolete inventory and uncollectible receivables can overstate value.',
    'loi-brief' =>
      'Some LOI provisions may bind the parties even when the price is described as non-binding. Do not send or sign the preparation brief.',
    'risk-log' =>
      'A proposed mitigation does not close a finding. Record the decision, residual exposure and actual completion evidence.',
    'funding' =>
      'Do not treat a balanced sources-and-uses table as committed financing. Test repayment under lower sales, higher costs and delayed collections.',
    'agreement-review' =>
      'A checklist cannot interpret the agreement. Work from the exact current draft and let counsel explain rights, remedies, survival and liability limits.',
    'closing' =>
      'Independently verify payment instructions through a known contact channel. Only counsel should confirm legal closing or advise a waiver.',
    'transition' =>
      'Do not postpone Day 1 decisions until after closing. Protect payroll, customer service, cash access and system control before pursuing improvements.',
    _ => '',
  };

  String document({required bool filled}) =>
      '# $title\n\n${filled ? "FICTIONAL WORKED EXAMPLE" : "BLANK LEARNING TEMPLATE"}\n\n$purpose\n\nDeal: ${filled ? "Harbour Services (fictional)" : "[Deal name]"}\nJurisdiction: ${filled ? "Canada / BC — illustrative only" : "[Country and local jurisdiction]"}\nCurrency: ${filled ? "CAD" : "[Currency code]"}\nPrepared by / date: [Name / date]\n\n${filled ? example : fields}\n\nReview notes: [Evidence, open questions, owner and due date]\n\nEducational preparation material. Legal and lender documents must be prepared or approved for the specific transaction and jurisdiction; this is not an agreement to sign.\n';
}

const transactionLessons = [
  TransactionLesson(
    'deal-brief',
    '1 · Understand the deal',
    'Deal brief & buyer criteria',
    'Organize the opportunity and compare it with the buyer’s goals before spending on detailed diligence.',
    'Source URL: [ ]\nIndustry / location: [ ]\nAssets or shares / inclusions: [ ]\nAsking price and currency: [ ]\nBuyer role / goals: [ ]\nHard limits: [ ]\nUnknown facts and next questions: [ ]',
    'Source: fictional broker listing\nIndustry: maintenance services\nAsking price: CAD 500,000\nBuyer role: full-time operator\nHard limit: no unresolved licence transfer\nUnknown: recurring contract renewal dates; ask seller for contract schedule.',
  ),
  TransactionLesson(
    'nda-brief',
    '1 · Understand the deal',
    'Confidentiality / NDA preparation brief',
    'Help local counsel identify who needs protection and what information may be disclosed before sensitive records are shared.',
    'Parties and advisers: [ ]\nInformation to disclose: [ ]\nPermitted purpose and recipients: [ ]\nExisting confidentiality restrictions: [ ]\nReturn / deletion needs: [ ]\nQuestions for counsel: [ ]',
    'Buyer wants financial statements and customer concentration data. Ask counsel to address access by the accountant and lender, permitted use, retention obligations and restrictions on contacting customers. No seller records shared until the approved agreement and access rules are in place.',
  ),
  TransactionLesson(
    'request-list',
    '2 · Collect evidence',
    'Document request list & evidence register',
    'Track requested records, their source and review status. Receiving a file does not mean its contents have been verified.',
    '| Request | Period | Owner | Due date | Received | Reviewed | Follow-up |\n|---|---|---|---|---|---|---|\n| Financial statements | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |\n\nAlso consider tax filings, bank reconciliations, sales by customer, debt and asset schedules, leases, contracts, licences, employees, insurance, claims and IP records.',
    '| Request | Period | Owner | Due date | Received | Reviewed | Follow-up |\n|---|---|---|---|---|---|---|\n| Financial statements | Last 3 years | Accountant | Before offer review | Yes | No | Reconcile to filings |\n| Lease and amendments | Current | Lawyer | During diligence | No | No | Confirm assignment process |',
  ),
  TransactionLesson(
    'earnings',
    '2 · Collect evidence',
    'Financial review & earnings bridge',
    'Separate seller-reported earnings from supported adjustments and recurring costs. Keep SDE, EBITDA and cash flow distinct.',
    'Reporting period / currency: [ ]\nReported revenue: [ ]\nReported EBITDA / source: [ ]\nOwner pay and role: [ ]\nProposed adjustment / amount / evidence: [ ]\nReplacement management cost: [ ]\nRecurring capital spending: [ ]\nReviewer conclusion and remaining gaps: [ ]',
    'Reported EBITDA: CAD 120,000\nProposed one-off repair add-back: CAD 10,000\nPotential recurring replacement cost: CAD 25,000\nIllustrative adjusted EBITDA: CAD 105,000 (120,000 + 10,000 - 25,000), subject to evidence. This is not free cash flow: financing, taxes, working capital and capital spending still need review.',
  ),
  TransactionLesson(
    'working-capital',
    '2 · Collect evidence',
    'Working capital, debt & asset schedule',
    'Identify operating funds and assets required after closing and clarify what the purchase price includes.',
    'Cash included/excluded: [ ]\nReceivables and collectability: [ ]\nInventory and valuation basis: [ ]\nPayables / accruals: [ ]\nDebt, liens and payout evidence: [ ]\nEquipment and condition: [ ]\nSeasonality and opening cash reserve: [ ]\nProposed closing adjustment questions: [ ]',
    'Inventory estimate: CAD 40,000, pending count and obsolete-stock review. Seller debt is proposed to be paid out at closing. Buyer asks accountant to test seasonal cash requirements and counsel to confirm releases; neither item is treated as verified.',
  ),
  TransactionLesson(
    'loi-brief',
    '3 · Structure the offer',
    'Letter of intent / offer preparation brief',
    'Record proposed commercial terms for professional review. An LOI may contain binding provisions even when other terms are preliminary.',
    'Buyer/seller legal entities: [ ]\nAssets or shares: [ ]\nPrice / payment structure: [ ]\nWorking-capital treatment: [ ]\nDiligence and financing conditions: [ ]\nTarget timetable: [ ]\nExclusivity / confidentiality questions: [ ]\nBinding terms and local-law review: [ ]',
    'Proposed asset purchase: CAD 500,000; financing and diligence to be explored. Inventory treatment remains open. Buyer asks counsel to draft conditions, identify any binding provisions and advise on exclusivity. This brief is not sent as an offer or signed.',
  ),
  TransactionLesson(
    'risk-log',
    '4 · Test the evidence',
    'Due diligence findings & decision log',
    'Turn financial, operational and legal findings into specific decisions and evidence requests.',
    '| Finding | Evidence | Impact | Owner | Next action | Deadline | Decision |\n|---|---|---|---|---|---|---|\n| [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |\n\nReview customers/suppliers, employees, owner dependence, licences, taxes, litigation, privacy/security, assets, environment and contracts with appropriate specialists.',
    '| Finding | Evidence | Impact | Owner | Next action | Deadline | Decision |\n|---|---|---|---|---|---|---|\n| Largest customer may not renew | Contract schedule | Revenue concentration | Buyer + counsel | Verify renewal/consent terms | Before conditions waived | Open |',
  ),
  TransactionLesson(
    'funding',
    '5 · Prepare funding',
    'Funding plan & lender package checklist',
    'Explain sources and uses of funds, operating reserves and repayment assumptions. A prepared package is not loan approval.',
    'Uses: price / fees / taxes / opening working capital / reserves [ ]\nSources: equity / lender / seller financing [ ]\nUnfunded gap: [ ]\nDebt terms and downside assumptions: [ ]\nBuyer experience and business plan: [ ]\nFinancial statements and projections: [ ]\nSecurity / guarantees / conditions to ask lender about: [ ]',
    'Illustrative uses: CAD 500,000 price + 30,000 fees + 70,000 working capital/reserve = 600,000. Proposed sources: 200,000 equity + 400,000 borrowing. Borrowing is unapproved. Test repayment capacity and a sales decline before treating the funding gap as solved.',
  ),
  TransactionLesson(
    'agreement-review',
    '6 · Prepare legal documents',
    'Purchase agreement & consent review checklist',
    'Track the issues for local counsel in the definitive agreement and related transfer documents; this checklist is not a purchase agreement.',
    'Asset/share agreement draft and version: [ ]\nInclusions / exclusions / allocation: [ ]\nRepresentations / indemnities / limitations: [ ]\nConditions and deadlines: [ ]\nLease / customer / supplier consents: [ ]\nEmployment / transition arrangements: [ ]\nRegulatory approvals and tax review: [ ]\nCounsel approval and unresolved issues: [ ]',
    'Lease assignment consent is outstanding. Buyer’s lawyer records it as an unresolved closing item and reviews remedies and conditions in the agreement. Accountant reviews allocation and tax questions. No condition is marked satisfied just because this checklist is complete.',
  ),
  TransactionLesson(
    'closing',
    '7 · Close deliberately',
    'Closing checklist & funds-flow review',
    'Coordinate the final documents, approvals and handover with the transaction’s lawyer and lender.',
    'Final signed documents / versions: [ ]\nConditions satisfied or advised waiver: [ ]\nConsents and approvals: [ ]\nDebt payouts / releases: [ ]\nClosing statement and adjustments: [ ]\nFunds flow approved by professionals: [ ]\nIndependent verification of payment instructions: [ ]\nKeys, systems and access handover: [ ]\nResponsible person and completion evidence: [ ]',
    'Counsel confirms final versions and outstanding consent status. Buyer independently verifies payment instructions using an established contact channel. The learning checklist never initiates payment or declares legal completion.',
  ),
  TransactionLesson(
    'transition',
    '8 · Take over & learn',
    'First 100 days & seller handover plan',
    'Translate the acquisition into an operating plan with clear owners, measures and follow-up.',
    '| Time | Priority | Owner | Evidence of completion |\n|---|---|---|---|\n| Day 1 | [ ] | [ ] | [ ] |\n| Days 2–30 | [ ] | [ ] | [ ] |\n| Days 31–60 | [ ] | [ ] | [ ] |\n| Days 61–100 | [ ] | [ ] | [ ] |\n\nCover staff, customers, vendors, cash controls, systems, training and seller support.',
    'Day 1: confirm payroll and customer service continuity. Days 2–30: seller trains buyer on scheduling; reconcile cash weekly. Days 31–60: review customer retention. Days 61–100: compare actual cash flow with the acquisition assumptions and document lessons.',
  ),
];
