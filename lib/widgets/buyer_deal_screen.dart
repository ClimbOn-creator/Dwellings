import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/business_model.dart';
import '../models/buyer_deal_screen.dart';
import 'dashboard_ui.dart';

enum BuyerScreenMode { business, assets, realEstate }

class BuyerDealScreen extends StatefulWidget {
  const BuyerDealScreen({
    super.key,
    required this.onBack,
    required this.onCreateBusinessRoom,
  });

  final VoidCallback onBack;
  final Future<void> Function(BusinessInputs, BusinessResult)
  onCreateBusinessRoom;

  @override
  State<BuyerDealScreen> createState() => _BuyerDealScreenState();
}

class _BuyerDealScreenState extends State<BuyerDealScreen> {
  static final _money = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
  static final _compactMoney = NumberFormat.compactCurrency(
    symbol: r'$',
    decimalDigits: 1,
  );
  final Map<String, TextEditingController> _fields = {};
  BuyerScreenMode _mode = BuyerScreenMode.business;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final entry in <String, String>{
      'businessDown': '25',
      'businessInterest': '7',
      'businessYears': '7',
      'multipleLow': '3',
      'multipleHigh': '5',
      'assetRecovery': '60',
      'creVacancy': '5',
      'creCap': '6',
      'creDown': '30',
      'creInterest': '6.5',
      'creYears': '25',
      'creHold': '5',
      'creGrowth': '2',
      'creExitCap': '6.5',
    }.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  double _number(String key) =>
      double.tryParse(
        _controller(key).text.replaceAll(',', '').replaceAll(r'$', '').trim(),
      ) ??
      0;

  BusinessPriceScreen get _business => BusinessPriceScreen(
    askingPrice: _number('businessAsk'),
    revenue: _number('businessRevenue'),
    reportedEbitda: _number('businessEbitda'),
    verifiedAddbacks: _number('businessAddbacks'),
    ownerCompensation: _number('businessOwnerComp'),
    replacementSalary: _number('businessSalary'),
    maintenanceCapex: _number('businessCapex'),
    lowMultiple: _number('multipleLow'),
    highMultiple: _number('multipleHigh'),
    downPaymentPercent: _number('businessDown'),
    interestPercent: _number('businessInterest'),
    amortizationYears: _number('businessYears').round(),
  );

  AssetDealScreen get _assets => AssetDealScreen(
    askingPrice: _number('assetAsk'),
    equipment: _number('assetEquipment'),
    inventory: _number('assetInventory'),
    receivables: _number('assetReceivables'),
    intangibles: _number('assetIntangibles'),
    cash: _number('assetCash'),
    liabilities: _number('assetLiabilities'),
    deferredMaintenance: _number('assetMaintenance'),
    transactionCosts: _number('assetCosts'),
    recoveryPercent: _number('assetRecovery'),
  );

  CommercialRealEstateScreen get _cre => CommercialRealEstateScreen(
    askingPrice: _number('creAsk'),
    potentialRent: _number('creRent'),
    otherIncome: _number('creOther'),
    vacancyPercent: _number('creVacancy'),
    operatingExpenses: _number('creExpenses'),
    replacementReserve: _number('creReserve'),
    marketCapPercent: _number('creCap'),
    downPaymentPercent: _number('creDown'),
    interestPercent: _number('creInterest'),
    amortizationYears: _number('creYears').round(),
    holdingYears: _number('creHold').round(),
    annualNoiGrowthPercent: _number('creGrowth'),
    exitCapPercent: _number('creExitCap'),
  );

  Future<void> _createBusinessRoom() async {
    final calculation = _business;
    if (!calculation.isValid || _saving) return;
    final inputs = BusinessInputs(
      businessName: _controller('businessName').text.trim(),
      industry: '',
      location: '',
      values: {
        'askingPrice': calculation.askingPrice,
        'revenue': calculation.revenue,
        'ebitda': calculation.reportedEbitda,
        'ownerComp': calculation.ownerCompensation,
        'addBacks': calculation.verifiedAddbacks,
        'verifiedAddBacks': calculation.verifiedAddbacks,
        'replacementSalary': calculation.replacementSalary,
        'maintenanceCapex': calculation.maintenanceCapex,
        'debtPercent': 100 - calculation.downPaymentPercent,
        'interestRate': calculation.interestPercent,
        'amortizationYears': calculation.amortizationYears.toDouble(),
      },
    );
    setState(() => _saving = true);
    try {
      await widget.onCreateBusinessRoom(inputs, analyzeBusiness(inputs));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(26, 28, 26, 56),
    child: LayoutBuilder(
      builder: (context, bounds) {
        final narrow = bounds.maxWidth < 850;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  tooltip: 'Back to dashboard',
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Deal screen',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF123C57),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNDERWRITE THE OPPORTUNITY',
                    style: TextStyle(
                      color: Color(0xFFB9D8E9),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'One decision workspace. Three ways to value a deal.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Enter your own figures. Results update as you edit.',
                    style: TextStyle(color: Color(0xFFE0ECF3), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _modePicker(bounds.maxWidth < 600),
            const SizedBox(height: 18),
            if (narrow) ...[
              _inputPanel(),
              const SizedBox(height: 16),
              _resultPanel(),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 385, child: _inputPanel()),
                  const SizedBox(width: 16),
                  Expanded(child: _resultPanel()),
                ],
              ),
          ],
        );
      },
    ),
  );

  Widget _modePicker(bool narrow) {
    final choices = <(BuyerScreenMode, String, String, IconData)>[
      (
        BuyerScreenMode.business,
        'Business value',
        'Earnings and acquisition price',
        Icons.storefront_outlined,
      ),
      (
        BuyerScreenMode.assets,
        'Asset value',
        'Adjusted net assets and recovery',
        Icons.inventory_2_outlined,
      ),
      (
        BuyerScreenMode.realEstate,
        'Commercial real estate',
        'NOI, cap rate and debt coverage',
        Icons.apartment_outlined,
      ),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (mode, title, detail, icon) in choices)
          SizedBox(
            width: narrow ? double.infinity : 225,
            child: Material(
              color: _mode == mode ? DashboardUi.paleBlue : Colors.white,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                key: Key('mode_${mode.name}'),
                onTap: () => setState(() => _mode = mode),
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _mode == mode
                          ? DashboardUi.blue
                          : DashboardUi.line,
                      width: _mode == mode ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: DashboardUi.blue, size: 23),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              detail,
                              style: const TextStyle(
                                fontSize: 12,
                                color: DashboardUi.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _inputPanel() => DashboardUi.panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: switch (_mode) {
        BuyerScreenMode.business => _businessInputs(),
        BuyerScreenMode.assets => _assetInputs(),
        BuyerScreenMode.realEstate => _creInputs(),
      },
    ),
  );

  Widget _section(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: DashboardUi.sectionTitle(title, subtitle: description),
  );

  Widget _field(
    String key,
    String label,
    String hint, {
    String? note,
    bool numeric = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          key: Key('field_$key'),
          controller: _controller(key),
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFE),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(fontSize: 12, color: DashboardUi.muted),
          ),
        ],
      ],
    ),
  );

  Widget _pair(Widget first, Widget second) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: first),
      const SizedBox(width: 10),
      Expanded(child: second),
    ],
  );

  List<Widget> _businessInputs() => [
    _section(
      'Business price estimate',
      'Compare the ask with maintainable earnings and a multiple you can support.',
    ),
    _field('businessName', 'Business name', 'Optional', numeric: false),
    _field('businessAsk', 'Asking price', '1,200,000'),
    _pair(
      _field('businessRevenue', 'Annual revenue', '1,800,000'),
      _field('businessEbitda', 'Reported EBITDA', '260,000'),
    ),
    _field(
      'businessAddbacks',
      'Verified add-backs',
      '0',
      note: 'Include only costs supported by records.',
    ),
    _pair(
      _field('businessOwnerComp', 'Owner compensation in EBITDA', '0'),
      _field('businessSalary', 'Replacement manager salary', '0'),
    ),
    _field('businessCapex', 'Annual maintenance investment', '0'),
    const Divider(height: 27),
    _section(
      'Market and financing assumptions',
      'Enter a comparable earnings range and proposed debt terms.',
    ),
    _pair(
      _field('multipleLow', 'Low EBITDA multiple', '3'),
      _field('multipleHigh', 'High EBITDA multiple', '5'),
    ),
    _pair(
      _field('businessDown', 'Down payment %', '25'),
      _field('businessInterest', 'Interest %', '7'),
    ),
    _field('businessYears', 'Loan amortization (years)', '7'),
  ];

  List<Widget> _assetInputs() => [
    _section(
      'Asset value',
      'Use supportable market values for assets actually included in the deal.',
    ),
    _field('assetAsk', 'Asking price', '850,000'),
    _pair(
      _field('assetEquipment', 'Equipment & vehicles', '500,000'),
      _field('assetInventory', 'Saleable inventory', '180,000'),
    ),
    _pair(
      _field('assetReceivables', 'Collectible receivables', '120,000'),
      _field('assetIntangibles', 'Transferable intangibles', '100,000'),
    ),
    _field('assetCash', 'Cash included', '40,000'),
    const Divider(height: 27),
    _section(
      'Claims and recovery',
      'Separate asset value from the cost to acquire and restore it.',
    ),
    _pair(
      _field('assetLiabilities', 'Liabilities assumed', '150,000'),
      _field('assetMaintenance', 'Deferred maintenance', '30,000'),
    ),
    _pair(
      _field('assetCosts', 'Transaction costs', '20,000'),
      _field('assetRecovery', 'Recovery rate %', '60'),
    ),
  ];

  List<Widget> _creInputs() => [
    _section(
      'Commercial real estate',
      'Replace residential features with property income, expenses, cap rates, and vacancy risk.',
    ),
    _field('creName', 'Property name', 'Optional', numeric: false),
    _field('creAsk', 'Asking price', '5,000,000'),
    _pair(
      _field('creRent', 'Annual potential rent', '480,000'),
      _field('creOther', 'Annual other income', '20,000'),
    ),
    _pair(
      _field('creVacancy', 'Vacancy & credit loss %', '5'),
      _field('creExpenses', 'Operating expenses / year', '140,000'),
    ),
    _field(
      'creReserve',
      'Replacement reserve / year',
      '20,000',
      note: 'Include ongoing capital replacement, not loan payments.',
    ),
    const Divider(height: 27),
    _section(
      'Valuation and financing',
      'Use market evidence for cap rates and lender terms.',
    ),
    _pair(
      _field('creCap', 'Market cap rate %', '6'),
      _field('creDown', 'Down payment %', '30'),
    ),
    _pair(
      _field('creInterest', 'Interest %', '6.5'),
      _field('creYears', 'Loan amortization (years)', '25'),
    ),
    const Divider(height: 27),
    _section('Hold scenario', 'Illustrative income and exit assumptions.'),
    _pair(
      _field('creHold', 'Holding period (years)', '5'),
      _field('creGrowth', 'Annual NOI growth %', '2'),
    ),
    _field('creExitCap', 'Exit cap rate %', '6.5'),
  ];

  Widget _resultPanel() => switch (_mode) {
    BuyerScreenMode.business => _businessResults(),
    BuyerScreenMode.assets => _assetResults(),
    BuyerScreenMode.realEstate => _creResults(),
  };

  Widget _empty(String title, String detail) => DashboardUi.panel(
    child: SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_graph_rounded,
              size: 40,
              color: DashboardUi.blue,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: DashboardUi.muted,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _headline(String eyebrow, String value, String note) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: DashboardUi.blue,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: DashboardUi.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          note,
          style: const TextStyle(fontSize: 14, color: DashboardUi.muted),
        ),
      ],
    ),
  );

  Widget _stat(String label, String value, String note) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FAFF),
      border: Border.all(color: DashboardUi.line),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          note,
          style: const TextStyle(fontSize: 12, color: DashboardUi.muted),
        ),
      ],
    ),
  );

  Widget _stats(List<Widget> children) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth < 540
          ? (box.maxWidth - 10) / 2
          : (box.maxWidth - 20) / 3;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );

  Widget _line(String label, String value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _sectionPanel(
    String title,
    List<Widget> children, {
    String? subtitle,
  }) => DashboardUi.panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardUi.sectionTitle(title, subtitle: subtitle),
        const SizedBox(height: 13),
        ...children,
      ],
    ),
  );

  Widget _businessResults() {
    final s = _business;
    if (!s.isValid) {
      return _empty(
        'Business value will appear here',
        'Enter the asking price, annual revenue, reported EBITDA, and a supported earnings multiple.',
      );
    }
    final flags = <String>[
      if (s.askingPrice > s.highValue)
        'Asking price is above the high end of your earnings range.',
      if (s.dscr < 1)
        'Maintainable cash flow does not cover modeled debt payments.',
      if (s.dscr >= 1 && s.dscr < 1.25)
        'Debt coverage is thin; verify lending requirements.',
      if (s.cashAfterDebt < 0)
        'Modeled cash after debt and maintenance is negative.',
      if (s.verifiedAddbacks > s.reportedEbitda * .3)
        'Add-backs are material; check supporting records.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headline(
          'Indicative enterprise value',
          '${_compactMoney.format(s.lowValue)}–${_compactMoney.format(s.highValue)}',
          'Maintainable EBITDA × your low and high market multiples',
        ),
        const SizedBox(height: 12),
        _stats([
          _stat(
            'Maintainable EBITDA',
            _money.format(s.maintainableEbitda),
            'After verified adjustments and manager pay',
          ),
          _stat(
            'Asking multiple',
            '${s.askingMultiple.toStringAsFixed(1)}×',
            'Ask ÷ maintainable EBITDA',
          ),
          _stat(
            'Ask vs midpoint',
            _money.format(s.priceGap),
            s.priceGap > 0 ? 'Above midpoint' : 'Below midpoint',
          ),
          _stat(
            'Debt coverage',
            s.annualDebt == 0 ? 'No debt' : '${s.dscr.toStringAsFixed(2)}×',
            'Cash available for debt ÷ payments',
          ),
          _stat(
            'Cash after debt',
            _money.format(s.cashAfterDebt),
            'Annual, before tax',
          ),
          _stat(
            'Cash on cash',
            s.askingPrice == s.loan
                ? '—'
                : '${(s.cashOnCash * 100).toStringAsFixed(1)}%',
            'Cash after debt ÷ equity',
          ),
        ]),
        const SizedBox(height: 12),
        _sectionPanel('Earnings bridge', [
          _line('Reported EBITDA', _money.format(s.reportedEbitda)),
          _line('Verified add-backs', _money.format(s.verifiedAddbacks)),
          _line(
            'Owner compensation in EBITDA',
            _money.format(s.ownerCompensation),
          ),
          _line(
            'Replacement manager salary',
            '-${_money.format(s.replacementSalary)}',
          ),
          const Divider(),
          _line(
            'Maintainable EBITDA',
            _money.format(s.maintainableEbitda),
            strong: true,
          ),
        ]),
        const SizedBox(height: 12),
        _sectionPanel(
          'Diligence signals',
          [
            if (flags.isEmpty)
              const Text(
                'No immediate numerical flags. Confirm earnings and comparable transactions.',
                style: TextStyle(fontSize: 14, color: DashboardUi.muted),
              ),
            for (final flag in flags) _signal(flag),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _saving ? null : _createBusinessRoom,
              icon: const Icon(Icons.meeting_room_outlined),
              label: Text(_saving ? 'Creating…' : 'Create business deal room'),
            ),
          ],
          subtitle:
              'A first pass for the buyer team; verify the underlying records.',
        ),
        const SizedBox(height: 10),
        _footnote(
          'Enterprise value excludes cash, debt, and working capital adjustments. The multiple must come from comparable transactions.',
        ),
      ],
    );
  }

  Widget _assetResults() {
    final s = _assets;
    if (!s.isValid) {
      return _empty(
        'Asset analysis will appear here',
        'Enter the asking price and market values for the assets included in the deal.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headline(
          'Adjusted net asset value',
          _money.format(s.adjustedNetAssets),
          'Market value of included assets less assumed liabilities and deferred maintenance',
        ),
        const SizedBox(height: 12),
        _stats([
          _stat(
            'Asset coverage',
            '${s.assetCoverage.toStringAsFixed(2)}×',
            'Adjusted net assets ÷ asking price',
          ),
          _stat(
            'Ask above asset value',
            _money.format(s.priceGap),
            s.priceGap > 0
                ? 'Premium to support with earnings or intangibles'
                : 'Below adjusted net assets',
          ),
          _stat(
            'Total buyer cost',
            _money.format(s.totalBuyerCost),
            'Ask + transaction costs + maintenance',
          ),
        ]),
        const SizedBox(height: 12),
        _sectionPanel('Asset value bridge', [
          _line('Equipment and vehicles', _money.format(s.equipment)),
          _line('Inventory', _money.format(s.inventory)),
          _line('Receivables', _money.format(s.receivables)),
          _line('Transferable intangibles', _money.format(s.intangibles)),
          _line('Cash included', _money.format(s.cash)),
          _line('Liabilities assumed', '-${_money.format(s.liabilities)}'),
          _line(
            'Deferred maintenance',
            '-${_money.format(s.deferredMaintenance)}',
          ),
          const Divider(),
          _line(
            'Adjusted net assets',
            _money.format(s.adjustedNetAssets),
            strong: true,
          ),
        ]),
        const SizedBox(height: 12),
        _sectionPanel('Recovery scenario', [
          _line(
            'Recovery rate on noncash assets',
            '${s.recoveryPercent.toStringAsFixed(0)}%',
          ),
          _line(
            'Indicative liquidation proceeds',
            _money.format(s.liquidationFloor),
            strong: true,
          ),
          const SizedBox(height: 8),
          const Text(
            'Check title, liens, condition, saleability, and which obligations transfer.',
            style: TextStyle(fontSize: 14, color: DashboardUi.muted),
          ),
        ]),
        const SizedBox(height: 10),
        _footnote(
          'Asset values are inputs, not appraisals. This view does not assume goodwill or operating earnings beyond the entered intangible value.',
        ),
      ],
    );
  }

  Widget _creResults() {
    final s = _cre;
    if (!s.isValid) {
      return _empty(
        'Commercial property analysis will appear here',
        'Enter an asking price, rent, expenses, replacement reserve, and market cap rate.',
      );
    }
    final stressNoi =
        s.potentialGrossIncome *
            (1 - (s.vacancyPercent + 5).clamp(0, 100) / 100) -
        s.operatingExpenses -
        s.replacementReserve;
    final stressValue = stressNoi / ((s.marketCapPercent + 1) / 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headline(
          'Income approach value',
          _money.format(s.incomeValue),
          'Stabilized NOI ÷ market cap rate',
        ),
        const SizedBox(height: 12),
        _stats([
          _stat(
            'Net operating income',
            _money.format(s.noi),
            'After vacancy, expenses and reserve',
          ),
          _stat(
            'Going-in cap rate',
            '${(s.goingInCap * 100).toStringAsFixed(2)}%',
            'NOI ÷ asking price',
          ),
          _stat(
            'Value vs ask',
            _money.format(s.valueGap),
            s.valueGap >= 0
                ? 'Income value above ask'
                : 'Income value below ask',
          ),
          _stat(
            'Debt coverage',
            s.annualDebt == 0 ? 'No debt' : '${s.dscr.toStringAsFixed(2)}×',
            'NOI ÷ annual debt service',
          ),
          _stat(
            'Debt yield',
            s.loan == 0
                ? 'No debt'
                : '${(s.debtYield * 100).toStringAsFixed(2)}%',
            'NOI ÷ proposed loan',
          ),
          _stat(
            'Cash on cash',
            s.askingPrice == s.loan
                ? '—'
                : '${(s.cashOnCash * 100).toStringAsFixed(1)}%',
            'Cash after debt ÷ down payment',
          ),
        ]),
        const SizedBox(height: 12),
        _sectionPanel('Property income bridge', [
          _line(
            'Potential rent and other income',
            _money.format(s.potentialGrossIncome),
          ),
          _line('Vacancy and credit loss', '-${_money.format(s.vacancyLoss)}'),
          _line(
            'Effective gross income',
            _money.format(s.effectiveGrossIncome),
          ),
          _line('Operating expenses', '-${_money.format(s.operatingExpenses)}'),
          _line(
            'Replacement reserve',
            '-${_money.format(s.replacementReserve)}',
          ),
          const Divider(),
          _line('Stabilized NOI', _money.format(s.noi), strong: true),
          _line('Annual debt service', _money.format(s.annualDebt)),
          _line(
            'Cash after debt',
            _money.format(s.cashAfterDebt),
            strong: true,
          ),
        ]),
        const SizedBox(height: 12),
        _sectionPanel(
          'Commercial scorecard',
          [
            _line('Opportunity score', '${s.opportunityScore.round()}/100'),
            _line('Risk score', '${s.riskScore.round()}/100'),
            _line(
              'Net screen score',
              '${s.netScore.round()}/100',
              strong: true,
            ),
            const SizedBox(height: 7),
            for (final entry in s.factorScores.entries)
              _factor(entry.key, entry.value),
          ],
          subtitle:
              'Adapted from your weighted Housing Moneyball factors; illustrative, not a calibrated probability.',
        ),
        const SizedBox(height: 12),
        _sectionPanel(
          'Hold and stress view',
          [
            _line('Projected NOI at exit', _money.format(s.projectedNoi)),
            _line(
              'Projected value at exit',
              _money.format(s.projectedValue),
              strong: true,
            ),
            const Divider(),
            _line('Stress NOI · vacancy +5 points', _money.format(stressNoi)),
            _line(
              'Stress value · cap +1 point',
              _money.format(stressValue),
              strong: true,
            ),
            if (s.dscr < 1.25)
              _signal(
                'Modeled debt coverage is below 1.25×; test lender requirements and lease rollover.',
              ),
          ],
          subtitle:
              'Exit value excludes sale costs, taxes, and remaining loan balance.',
        ),
        const SizedBox(height: 10),
        _footnote(
          'Check rent rolls, lease terms, tenant concentration, recoveries, capex, and comparable sales. The scorecard weights are hypotheses until calibrated.',
        ),
      ],
    );
  }

  Widget _factor(String label, double score) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 125,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: DashboardUi.paleBlue,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          '${score.round()}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  Widget _signal(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 17,
          color: Color(0xFFB88016),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
      ],
    ),
  );

  Widget _footnote(String value) => Text(
    value,
    style: const TextStyle(fontSize: 12, color: DashboardUi.muted, height: 1.4),
  );
}
