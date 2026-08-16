import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/account_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/acquisition_step_bar.dart';
import '../widgets/topo_background.dart';
import 'auth_page.dart';
import 'business_acquisition_page.dart';
import 'deal_rooms_page.dart';

const _ink = Color(0xFF050510);
const _green = Color(0xFF7657FF);
const _lime = Color(0xFFBCAEFF);
const _paper = Color(0xFF09091B);
const _line = Color(0xFF292944);
const _muted = Color(0xFFA5A5B5);
const _surface = Color(0xFF121225);
const _lilac = Color(0xFFBCAEFF);

class AcquisitionSupportPage extends StatefulWidget {
  const AcquisitionSupportPage({super.key});

  @override
  State<AcquisitionSupportPage> createState() => _AcquisitionSupportPageState();
}

class _AcquisitionSupportPageState extends State<AcquisitionSupportPage> {
  AcquisitionFoundation? _foundation;

  @override
  void initState() {
    super.initState();
    AcquisitionFoundation.load().then((value) {
      if (mounted) setState(() => _foundation = value);
    });
  }

  void _open(Widget page) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => page))
      .then((_) async {
        final value = await AcquisitionFoundation.load();
        if (mounted) setState(() => _foundation = value);
      });

  @override
  Widget build(BuildContext context) {
    final value = _foundation;
    if (value == null) {
      return const Scaffold(
        backgroundColor: _paper,
        body: Center(child: CircularProgressIndicator(color: _green)),
      );
    }
    final readiness = value.readinessScore;
    return Scaffold(
      backgroundColor: _paper,
      body: TopoBackground(
        color: _paper,
        opacity: .11,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _mobileHeader(value)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 44, 24, 110),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACQUISITION SUPPORT',
                          style: TextStyle(
                            color: _green,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Define. Prepare.\nScreen with confidence.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.sizeOf(context).width < 650
                                ? 42
                                : 64,
                            height: .98,
                            letterSpacing: -3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Start with the buyer—not the deal. Your Blueprint and Readiness profile become the benchmark for every opportunity.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 34),
                        _NorthStar(value: value),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (_, box) {
                            final width = box.maxWidth >= 760
                                ? (box.maxWidth - 24) / 3
                                : box.maxWidth;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _MetricCard(
                                  width: width,
                                  label: 'BLUEPRINT CLARITY',
                                  value: '${value.blueprintScore}',
                                  note: 'Your mandate is the deal benchmark.',
                                  onTap: () =>
                                      _open(const AcquisitionBlueprintPage()),
                                ),
                                _MetricCard(
                                  width: width,
                                  label: 'BUYER READINESS',
                                  value: '$readiness',
                                  note: readiness >= 70
                                      ? 'A solid base for the right deal.'
                                      : 'Priority actions remain.',
                                  onTap: () =>
                                      _open(const BuyerReadinessPage()),
                                ),
                                _MetricCard(
                                  width: width,
                                  label: 'INDICATIVE CAPACITY',
                                  value: _compactMoney(value.capacity),
                                  note: 'Directional—not lending approval.',
                                  onTap: () =>
                                      _open(const BuyerReadinessPage()),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 42),
                        const Text(
                          'YOUR ACQUISITION PATH',
                          style: TextStyle(
                            color: _green,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ActionTile(
                          number: '01',
                          title: 'Acquisition Blueprint',
                          copy:
                              'Define target type, geography, economics, involvement, hard limits, and stretch criteria.',
                          action: 'Refine mandate',
                          onTap: () => _open(const AcquisitionBlueprintPage()),
                        ),
                        _ActionTile(
                          number: '02',
                          title: 'Buyer Readiness',
                          copy:
                              'Measure financial capacity, documentation, experience, and lender preparation.',
                          action: 'Build readiness',
                          onTap: () => _open(const BuyerReadinessPage()),
                        ),
                        _ActionTile(
                          number: '03',
                          title: 'Initial Deal Screen',
                          copy:
                              'Test a live opportunity without confusing deal fit with your ability to execute.',
                          action: 'Screen a deal',
                          onTap: () => _open(const BusinessAcquisitionPage()),
                        ),
                        _ActionTile(
                          number: '04',
                          title: 'My Deal Pipeline',
                          copy:
                              'Compare active opportunities, preserve decisions, and move serious deals into support.',
                          action: 'View pipeline',
                          onTap: () => _open(
                            const DealRoomsPage(
                              initialSide: PlatformSide.business,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileHeader(AcquisitionFoundation value) => Material(
    color: _ink,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            const HomeBrandButton(size: 42, dark: true),
            const Spacer(),
            const AppNavigationMenu(side: PlatformSide.business),
          ],
        ),
      ),
    ),
  );
}

class AcquisitionBlueprintPage extends StatefulWidget {
  const AcquisitionBlueprintPage({super.key});
  @override
  State<AcquisitionBlueprintPage> createState() =>
      _AcquisitionBlueprintPageState();
}

class _AcquisitionBlueprintPageState extends State<AcquisitionBlueprintPage> {
  AcquisitionFoundation? value;
  final controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    AcquisitionFoundation.load().then((loaded) {
      for (final entry in loaded.blueprint.entries) {
        controllers[entry.key] = TextEditingController(text: '${entry.value}');
      }
      if (mounted) setState(() => value = loaded);
    });
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateDraft() async {
    final current = value!;
    current.blueprint.addAll({
      for (final entry in controllers.entries) entry.key: entry.value.text,
    });
    await current.save();
  }

  Future<void> _save() async {
    await _updateDraft();
    if (!mounted) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    try {
      await value!.saveForAccount('blueprint');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft kept on this device. Cloud save failed: $error'),
        ),
      );
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Step 1 saved to your profile.')),
      );
    }
  }

  Future<void> _goStep(int step) async {
    if (step == 0) return;
    await _updateDraft();
    if (!mounted) return;
    final page = switch (step) {
      1 => const BuyerReadinessPage(),
      2 => const BusinessAcquisitionPage(),
      _ => const DealRoomsPage(initialSide: PlatformSide.business),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _clear() => setState(() {
    for (final controller in controllers.values) {
      controller.clear();
    }
  });

  @override
  Widget build(BuildContext context) => _ModuleScaffold(
    kicker: 'PAGE 1 OF 4 · BLUEPRINT',
    title: 'Acquisition Blueprint',
    subtitle:
        'Define the acquisition you want before a compelling deal changes the rules.',
    currentStep: 0,
    onStepSelected: _goStep,
    child: value == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _FormSection(
                number: '01',
                title: 'Target acquisition',
                children: [
                  _dropdown('type', 'Acquisition type', const [
                    'Business acquisition',
                    'Asset purchase',
                    'Share purchase',
                    'Undecided',
                  ]),
                  _input(
                    'geography',
                    'Target geography',
                    hint: 'City, province, or region',
                  ),
                  _input(
                    'minPrice',
                    'Minimum purchase price',
                    unit: r'$ CAD',
                    hint: 'e.g. 500,000',
                  ),
                  _input(
                    'maxPrice',
                    'Maximum purchase price',
                    unit: r'$ CAD',
                    hint: 'e.g. 2,000,000',
                  ),
                  _input(
                    'minReturn',
                    'Minimum return or earnings yield',
                    unit: '%',
                    hint: 'e.g. 18',
                  ),
                  _dropdown('involvement', 'Desired operating role', const [
                    'Owner-operator',
                    'Strategic owner',
                    'Investor with manager',
                    'Undecided',
                  ]),
                ],
              ),
              const SizedBox(height: 18),
              _FormSection(
                number: '02',
                title: 'Fit and boundaries',
                children: [
                  _input(
                    'industries',
                    'Preferred industries or asset types',
                    hint: 'Industries you understand or want to explore',
                  ),
                  _input(
                    'limits',
                    'Hard limits',
                    hint: 'Conditions that immediately rule out a deal',
                    maxLines: 3,
                  ),
                  _input(
                    'stretch',
                    'Acceptable stretch criteria',
                    hint: 'Where you could be flexible',
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Clear form'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save Step 1 to profile'),
                  ),
                ],
              ),
            ],
          ),
  );

  Widget _input(
    String key,
    String label, {
    String? unit,
    String? hint,
    int maxLines = 1,
  }) => _LabeledField(
    label: label,
    unit: unit,
    child: TextField(
      controller: controllers[key],
      keyboardType: ['minPrice', 'maxPrice', 'minReturn'].contains(key)
          ? TextInputType.number
          : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint),
    ),
  );

  Widget _dropdown(String key, String label, List<String> options) {
    final current = controllers[key]?.text.trim() ?? '';
    return _LabeledField(
      label: label,
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(current) ? current : null,
        hint: const Text('Select an option'),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (selected) => controllers[key]?.text = selected ?? '',
      ),
    );
  }
}

class BuyerReadinessPage extends StatefulWidget {
  const BuyerReadinessPage({super.key});
  @override
  State<BuyerReadinessPage> createState() => _BuyerReadinessPageState();
}

class _BuyerReadinessPageState extends State<BuyerReadinessPage> {
  AcquisitionFoundation? value;
  final controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    AcquisitionFoundation.load().then((loaded) {
      for (final key in ['equity', 'reserves', 'income', 'credit']) {
        controllers[key] = TextEditingController(
          text: '${loaded.readiness[key]}',
        );
      }
      if (mounted) setState(() => value = loaded);
    });
  }

  Future<void> _updateDraft() async {
    final current = value!;
    for (final entry in controllers.entries) {
      current.readiness[entry.key] = entry.value.text;
    }
    await current.save();
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await _updateDraft();
    if (!mounted) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    try {
      await value!.saveForAccount('readiness');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Step 2 saved to your profile.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Draft kept on this device. Cloud save failed: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _goStep(int step) async {
    await _updateDraft();
    if (!mounted || step == 1) return;
    final page = switch (step) {
      0 => const AcquisitionBlueprintPage(),
      2 => const BusinessAcquisitionPage(),
      _ => const DealRoomsPage(initialSide: PlatformSide.business),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    return _ModuleScaffold(
      kicker: 'PAGE 2 OF 4 · READINESS',
      title: 'Buyer Readiness',
      subtitle:
          'Understand what you can execute now and your path to becoming transaction-ready.',
      currentStep: 1,
      onStepSelected: _goStep,
      child: current == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _ReadinessSummary(value: current),
                const SizedBox(height: 18),
                _FormSection(
                  number: '01',
                  title: 'Financial capacity',
                  children: [
                    for (final item in const {
                      'equity': 'Available equity or cash',
                      'reserves': 'Post-close reserves',
                      'income': 'Annual supporting income',
                    }.entries)
                      _LabeledField(
                        label: item.value,
                        unit: r'$ CAD',
                        child: TextField(
                          controller: controllers[item.key],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter amount',
                          ),
                        ),
                      ),
                    _LabeledField(
                      label: 'Credit profile',
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            const [
                              'Excellent',
                              'Good',
                              'Fair',
                              'Needs work',
                            ].contains(controllers['credit']?.text)
                            ? controllers['credit']!.text
                            : null,
                        hint: const Text('Select a profile'),
                        items: const ['Excellent', 'Good', 'Fair', 'Needs work']
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        onChanged: (selected) =>
                            controllers['credit']?.text = selected ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _FormSection(
                  number: '02',
                  title: 'Transaction package',
                  children: [
                    for (final item in const {
                      'proof': 'Proof of funds',
                      'tax': 'Tax returns / financial statements',
                      'resume': 'Buyer résumé / operating story',
                      'entity': 'Acquisition entity information',
                      'lender': 'Introductory lender conversation',
                    }.entries)
                      CheckboxListTile(
                        value: current.readiness[item.key] == true,
                        title: Text(item.value),
                        subtitle: Text(
                          current.readiness[item.key] == true
                              ? 'Ready'
                              : 'Action needed',
                        ),
                        activeColor: _green,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (checked) => setState(
                          () => current.readiness[item.key] = checked == true,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save Step 2 to profile'),
                  ),
                ),
              ],
            ),
    );
  }
}

// Retained temporarily for migration of earlier local Guide sessions.
// ignore: unused_element
class AcquisitionGuideSheet extends StatefulWidget {
  const AcquisitionGuideSheet({super.key, required this.foundation});
  final AcquisitionFoundation foundation;
  @override
  State<AcquisitionGuideSheet> createState() => _AcquisitionGuideSheetState();
}

class _AcquisitionGuideSheetState extends State<AcquisitionGuideSheet> {
  final input = TextEditingController();
  bool thinking = false;
  late final List<({bool user, String text})> messages;

  @override
  void initState() {
    super.initState();
    messages = [
      (
        user: false,
        text:
            'I want to understand you before I recommend anything. What outcome would make this acquisition successful three years after close?',
      ),
    ];
  }

  Future<void> _ask([String? prompt]) async {
    final question = (prompt ?? input.text).trim();
    if (question.isEmpty || thinking) return;
    final memory = List<String>.from(
      widget.foundation.readiness['guideMemory'] as List? ?? const [],
    )..add(question);
    widget.foundation.readiness['guideMemory'] = memory;
    await widget.foundation.save();
    setState(() {
      messages.add((user: true, text: question));
      input.clear();
      thinking = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    final lower = question.toLowerCase();
    String answer;
    if (memory.length == 1) {
      answer =
          'Got it. Now help me understand the constraint: how much capital must remain untouched after closing, and how involved do you want to be day to day?';
    } else if (memory.length == 2) {
      answer =
          'That changes the shape of a viable deal. One more thing before I form a view: which risk would you regret most—overpaying, operational complexity, unreliable earnings, or missing growth?';
    } else if (memory.length == 3) {
      answer =
          'I have enough context to start being useful. I’ll carry these priorities into your Blueprint, readiness actions, and future deal screens. Ask me about a target or opportunity and I’ll explain my reasoning—not just give a verdict.';
    } else if (lower.contains('next')) {
      answer = widget.foundation.readiness['proof'] != true
          ? 'Prepare proof of funds first, then validate debt capacity with a lender. Those two actions remove the biggest execution uncertainty.'
          : 'Your documentation is progressing. Screen a live opportunity and compare its price, economics, risk, and fit separately.';
    } else if (lower.contains('realistic') || lower.contains('afford')) {
      answer =
          'Your entered capital suggests an indicative acquisition capacity of ${_money(widget.foundation.capacity)}. Treat that as a planning range, not approval, until a lender validates leverage and debt service.';
    } else {
      answer =
          'A viable deal for you should fit ${_money(widget.foundation.minPrice)}–${_money(widget.foundation.maxPrice)}, meet at least ${widget.foundation.blueprint['minReturn']}% headline return, and respect this hard limit: ${widget.foundation.blueprint['limits']}.';
    }
    setState(() {
      messages.add((user: false, text: answer));
      thinking = false;
    });
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .88,
    child: Material(
      color: _ink,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.auto_awesome_rounded),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acquisition Guide',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Personalized from your saved foundation',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.foundation.guideSummary,
                style: const TextStyle(color: _muted, height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  backgroundColor: _surface,
                  side: const BorderSide(color: _line),
                  label: const Text(
                    'Teach the Guide about me',
                    style: TextStyle(color: _lilac),
                  ),
                  onPressed: () => _ask(
                    'My main acquisition goal is long-term independence and durable cash flow.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  for (final message in messages)
                    Align(
                      alignment: message.user
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 620),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: message.user ? _green : _surface,
                          border: Border.all(color: _line),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(color: Colors.white, height: 1.45),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (thinking)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _lilac,
                      ),
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Connecting this to your acquisition profile…',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    onSubmitted: _ask,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your acquisition…',
                      hintStyle: TextStyle(color: _muted),
                      filled: true,
                      fillColor: _surface,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: _green),
                  onPressed: thinking ? null : _ask,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class AcquisitionFoundation {
  AcquisitionFoundation({
    required this.blueprint,
    required this.readiness,
    required this.dealScreen,
  });
  final Map<String, dynamic> blueprint;
  final Map<String, dynamic> readiness;
  final Map<String, dynamic> dealScreen;

  static const _key = 'acquisition_foundation_v1';
  static const _pendingKey = 'acquisition_foundation_pending_sync';
  static const _completedKey = 'acquisition_completed_modules';
  static final _defaults = {
    'blueprint': {
      'type': '',
      'geography': '',
      'minPrice': '',
      'maxPrice': '',
      'minReturn': '',
      'involvement': '',
      'industries': '',
      'limits': '',
      'stretch': '',
    },
    'readiness': {
      'equity': '',
      'reserves': '',
      'income': '',
      'credit': '',
      'proof': false,
      'tax': true,
      'resume': false,
      'entity': false,
      'lender': false,
    },
    'dealScreen': <String, dynamic>{},
  };

  static Future<AcquisitionFoundation> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    var data = raw == null
        ? jsonDecode(jsonEncode(_defaults)) as Map<String, dynamic>
        : jsonDecode(raw) as Map<String, dynamic>;
    const legacyBlueprint = {
      'type': 'Business Acquisition',
      'geography': 'British Columbia',
      'minPrice': '500000',
      'maxPrice': '2000000',
      'minReturn': '18',
      'involvement': 'Owner-operator',
      'industries': 'Home services, recurring revenue',
      'limits': 'No turnarounds; no single customer over 25%',
      'stretch': 'Adjacent industries with an experienced GM',
    };
    final blueprint = Map<String, dynamic>.from(data['blueprint'] as Map);
    final isLegacySeed = legacyBlueprint.entries.every(
      (entry) => '${blueprint[entry.key]}' == entry.value,
    );
    if (isLegacySeed) {
      data = jsonDecode(jsonEncode(_defaults)) as Map<String, dynamic>;
      await prefs.setString(_key, jsonEncode(data));
    }
    if (BackendService.user != null && prefs.getBool(_pendingKey) != true) {
      try {
        final cloud = await AccountService.loadAcquisitionFoundation();
        if (cloud != null && cloud.isNotEmpty) {
          data = cloud;
          await prefs.setString(_key, jsonEncode(data));
        }
      } catch (_) {
        // The local draft remains available if the profile migration is pending.
      }
    }
    final blueprintData = data['blueprint'] is Map
        ? Map<String, dynamic>.from(data['blueprint'] as Map)
        : Map<String, dynamic>.from(_defaults['blueprint']! as Map);
    final readinessData = data['readiness'] is Map
        ? Map<String, dynamic>.from(data['readiness'] as Map)
        : Map<String, dynamic>.from(_defaults['readiness']! as Map);
    final dealData = data['dealScreen'] is Map
        ? Map<String, dynamic>.from(data['dealScreen'] as Map)
        : <String, dynamic>{};
    final foundation = AcquisitionFoundation(
      blueprint: blueprintData,
      readiness: readinessData,
      dealScreen: dealData,
    );
    if (BackendService.user != null && prefs.getBool(_pendingKey) == true) {
      try {
        await foundation.syncPendingToAccount();
      } catch (_) {}
    }
    return foundation;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
    await prefs.setBool(_pendingKey, true);
  }

  Map<String, dynamic> toJson() => {
    'blueprint': blueprint,
    'readiness': readiness,
    'dealScreen': dealScreen,
  };

  Future<void> saveForAccount(String module) async {
    await save();
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_completedKey) ?? <String>[];
    if (!completed.contains(module)) completed.add(module);
    await prefs.setStringList(_completedKey, completed);
    await syncPendingToAccount();
  }

  Future<void> syncPendingToAccount() async {
    if (BackendService.user == null) throw StateError('Sign in required.');
    final prefs = await SharedPreferences.getInstance();
    await AccountService.saveAcquisitionFoundation(
      toJson(),
      completedModules: prefs.getStringList(_completedKey) ?? const [],
    );
    await prefs.setBool(_pendingKey, false);
  }

  double get minPrice => double.tryParse('${blueprint['minPrice']}') ?? 0;
  double get maxPrice => double.tryParse('${blueprint['maxPrice']}') ?? 0;
  double get capacity =>
      ((double.tryParse('${readiness['equity']}') ?? 0) +
          (double.tryParse('${readiness['reserves']}') ?? 0) * .5) *
      4;
  int get blueprintScore =>
      ((blueprint.values.where((value) => '$value'.trim().isNotEmpty).length /
                  blueprint.length) *
              100)
          .round();
  int get readinessScore {
    var score = 30;
    for (final key in ['proof', 'tax', 'resume', 'entity', 'lender']) {
      if (readiness[key] == true) score += 10;
    }
    final credit = '${readiness['credit']}'.toLowerCase();
    score += credit.contains('excellent')
        ? 20
        : credit.contains('good')
        ? 14
        : 7;
    return score.clamp(0, 100);
  }

  String get guideSummary =>
      'You are targeting ${blueprint['type'].toString().toLowerCase()} opportunities in ${blueprint['geography']}, between ${_money(minPrice)} and ${_money(maxPrice)}. ${readiness['proof'] == true ? 'Your documentation is progressing well.' : 'Proof of funds is your clearest readiness gap.'}';
}

class _ModuleScaffold extends StatelessWidget {
  const _ModuleScaffold({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.currentStep,
    required this.onStepSelected,
  });
  final String kicker, title, subtitle;
  final Widget child;
  final int currentStep;
  final ValueChanged<int> onStepSelected;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      backgroundColor: _ink,
      foregroundColor: Colors.white,
      title: const HomeBrandButton(size: 38, dark: true),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business),
        SizedBox(width: 12),
      ],
    ),
    body: TopoBackground(
      color: _paper,
      opacity: .055,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 80),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcquisitionStepBar(
                  currentStep: currentStep,
                  onSelected: onStepSelected,
                ),
                const SizedBox(height: 34),
                Text(
                  kicker,
                  style: const TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, height: 1.5),
                ),
                const SizedBox(height: 30),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.unit});
  final String label;
  final String? unit;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE2E2EA),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (unit != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF292944),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                unit!,
                style: const TextStyle(
                  color: _lilac,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.number,
    required this.title,
    required this.children,
  });
  final String number, title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              child: Text(number),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Divider(height: 32, color: _line),
        LayoutBuilder(
          builder: (_, box) => Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final child in children)
                SizedBox(
                  width: box.maxWidth >= 680
                      ? (box.maxWidth - 14) / 2
                      : box.maxWidth,
                  child: child,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NorthStar extends StatelessWidget {
  const _NorthStar({required this.value});
  final AcquisitionFoundation value;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF181033), Color(0xFF0D0D20)],
      ),
      border: Border.all(color: Color(0xFF392A78)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR NORTH STAR',
          style: TextStyle(color: _lime, fontSize: 9, letterSpacing: 1.3),
        ),
        const SizedBox(height: 7),
        Text(
          '${value.blueprint['type']}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${value.blueprint['geography']} · ${_money(value.minPrice)}–${_money(value.maxPrice)} · ${value.blueprint['involvement']}',
          style: const TextStyle(color: Color(0xFFB8CEC3), fontSize: 11),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.note,
    required this.onTap,
  });
  final double width;
  final String label, value, note;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: width,
      height: 155,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(note, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.number,
    required this.title,
    required this.copy,
    required this.action,
    required this.onTap,
  });
  final String number, title, copy, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    color: _surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: _line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF241A4E),
              foregroundColor: _lilac,
              child: Text(number),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              action,
              style: const TextStyle(
                color: _green,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GuideBanner extends StatelessWidget {
  const _GuideBanner({required this.summary, required this.onTap});
  final String summary;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF211648), Color(0xFF101024)],
      ),
      border: Border.all(color: Color(0xFF3A2B79)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          child: Icon(Icons.auto_awesome_rounded),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR ACQUISITION GUIDE',
                style: TextStyle(
                  color: _green,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(summary, style: const TextStyle(color: _muted, height: 1.4)),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text('Talk through my plan →'),
        ),
      ],
    ),
  );
}

class _ReadinessSummary extends StatelessWidget {
  const _ReadinessSummary({required this.value});
  final AcquisitionFoundation value;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _ink,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Wrap(
      spacing: 42,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OVERALL READINESS',
              style: TextStyle(color: _lime, fontSize: 9, letterSpacing: 1),
            ),
            Text(
              '${value.readinessScore}/100',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INDICATIVE CAPACITY',
              style: TextStyle(color: _lime, fontSize: 9, letterSpacing: 1),
            ),
            Text(
              _money(value.capacity),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

String _money(num value) =>
    '\$${value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';
String _compactMoney(num value) => value >= 1000000
    ? '\$${(value / 1000000).toStringAsFixed(1)}M'
    : '\$${(value / 1000).round()}K';
