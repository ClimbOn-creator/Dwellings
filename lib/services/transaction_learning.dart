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
  String assetPath({required bool filled}) =>
      'assets/transaction_templates/$id-${filled ? "example" : "template"}.$fileExtension';
  String fileName({required bool filled}) =>
      '$id-${filled ? "example" : "template"}.$fileExtension';

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
