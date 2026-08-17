import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/account_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/acquisition_step_bar.dart';
import '../widgets/membership_footer.dart';
import 'auth_page.dart';
import 'business_acquisition_page.dart';
import 'deal_rooms_page.dart';
import 'assistant_workspace_page.dart';

const _ink = Color(0xFF050510);
const _green = Color(0xFF252525);
const _lime = Color(0xFF9B9B98);
const _line = Color(0xFF292944);
const _muted = Color(0xFFA5A5B5);
const _surface = Color(0xFF121225);
const _lilac = Color(0xFF9B9B98);
const _cream = Color(0xFFF4F1EB);

class AcquisitionSupportPage extends StatefulWidget {
  const AcquisitionSupportPage({super.key});

  @override
  State<AcquisitionSupportPage> createState() => _AcquisitionSupportPageState();
}

class _AcquisitionSupportPageState extends State<AcquisitionSupportPage> {
  final _marketingScroll = ScrollController();

  @override
  void dispose() {
    _marketingScroll.dispose();
    super.dispose();
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cream,
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 86,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: const Color(0xFFF7F5F0),
          surfaceTintColor: Colors.transparent,
          title: const HomeBrandButton(size: 66, dark: false),
          actions: [
            OutlinedButton(
              onPressed: () => _open(const AcquisitionBlueprintPage()),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xFFBDB9B2)),
              ),
              child: const Text('START MY PATH'),
            ),
            const SizedBox(width: 8),
            const AppNavigationMenu(side: PlatformSide.business, dark: false),
            const SizedBox(width: 18),
          ],
        ),
        SliverToBoxAdapter(child: _hero()),
        SliverToBoxAdapter(child: _goalStatement()),
        SliverToBoxAdapter(child: _audiences()),
        SliverToBoxAdapter(child: _movingMarketing()),
        SliverToBoxAdapter(child: _path()),
        const SliverToBoxAdapter(child: MembershipFooter()),
      ],
    ),
  );

  Widget _hero() => Container(
    constraints: const BoxConstraints(minHeight: 690),
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/affinity-city-hero.png'),
        fit: BoxFit.cover,
      ),
    ),
    padding: const EdgeInsets.fromLTRB(24, 150, 24, 0),
    alignment: Alignment.bottomCenter,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: 820,
            padding: const EdgeInsets.fromLTRB(44, 42, 44, 46),
            color: const Color(0xF7F7F5F0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BUSINESS ACQUISITION, MADE NAVIGABLE',
                  style: TextStyle(
                    color: Color(0xFF65615C),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.7,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Don’t just find a business.\nKnow what you’re buying into.',
                  style: TextStyle(
                    color: _ink,
                    fontSize: MediaQuery.sizeOf(context).width < 700 ? 44 : 66,
                    height: .96,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -3.4,
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 780,
                  child: Text(
                    'Affinity helps aspiring buyers define the right target, prepare to transact, screen real opportunities, and build the professional team needed to close with confidence.',
                    style: TextStyle(
                      color: Color(0xFF5D5954),
                      fontSize: 17,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _open(const AcquisitionBlueprintPage()),
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 20,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('I WANT TO BUY A BUSINESS'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _open(const MemberStudioPage()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: const BorderSide(color: Color(0xFFAAA69F)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 20,
                        ),
                      ),
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('I PROVIDE PROFESSIONAL SERVICES'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _goalStatement() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 86),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: LayoutBuilder(
          builder: (context, box) {
            const statement = Text(
              'A clearer path from “I want to buy a business” to “this is the right business for me.”',
              style: TextStyle(
                color: _ink,
                fontSize: 42,
                height: 1.08,
                fontWeight: FontWeight.w700,
                letterSpacing: -2.2,
              ),
            );
            const copy = Text(
              'The goal is not more deal flow. It is better judgment: a personal acquisition Blueprint, an honest view of readiness, disciplined screening, and access to specialists when the stakes rise.',
              style: TextStyle(color: Color(0xFF555562), height: 1.65),
            );
            if (box.maxWidth < 720) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [statement, SizedBox(height: 28), copy],
              );
            }
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: statement),
                SizedBox(width: 70),
                Expanded(flex: 4, child: copy),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _audiences() => Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/affinity-reflection-facade.png'),
        fit: BoxFit.cover,
      ),
    ),
    padding: const EdgeInsets.fromLTRB(24, 112, 24, 112),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: LayoutBuilder(
          builder: (context, box) {
            final narrow = box.maxWidth < 760;
            final buyer = _AudienceBlock(
              number: '01',
              eyebrow: 'FOR BUYERS & THE ACQUISITION-CURIOUS',
              title: 'Turn interest into a mandate.',
              copy:
                  'Learn the path, define what fits your life and capital, measure your readiness, and screen opportunities against your own rules.',
              action: 'BUILD MY BLUEPRINT',
              onTap: () => _open(const AcquisitionBlueprintPage()),
            );
            final member = _AudienceBlock(
              number: '02',
              eyebrow: 'FOR PROFESSIONAL MEMBERS',
              title: 'Be visible when buyers need you.',
              copy:
                  'Create a credible professional presence inside the Member Studio so acquisition buyers can understand your expertise and engage your services.',
              action: 'EXPLORE MEMBER STUDIO',
              onTap: () => _open(const MemberStudioPage()),
            );
            return narrow
                ? Column(children: [buyer, const SizedBox(height: 18), member])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: buyer),
                      const SizedBox(width: 18),
                      Expanded(child: member),
                    ],
                  );
          },
        ),
      ),
    ),
  );

  Widget _movingMarketing() {
    const stories = [
      (
        'DEFINE',
        'Build a buyer-first acquisition Blueprint.',
        'Set the industries, geography, price range, role, return expectations, and hard limits that define a viable target.',
        Icons.explore_outlined,
      ),
      (
        'PREPARE',
        'Know what must be true before you transact.',
        'Organize capital, reserves, documentation, operating credibility, and lender conversations into an honest readiness view.',
        Icons.verified_user_outlined,
      ),
      (
        'SCREEN',
        'Pressure-test the deal—not your hopes.',
        'Normalize earnings, account for owner pay and working capital, test debt, and expose missing evidence before an offer.',
        Icons.query_stats_outlined,
      ),
      (
        'CONNECT',
        'Bring in the right expertise at the right moment.',
        'Find member professionals whose services match the financing, legal, diligence, tax, risk, and transition work ahead.',
        Icons.hub_outlined,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'WHAT AFFINITY MOVES FORWARD',
              style: TextStyle(
                color: Color(0xFF66615B),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 310,
            child: ListView.separated(
              controller: _marketingScroll,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (_, index) {
                final story = stories[index];
                return _MovingMarketingCard(
                  eyebrow: story.$1,
                  title: story.$2,
                  copy: story.$3,
                  icon: story.$4,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _path() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 82, 24, 88),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THE BUYER PATH',
              style: TextStyle(
                color: _green,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Four steps. One clearer decision.',
              style: TextStyle(
                color: _ink,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                letterSpacing: -2.2,
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HomePathStep('01', 'Blueprint', 'Define the target.', () {
                  _open(const AcquisitionBlueprintPage());
                }),
                _HomePathStep('02', 'Readiness', 'Prepare the buyer.', () {
                  _open(const BuyerReadinessPage());
                }),
                _HomePathStep('03', 'Deal screen', 'Test the opportunity.', () {
                  _open(const BusinessAcquisitionPage());
                }),
                _HomePathStep('04', 'Pipeline', 'Manage what advances.', () {
                  _open(
                    const DealRoomsPage(initialSide: PlatformSide.business),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AudienceBlock extends StatelessWidget {
  const _AudienceBlock({
    required this.number,
    required this.eyebrow,
    required this.title,
    required this.copy,
    required this.action,
    required this.onTap,
  });
  final String number, eyebrow, title, copy, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 430),
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 40,
          offset: Offset(0, 20),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: _green,
            fontSize: 56,
            height: 1,
            fontWeight: FontWeight.w300,
          ),
        ),
        const Spacer(),
        Text(
          eyebrow,
          style: const TextStyle(
            color: _green,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 11),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 31,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          copy,
          style: const TextStyle(color: Color(0xFF555562), height: 1.55),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: _ink),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward),
          label: Text(action),
        ),
      ],
    ),
  );
}

class _MovingMarketingCard extends StatelessWidget {
  const _MovingMarketingCard({
    required this.eyebrow,
    required this.title,
    required this.copy,
    required this.icon,
  });
  final String eyebrow, title, copy;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.sizeOf(context).width < 520 ? 300 : 370,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _green, size: 30),
            const Spacer(),
            Text(
              eyebrow,
              style: const TextStyle(
                color: _green,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 26,
            height: 1.06,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          copy,
          style: const TextStyle(color: Color(0xFF555562), height: 1.5),
        ),
      ],
    ),
  );
}

class _HomePathStep extends StatelessWidget {
  const _HomePathStep(this.number, this.title, this.copy, this.onTap);
  final String number, title, copy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 620 ? double.infinity : 260,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 21),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFCDCDD4))),
        ),
        child: Row(
          children: [
            Text(
              number,
              style: const TextStyle(
                color: _green,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(copy, style: const TextStyle(color: Color(0xFF777783))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: _ink, size: 18),
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
  int _chapter = 0;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'QUESTION ${_chapter + 1} OF 4',
                    style: const TextStyle(
                      color: _lime,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((_chapter + 1) / 4 * 100).round()}%',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_chapter + 1) / 4,
                minHeight: 3,
                color: _green,
                backgroundColor: _line,
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: KeyedSubtree(
                  key: ValueKey(_chapter),
                  child: _chapterBody(),
                ),
              ),
              const SizedBox(height: 22),
              _chapterActions(),
            ],
          ),
  );

  Widget _chapterBody() => switch (_chapter) {
    0 => _GuidedQuestion(
      title: 'What kind of owner do you want to become?',
      copy:
          'Start with the role and structure—not a price. You can revise this as your search becomes clearer.',
      children: [
        _dropdown('type', 'Acquisition structure', const [
          'Business acquisition',
          'Asset purchase',
          'Share purchase',
          'I’m not sure yet',
        ]),
        _dropdown('involvement', 'Your preferred role', const [
          'Owner-operator',
          'Strategic owner',
          'Investor with manager',
          'I’m not sure yet',
        ]),
      ],
    ),
    1 => _GuidedQuestion(
      title: 'What would feel like a natural fit?',
      copy:
          'Use plain language. A broad answer is useful; “local service businesses” is enough to begin.',
      children: [
        _input(
          'geography',
          'Where would you consider buying?',
          hint: 'A city, province, region, or remote',
        ),
        _input(
          'industries',
          'What businesses interest you?',
          hint: 'Industries, business models, or simply “open to ideas”',
        ),
      ],
    ),
    2 => _GuidedQuestion(
      title: 'Do you know your financial range?',
      copy:
          'These figures are optional planning estimates—not a test or lending approval. Leave them blank if you are still learning.',
      children: [
        _input(
          'minPrice',
          'Lower purchase range',
          unit: r'$ CAD',
          hint: 'Optional',
        ),
        _input(
          'maxPrice',
          'Upper purchase range',
          unit: r'$ CAD',
          hint: 'Optional',
        ),
        _input(
          'minReturn',
          'Minimum return or earnings yield',
          unit: '%',
          hint: 'Optional',
        ),
      ],
    ),
    _ => _GuidedQuestion(
      title: 'What should protect you from the wrong deal?',
      copy:
          'Name the risks you already know you do not want. If nothing comes to mind, uncertainty is a valid answer.',
      children: [
        _input(
          'limits',
          'Non-negotiables',
          hint: 'Examples: no turnaround, no heavy travel—or “not sure yet”',
          maxLines: 3,
        ),
        _input(
          'stretch',
          'Where could you be flexible?',
          hint: 'Optional',
          maxLines: 3,
        ),
      ],
    ),
  };

  Widget _chapterActions() => Row(
    children: [
      if (_chapter > 0)
        TextButton.icon(
          onPressed: () => setState(() => _chapter--),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
      const Spacer(),
      if (_chapter == 2)
        TextButton(
          onPressed: () {
            controllers['minPrice']?.clear();
            controllers['maxPrice']?.clear();
            controllers['minReturn']?.clear();
            setState(() => _chapter++);
          },
          child: const Text('I DON’T KNOW YET'),
        ),
      const SizedBox(width: 10),
      FilledButton.icon(
        onPressed: _chapter < 3
            ? () async {
                await _updateDraft();
                if (mounted) setState(() => _chapter++);
              }
            : _save,
        icon: Icon(_chapter < 3 ? Icons.arrow_forward : Icons.check_rounded),
        label: Text(_chapter < 3 ? 'CONTINUE' : 'SAVE BLUEPRINT'),
      ),
    ],
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
    labelColor: _ink,
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
      labelColor: _ink,
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
  int _stage = 0;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MOMENT ${_stage + 1} OF 3',
                      style: const TextStyle(
                        color: _lime,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${((_stage + 1) / 3 * 100).round()}%',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (_stage + 1) / 3,
                  minHeight: 3,
                  color: _green,
                  backgroundColor: _line,
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: KeyedSubtree(
                    key: ValueKey(_stage),
                    child: _readinessMoment(current),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    if (_stage > 0)
                      TextButton.icon(
                        onPressed: () => setState(() => _stage--),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _stage < 2
                          ? () async {
                              await _updateDraft();
                              if (mounted) setState(() => _stage++);
                            }
                          : _save,
                      icon: Icon(
                        _stage < 2 ? Icons.arrow_forward : Icons.check_rounded,
                      ),
                      label: Text(_stage < 2 ? 'CONTINUE' : 'SAVE READINESS'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _readinessMoment(AcquisitionFoundation current) => switch (_stage) {
    0 => _GuidedQuestion(
      title: 'What capital could be available?',
      copy:
          'A rough range is enough. Leave every field blank if you have not had this conversation yet.',
      children: [
        _readinessInput('equity', 'Cash or equity you might use'),
        _readinessInput('reserves', 'Capital you want untouched after closing'),
      ],
    ),
    1 => _GuidedQuestion(
      title: 'What supports the acquisition?',
      copy:
          'These answers help frame—not approve—your capacity. “I’m not sure yet” is included on purpose.',
      children: [
        _readinessInput('income', 'Annual supporting income'),
        _LabeledField(
          label: 'How would you describe your credit?',
          labelColor: _ink,
          child: DropdownButtonFormField<String>(
            initialValue:
                const [
                  'Excellent',
                  'Good',
                  'Fair',
                  'Needs work',
                  'I’m not sure yet',
                ].contains(controllers['credit']?.text)
                ? controllers['credit']!.text
                : null,
            hint: const Text('Choose what feels closest'),
            items:
                const [
                      'Excellent',
                      'Good',
                      'Fair',
                      'Needs work',
                      'I’m not sure yet',
                    ]
                    .map(
                      (option) =>
                          DropdownMenuItem(value: option, child: Text(option)),
                    )
                    .toList(),
            onChanged: (selected) =>
                controllers['credit']?.text = selected ?? '',
          ),
        ),
      ],
    ),
    _ => _GuidedQuestion(
      title: 'What is already in motion?',
      copy:
          'This is a planning checklist, not homework you must finish today. Select only what is genuinely underway.',
      children: [
        for (final item in const {
          'proof': 'Proof of funds',
          'tax': 'Tax returns or financial statements',
          'resume': 'Buyer résumé or operating story',
          'entity': 'Acquisition entity information',
          'lender': 'An introductory lender conversation',
        }.entries)
          CheckboxListTile(
            value: current.readiness[item.key] == true,
            title: Text(item.value),
            activeColor: _green,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (checked) =>
                setState(() => current.readiness[item.key] = checked == true),
          ),
      ],
    ),
  };

  Widget _readinessInput(String key, String label) => _LabeledField(
    label: label,
    labelColor: _ink,
    unit: r'$ CAD',
    child: TextField(
      controller: controllers[key],
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(hintText: 'Optional estimate'),
    ),
  );
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
    backgroundColor: _cream,
    appBar: AppBar(
      toolbarHeight: 78,
      backgroundColor: const Color(0xFFF7F5F0),
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      title: const HomeBrandButton(size: 58, dark: false),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business, dark: false),
        SizedBox(width: 12),
      ],
    ),
    body: Container(
      decoration: BoxDecoration(
        color: _cream,
        image: DecorationImage(
          image: const AssetImage(
            'assets/images/affinity-reflection-facade.png',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            _cream.withValues(alpha: .9),
            BlendMode.srcOver,
          ),
        ),
      ),
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
                    color: Color(0xFF625E58),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF5F5B56), height: 1.5),
                ),
                const SizedBox(height: 30),
                child,
                const SizedBox(height: 42),
                const MembershipFooter(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.unit,
    this.labelColor = const Color(0xFFE2E2EA),
  });
  final String label;
  final String? unit;
  final Color labelColor;
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
              style: TextStyle(
                color: labelColor,
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

class _GuidedQuestion extends StatelessWidget {
  const _GuidedQuestion({
    required this.title,
    required this.copy,
    required this.children,
  });

  final String title;
  final String copy;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          copy,
          style: const TextStyle(color: Color(0xFF626270), height: 1.55),
        ),
        const SizedBox(height: 28),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF4F6FA),
              hintStyle: const TextStyle(color: Color(0xFF898995)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD8DDE8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD8DDE8)),
              ),
            ),
            textTheme: Theme.of(
              context,
            ).textTheme.apply(bodyColor: _ink, displayColor: _ink),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: _ink),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

String _money(num value) =>
    '\$${value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';
