import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/account_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/profile_photo.dart';
import '../widgets/topo_background.dart';
import 'profile_page.dart';

const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);
const _lilac = Color(0xFFBCAEFF);

class ConnectionBriefPage extends StatefulWidget {
  const ConnectionBriefPage({
    super.key,
    required this.provider,
    this.initialContext = '',
  });

  final MarketplaceProvider provider;
  final String initialContext;

  @override
  State<ConnectionBriefPage> createState() => _ConnectionBriefPageState();
}

class _ConnectionBriefPageState extends State<ConnectionBriefPage> {
  late final TextEditingController _location;
  late final TextEditingController _context;
  final _phone = TextEditingController();
  final _budget = TextEditingController();
  int _step = 0;
  bool _sending = false;
  bool _complete = false;
  bool _sharePhone = false;
  String _help = '';
  String _stage = 'Exploring options';
  String _timeline = '1–3 months';
  String _contact = 'email';

  MarketplaceProvider get provider => widget.provider;
  bool get _business => provider.category.side == PlatformSide.business;

  @override
  void initState() {
    super.initState();
    _location = TextEditingController();
    _context = TextEditingController(text: widget.initialContext);
    _help = _helpOptions.first;
  }

  @override
  void dispose() {
    _location.dispose();
    _context.dispose();
    _phone.dispose();
    _budget.dispose();
    super.dispose();
  }

  List<String> get _helpOptions => _business
      ? const [
          'Evaluate the opportunity',
          'Financing and deal structure',
          'Legal or tax diligence',
          'Quality of earnings',
          'Negotiation and closing',
        ]
      : const [
          'Understand affordability',
          'Financing or pre-approval',
          'Property and offer strategy',
          'Legal or tax questions',
          'Due diligence and closing',
        ];

  String get _brief {
    final lines = <String>[
      'Connection brief',
      'Help requested: $_help',
      'Current stage: $_stage',
      'Timeline: $_timeline',
      if (_location.text.trim().isNotEmpty)
        '${_business ? 'Target market' : 'Property location'}: ${_location.text.trim()}',
      if (_budget.text.trim().isNotEmpty)
        '${_business ? 'Approximate deal size' : 'Approximate budget'}: ${_budget.text.trim()}',
      if (_context.text.trim().isNotEmpty)
        'Buyer context: ${_context.text.trim()}',
      'Preferred contact: ${_contact == 'phone' ? 'Phone' : 'Email'}',
    ];
    return lines.join('\n');
  }

  bool get _canContinue => switch (_step) {
    0 => _help.isNotEmpty,
    1 => _context.text.trim().isNotEmpty,
    _ => !_sharePhone || _phone.text.trim().isNotEmpty,
  };

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await AccountService.requestIntroduction(
        provider: provider,
        propertySummary: _brief,
        phone: _sharePhone ? _phone.text : '',
        preferredContact: _contact,
        leadType: _business ? 'business_acquisition' : 'property_purchase',
      );
      if (mounted) setState(() => _complete = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send the connection brief: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _hero()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: _complete ? _success() : _workspace(),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _hero() => TopoBackground(
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 52),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HomeBrandButton(size: 44),
                    const Spacer(),
                    AppNavigationMenu(side: provider.category.side),
                  ],
                ),
                const SizedBox(height: 48),
                const Text(
                  'PRIVATE CONNECTION BRIEF',
                  style: TextStyle(
                    color: _lilac,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Make the first conversation count.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 45,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Build a clear, consented brief so the professional understands your goal before they contact you.',
                  style: TextStyle(
                    color: Color(0xFFB8B8C5),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _workspace() => Column(
    children: [
      _professionalStrip(),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE0E0E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _progress(),
            const SizedBox(height: 30),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (_step) {
                0 => _goalStep(),
                1 => _contextStep(),
                _ => _reviewStep(),
              },
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: _sending ? null : () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _sending || !_canContinue
                      ? null
                      : _step < 2
                      ? () => setState(() => _step++)
                      : _submit,
                  icon: Icon(
                    _step < 2
                        ? Icons.arrow_forward_rounded
                        : Icons.lock_outline,
                  ),
                  label: Text(
                    _sending
                        ? 'Sending…'
                        : _step < 2
                        ? 'Continue'
                        : provider.isExample
                        ? 'Complete preview'
                        : 'Send private brief',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _professionalStrip() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFEDE8FF),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        ProfilePhoto(
          size: 58,
          photoUrl: provider.photoUrl,
          exampleIndex: provider.photoIndex,
          borderRadius: BorderRadius.circular(15),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${provider.jobTitle} · ${provider.company}',
                style: const TextStyle(color: Color(0xFF666674), fontSize: 12),
              ),
            ],
          ),
        ),
        if (provider.isExample)
          const Text(
            'PREVIEW',
            style: TextStyle(
              color: _purple,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    ),
  );

  Widget _progress() => Row(
    children: [
      for (var index = 0; index < 3; index++) ...[
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 4,
            decoration: BoxDecoration(
              color: index <= _step ? _purple : const Color(0xFFE2E2E8),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (index < 2) const SizedBox(width: 8),
      ],
    ],
  );

  Widget _goalStep() => Column(
    key: const ValueKey('goal'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _StepTitle('01', 'What outcome do you need?'),
      const SizedBox(height: 18),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          for (final option in _helpOptions)
            ChoiceChip(
              label: Text(option),
              selected: _help == option,
              onSelected: (_) => setState(() => _help = option),
            ),
        ],
      ),
      const SizedBox(height: 22),
      DropdownButtonFormField<String>(
        initialValue: _stage,
        decoration: const InputDecoration(labelText: 'Where are you now?'),
        items:
            const [
                  'Exploring options',
                  'Financing and planning',
                  'Evaluating opportunities',
                  'Preparing an offer or LOI',
                  'Under contract or in diligence',
                  'Closing',
                ]
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
        onChanged: (value) => setState(() => _stage = value!),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _timeline,
        decoration: const InputDecoration(labelText: 'Desired timeline'),
        items:
            const [
                  'As soon as possible',
                  'Within 30 days',
                  '1–3 months',
                  '3+ months',
                ]
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
        onChanged: (value) => setState(() => _timeline = value!),
      ),
    ],
  );

  Widget _contextStep() => Column(
    key: const ValueKey('context'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _StepTitle('02', 'Give them useful context'),
      const SizedBox(height: 8),
      const Text(
        'Do not include confidential seller documents, account numbers or identification.',
        style: TextStyle(color: Color(0xFF6B6B78), fontSize: 12),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: _location,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: _business
              ? 'Target market or industry'
              : 'City or property',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _budget,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: _business ? 'Approximate deal size' : 'Approximate budget',
          hintText: r'Example: $750k–$1M',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _context,
        onChanged: (_) => setState(() {}),
        minLines: 4,
        maxLines: 7,
        decoration: const InputDecoration(
          labelText: 'What should they know before contacting you?',
          hintText:
              'Your goal, constraint, concern and the decision you need help making.',
        ),
      ),
    ],
  );

  Widget _reviewStep() => Column(
    key: const ValueKey('review'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _StepTitle('03', 'Choose contact details and review'),
      const SizedBox(height: 18),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'email',
            label: Text('Email'),
            icon: Icon(Icons.mail_outline),
          ),
          ButtonSegment(
            value: 'phone',
            label: Text('Phone'),
            icon: Icon(Icons.call_outlined),
          ),
        ],
        selected: {_contact},
        onSelectionChanged: (value) => setState(() {
          _contact = value.first;
          if (_contact == 'phone') _sharePhone = true;
        }),
      ),
      const SizedBox(height: 12),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _sharePhone,
        onChanged: (value) => setState(() => _sharePhone = value ?? false),
        title: const Text('Share my phone number'),
        subtitle: const Text(
          'Your account name and email are included automatically.',
        ),
      ),
      if (_sharePhone) ...[
        const SizedBox(height: 8),
        TextField(
          controller: _phone,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number'),
        ),
      ],
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WHAT THE PROFESSIONAL RECEIVES',
              style: TextStyle(
                color: _purple,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(_brief, style: const TextStyle(height: 1.55)),
          ],
        ),
      ),
    ],
  );

  Widget _success() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(34),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE0E0E7)),
    ),
    child: Column(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF16825D), size: 48),
        const SizedBox(height: 16),
        Text(
          provider.isExample
              ? 'Connection preview complete'
              : 'Your brief is on its way',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 9),
        Text(
          provider.isExample
              ? 'Nothing was sent because this is an example profile.'
              : '${provider.name} can now review your goal and respond with a useful next step.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF666674), height: 1.5),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
            (route) => route.isFirst,
          ),
          child: const Text('Track connections in Profile'),
        ),
      ],
    ),
  );
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.number, this.title);
  final String number;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        number,
        style: const TextStyle(
          color: _purple,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
      ),
    ],
  );
}
