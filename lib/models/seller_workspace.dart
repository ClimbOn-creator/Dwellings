import 'dart:math' as math;

enum TransferPath {
  outsideBuyer('Outside buyer', 'Find and qualify a new owner'),
  family('Family succession', 'Prepare a family successor'),
  management('Management buyout', 'Transfer to your leadership team'),
  partial('Partial sale', 'Bring in a partner or investor');

  const TransferPath(this.label, this.summary);
  final String label;
  final String summary;
}

enum SellerStage {
  direction('Set direction', -180),
  prepare('Get sale-ready', -120),
  successor('Find your successor', -90),
  terms('Agree on terms', -60),
  diligence('Prove the business', -30),
  closing('Close the transfer', -7),
  handover('Hand over well', 30);

  const SellerStage(this.label, this.daysFromClose);
  final String label;
  final int daysFromClose;
}

class SellerTask {
  const SellerTask(
    this.id,
    this.stage,
    this.title,
    this.detail,
    this.role, {
    this.paths,
  });

  final String id;
  final SellerStage stage;
  final String title;
  final String detail;
  final String role;
  final Set<TransferPath>? paths;

  bool appliesTo(TransferPath path) => paths == null || paths!.contains(path);
}

const sellerTasks = <SellerTask>[
  SellerTask(
    'goals',
    SellerStage.direction,
    'Write your exit goals',
    'Set your preferred timing, role after closing, price priorities and non-negotiable terms.',
    'Owner',
  ),
  SellerTask(
    'route',
    SellerStage.direction,
    'Choose the transfer path',
    'Compare an outside sale, family handover, management buyout or partial sale with your advisers.',
    'Transaction lead',
  ),
  SellerTask(
    'tax_structure',
    SellerStage.direction,
    'Review tax and legal structure',
    'Have your CPA and lawyer compare share and asset structures before promising a buyer a structure.',
    'CPA / tax adviser',
  ),
  SellerTask(
    'family_alignment',
    SellerStage.direction,
    'Align family expectations',
    'Record decision rights, fairness concerns and the successor’s preparation plan.',
    'Family adviser',
    paths: {TransferPath.family},
  ),
  SellerTask(
    'management_alignment',
    SellerStage.direction,
    'Test management interest and capacity',
    'Agree who could lead, what ownership they want and how confidentiality will be handled.',
    'Operations successor',
    paths: {TransferPath.management},
  ),
  SellerTask(
    'financial_history',
    SellerStage.prepare,
    'Prepare three years of financial history',
    'Reconcile statements, tax returns, monthly trends and unusual items with your accountant.',
    'CPA / tax adviser',
  ),
  SellerTask(
    'earnings',
    SellerStage.prepare,
    'Build a supportable earnings bridge',
    'Separate reported EBITDA, verified add-backs, owner pay and a realistic replacement salary.',
    'Valuation specialist',
  ),
  SellerTask(
    'valuation',
    SellerStage.prepare,
    'Commission an independent valuation',
    'Use a qualified specialist to test comparables, assets, liabilities and the value of transferable earnings.',
    'Valuation specialist',
  ),
  SellerTask(
    'operations',
    SellerStage.prepare,
    'Reduce owner dependence',
    'Document critical decisions, systems, customer relationships and who can run each function.',
    'Operations successor',
  ),
  SellerTask(
    'consents_map',
    SellerStage.prepare,
    'Map contracts and approvals',
    'List leases, customer and supplier contracts, licences, financing and any consent needed to transfer.',
    'Legal counsel',
  ),
  SellerTask(
    'buyer_profile',
    SellerStage.successor,
    'Define a qualified buyer',
    'Set capability, financing, culture and continuity criteria before broad outreach.',
    'Transaction lead',
    paths: {TransferPath.outsideBuyer, TransferPath.partial},
  ),
  SellerTask(
    'confidential_marketing',
    SellerStage.successor,
    'Prepare confidential outreach',
    'Use a teaser and a staged NDA process before sharing identifying information.',
    'Transaction lead',
    paths: {TransferPath.outsideBuyer, TransferPath.partial},
  ),
  SellerTask(
    'successor_training',
    SellerStage.successor,
    'Build the successor development plan',
    'Define training, decision authority and milestones for the next leader.',
    'Operations successor',
    paths: {TransferPath.family, TransferPath.management},
  ),
  SellerTask(
    'capital_plan',
    SellerStage.successor,
    'Test buyer financing capacity',
    'Discuss equity, lender financing and any proposed vendor note before agreeing to a timetable.',
    'Financing adviser',
  ),
  SellerTask(
    'partial_governance',
    SellerStage.terms,
    'Define retained ownership and decision rights',
    'Agree which decisions, future funding obligations and exit rights remain with each owner.',
    'Legal counsel',
    paths: {TransferPath.partial},
  ),
  SellerTask(
    'loi',
    SellerStage.terms,
    'Negotiate a letter of intent',
    'Record price, payment mix, conditions, exclusivity, working capital and intended closing date for counsel to review.',
    'Legal counsel',
  ),
  SellerTask(
    'vendor_note',
    SellerStage.terms,
    'Evaluate deferred payment risk',
    'Model any holdback, earn-out or vendor note and the security and reporting you would need.',
    'Financing adviser',
  ),
  SellerTask(
    'communication',
    SellerStage.terms,
    'Plan people and customer communication',
    'Decide who learns what, when and from whom while respecting confidentiality and continuity.',
    'People lead',
  ),
  SellerTask(
    'data_room',
    SellerStage.diligence,
    'Open a controlled diligence room',
    'Share approved records in stages, track questions and restrict access to sensitive information.',
    'Transaction lead',
  ),
  SellerTask(
    'buyer_diligence',
    SellerStage.diligence,
    'Resolve diligence findings',
    'Track accounting, legal, employee, tax, contract and operational questions to evidence and owners.',
    'Transaction lead',
  ),
  SellerTask(
    'consents',
    SellerStage.diligence,
    'Obtain required consents',
    'Confirm landlord, lender, customer, regulator and third-party approvals where applicable.',
    'Legal counsel',
  ),
  SellerTask(
    'closing_documents',
    SellerStage.closing,
    'Finalize closing documents',
    'Have counsel reconcile the purchase agreement, schedules, releases and closing conditions.',
    'Legal counsel',
  ),
  SellerTask(
    'closing_numbers',
    SellerStage.closing,
    'Reconcile the closing statement',
    'Confirm cash, debt, inventory, working capital, fees and any deferred payment with your CPA.',
    'CPA / tax adviser',
  ),
  SellerTask(
    'accounts',
    SellerStage.closing,
    'Plan account and registration changes',
    'Check payroll, GST/HST, business numbers, licences and other registrations with the relevant advisers.',
    'CPA / tax adviser',
  ),
  SellerTask(
    'handover_schedule',
    SellerStage.handover,
    'Run the handover schedule',
    'Transfer knowledge, systems and introductions with clear owners and dates.',
    'Operations successor',
  ),
  SellerTask(
    'continuity',
    SellerStage.handover,
    'Watch continuity after closing',
    'Review employee retention, customer service, supplier relationships and open commitments.',
    'Operations successor',
  ),
  SellerTask(
    'final_obligations',
    SellerStage.handover,
    'Close remaining seller obligations',
    'Track transition support, earn-out reporting, retained liabilities and agreed follow-ups.',
    'Legal counsel',
  ),
];

List<SellerTask> tasksFor(TransferPath path) =>
    sellerTasks.where((task) => task.appliesTo(path)).toList(growable: false);

class SellerDealPackItem {
  const SellerDealPackItem(this.id, this.group, this.title, this.detail);
  final String id;
  final String group;
  final String title;
  final String detail;
}

const sellerDealPack = <SellerDealPackItem>[
  SellerDealPackItem(
    'statements',
    'Financial',
    'Three years of statements',
    'Annual and recent interim results, reconciled to the books.',
  ),
  SellerDealPackItem(
    'tax_returns',
    'Financial',
    'Tax returns and assessments',
    'Copies reviewed with your accountant before controlled sharing.',
  ),
  SellerDealPackItem(
    'monthly_kpis',
    'Financial',
    'Monthly trends and KPIs',
    'Revenue, margin, cash, backlog and seasonality.',
  ),
  SellerDealPackItem(
    'addbacks',
    'Financial',
    'Earnings adjustment support',
    'Evidence for each non-recurring cost or owner adjustment.',
  ),
  SellerDealPackItem(
    'working_capital',
    'Financial',
    'Working capital schedule',
    'Receivables, payables, inventory and normal operating cash needs.',
  ),
  SellerDealPackItem(
    'debt',
    'Financial',
    'Debt and security schedule',
    'Loans, guarantees, liens and expected discharge amounts.',
  ),
  SellerDealPackItem(
    'corporate',
    'Legal',
    'Ownership and corporate records',
    'Shareholders, minute book and signing authority.',
  ),
  SellerDealPackItem(
    'contracts',
    'Legal',
    'Material contracts and leases',
    'Renewal dates, change-of-control terms and consent needs.',
  ),
  SellerDealPackItem(
    'licenses',
    'Legal',
    'Licences, permits and insurance',
    'Validity, renewal and transfer requirements.',
  ),
  SellerDealPackItem(
    'claims',
    'Legal',
    'Claims and compliance register',
    'Open disputes, warranties and regulatory matters.',
  ),
  SellerDealPackItem(
    'people',
    'People',
    'Roles and employment terms',
    'Key people, benefits, retention risks and continuity obligations.',
  ),
  SellerDealPackItem(
    'successor',
    'People',
    'Successor training plan',
    'Responsibilities, delegation and knowledge transfer milestones.',
  ),
  SellerDealPackItem(
    'customer_mix',
    'Operations',
    'Customer and supplier concentration',
    'Summaries of major relationships and dependency risks.',
  ),
  SellerDealPackItem(
    'processes',
    'Operations',
    'Operating procedures and systems',
    'Core workflows, software ownership and access handover plan.',
  ),
  SellerDealPackItem(
    'assets',
    'Operations',
    'Assets and inventory register',
    'Condition, title, obsolete stock and items excluded from sale.',
  ),
  SellerDealPackItem(
    'consent_tracker',
    'Transfer',
    'Consent tracker',
    'Who must approve a transfer, by when and under which terms.',
  ),
  SellerDealPackItem(
    'qa_log',
    'Transfer',
    'Buyer question log',
    'One source of truth for questions, answers and supporting evidence.',
  ),
  SellerDealPackItem(
    'day_one',
    'Transfer',
    'Day-one and 100-day handover',
    'Introductions, cash controls, customer continuity and follow-up owners.',
  ),
];

class SellerValuation {
  const SellerValuation({
    required this.reportedEbitda,
    required this.verifiedAddbacks,
    required this.ownerPayInExpenses,
    required this.replacementSalary,
    required this.lowMultiple,
    required this.highMultiple,
    required this.tangibleAssets,
    required this.inventory,
    required this.receivables,
    required this.liabilities,
    required this.expectedPrice,
    required this.vendorNote,
    required this.fees,
    required this.debtPayoff,
  });

  final double reportedEbitda;
  final double verifiedAddbacks;
  final double ownerPayInExpenses;
  final double replacementSalary;
  final double lowMultiple;
  final double highMultiple;
  final double tangibleAssets;
  final double inventory;
  final double receivables;
  final double liabilities;
  final double expectedPrice;
  final double vendorNote;
  final double fees;
  final double debtPayoff;

  double get maintainableEbitda =>
      reportedEbitda +
      verifiedAddbacks +
      ownerPayInExpenses -
      replacementSalary;
  bool get earningsReady =>
      [
        reportedEbitda,
        verifiedAddbacks,
        ownerPayInExpenses,
        replacementSalary,
      ].every((value) => value >= 0) &&
      maintainableEbitda > 0 &&
      lowMultiple > 0 &&
      highMultiple >= lowMultiple;
  double get lowEnterpriseValue =>
      math.max(0, maintainableEbitda * lowMultiple);
  double get highEnterpriseValue =>
      math.max(0, maintainableEbitda * highMultiple);
  double get netAssetReference =>
      tangibleAssets + inventory + receivables - liabilities;
  bool get assetsReady => [
    tangibleAssets,
    inventory,
    receivables,
    liabilities,
  ].every((value) => value >= 0);
  bool get proceedsReady =>
      expectedPrice > 0 &&
      vendorNote >= 0 &&
      vendorNote <= expectedPrice &&
      fees >= 0 &&
      debtPayoff >= 0;
  double get cashAtCloseBeforeTax =>
      expectedPrice - vendorNote - fees - debtPayoff;
}

class SellerWorkspaceDraft {
  const SellerWorkspaceDraft({
    this.businessName = '',
    this.path = TransferPath.outsideBuyer,
    this.targetDate,
    this.handoverMonths = 3,
    this.completedTasks = const {},
    this.readyDocuments = const {},
    this.teamNames = const {},
    this.numbers = const {},
  });

  final String businessName;
  final TransferPath path;
  final DateTime? targetDate;
  final int handoverMonths;
  final Set<String> completedTasks;
  final Set<String> readyDocuments;
  final Map<String, String> teamNames;
  final Map<String, String> numbers;

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'path': path.name,
    'targetDate': targetDate?.toIso8601String(),
    'handoverMonths': handoverMonths,
    'completedTasks': completedTasks.toList(),
    'readyDocuments': readyDocuments.toList(),
    'teamNames': teamNames,
    'numbers': numbers,
  };

  factory SellerWorkspaceDraft.fromJson(Map<String, dynamic> json) {
    TransferPath path = TransferPath.outsideBuyer;
    for (final option in TransferPath.values) {
      if (option.name == json['path']) path = option;
    }
    final team = json['teamNames'];
    final numbers = json['numbers'];
    return SellerWorkspaceDraft(
      businessName: json['businessName'] is String
          ? json['businessName'] as String
          : '',
      path: path,
      targetDate: DateTime.tryParse(json['targetDate']?.toString() ?? ''),
      handoverMonths: (json['handoverMonths'] is num)
          ? (json['handoverMonths'] as num).toInt().clamp(1, 24)
          : 3,
      completedTasks: (json['completedTasks'] is List)
          ? (json['completedTasks'] as List).whereType<String>().toSet()
          : <String>{},
      readyDocuments: (json['readyDocuments'] is List)
          ? (json['readyDocuments'] as List).whereType<String>().toSet()
          : <String>{},
      teamNames: team is Map
          ? team.map((key, value) => MapEntry(key.toString(), value.toString()))
          : <String, String>{},
      numbers: numbers is Map
          ? numbers.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : <String, String>{},
    );
  }
}
