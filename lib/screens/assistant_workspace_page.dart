import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/platform_side.dart';
import '../widgets/home_brand_button.dart';
import 'local_network_page.dart';
import 'member_workspace_pages.dart';
import '../services/backend_service.dart';
import '../services/consulting_service.dart';
import 'business_acquisition_page.dart';

const ink = Color(0xFF050510),
    surface = Color(0xFF121225),
    purple = Color(0xFF7657FF),
    lilac = Color(0xFFBCAEFF),
    line = Color(0xFF2B2B49),
    muted = Color(0xFFA5A5B5);

class GuideWorkspacePage extends StatefulWidget {
  const GuideWorkspacePage({super.key, required this.foundationSummary});
  final String foundationSummary;
  @override
  State<GuideWorkspacePage> createState() => _GuideWorkspacePageState();
}

class _GuideWorkspacePageState extends State<GuideWorkspacePage> {
  final input = TextEditingController(), scroll = ScrollController();
  List<Map<String, String>> messages = [];
  String? thinking;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance(),
        raw = p.getString('guide_conversation_v2');
    if (raw != null)
      messages = (jsonDecode(raw) as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    if (messages.isEmpty)
      messages = [
        {
          'role': 'assistant',
          'text':
              'I’m your DwellingIQ acquisition strategist. I remember this workspace across visits. Before I recommend anything, what does a successful acquisition need to change in your life or business?',
        },
      ];
    if (mounted) setState(() {});
  }

  Future<void> _save() async => (await SharedPreferences.getInstance())
      .setString('guide_conversation_v2', jsonEncode(messages));

  Future<void> _applyToBlueprint() async {
    final userNotes = messages
        .where((m) => m['role'] == 'user')
        .map((m) => m['text'])
        .join(' · ');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('acquisition_foundation_v1');
    if (raw == null || userNotes.isEmpty) {
      await _send('Help me fill out my business acquisition Blueprint.');
      return;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final blueprint = Map<String, dynamic>.from(data['blueprint'] as Map);
    blueprint['stretch'] = 'AI working context: $userNotes';
    data['blueprint'] = blueprint;
    await prefs.setString('acquisition_foundation_v1', jsonEncode(data));
    setState(
      () => messages.add({
        'role': 'assistant',
        'text':
            'I applied your remembered goals and constraints to the Blueprint working context. Open Blueprint to review and approve the exact fields before screening deals.',
      }),
    );
    await _save();
  }

  Future<void> _send([String? value]) async {
    final text = (value ?? input.text).trim();
    if (text.isEmpty || thinking != null) return;
    setState(() {
      messages.add({'role': 'user', 'text': text});
      input.clear();
      thinking = 'Reading your saved goals and readiness profile';
    });
    await _save();
    for (final step in [
      'Connecting this to your deal history',
      'Building a useful next action',
    ]) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => thinking = step);
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final count = messages.where((m) => m['role'] == 'user').length,
        low = text.toLowerCase();
    String answer;
    if (count == 1) {
      answer =
          'I saved that as your primary outcome. What must remain protected while you pursue it—cash reserves, family time, current income, or reputation?';
    } else if (count == 2) {
      answer =
          'Understood. I’ll treat that as a hard constraint. Which role fits you after close: daily operator, strategic owner, or investor with a hired manager?';
    } else if (low.contains('calendar') || low.contains('plan')) {
      answer =
          'I can build a 90-day plan in your acquisition calendar. Open Calendar from the tool panel and generate the staged plan.';
    } else if (low.contains('newsletter')) {
      answer =
          'Open Newsletter Studio below. It uses the member workflow to generate a reviewable local update; nothing is sent automatically.';
    } else if (low.contains('email') || low.contains('marketing')) {
      answer =
          'Open Email Studio below. It turns acquisition or client context into a polished draft that you approve before use.';
    } else {
      answer =
          'I remember what you told me and I’m connecting it to your foundation: ${widget.foundationSummary} I’ll use those constraints in future answers instead of restarting the interview.';
    }
    setState(() {
      messages.add({'role': 'assistant', 'text': answer});
      thinking = null;
    });
    await _save();
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ink,
    appBar: AppBar(
      backgroundColor: ink,
      foregroundColor: Colors.white,
      title: const HomeBrandButton(size: 38, dark: true),
      actions: [
        IconButton(
          tooltip: 'New conversation',
          onPressed: () async {
            (await SharedPreferences.getInstance()).remove(
              'guide_conversation_v2',
            );
            messages = [];
            await _load();
          },
          icon: const Icon(Icons.edit_square),
        ),
      ],
    ),
    body: Row(
      children: [
        if (MediaQuery.sizeOf(context).width >= 940)
          Container(
            width: 260,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CREATE & ACT',
                  style: TextStyle(
                    color: lilac,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _tool(
                  Icons.fact_check_outlined,
                  'Fill my Blueprint',
                  _applyToBlueprint,
                ),
                _tool(
                  Icons.calendar_month_outlined,
                  'Acquisition calendar',
                  () => _open(const PersonalizedCalendarPage()),
                ),
                _tool(
                  Icons.workspace_premium_outlined,
                  'Member Studio',
                  () => _open(const MemberStudioPage()),
                ),
                _tool(
                  Icons.auto_fix_high_outlined,
                  'Business acquisition tool',
                  () => _open(const BusinessAcquisitionPage()),
                ),
                _tool(
                  Icons.groups_outlined,
                  'Members & experts',
                  () => _open(
                    const LocalNetworkPage(side: PlatformSide.business),
                  ),
                ),
                _tool(
                  Icons.support_agent,
                  'Personal consulting',
                  () => _open(const PersonalizedConsultingPage()),
                ),
                const Spacer(),
                const Text(
                  'DwellingIQ creates drafts and plans. You approve every external action.',
                  style: TextStyle(color: muted, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(24, 42, 24, 20),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: lilac,
                              size: 30,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Acquisition Intelligence',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'One memory across your Blueprint, deals, calendar, and member workspace.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted),
                            ),
                            const SizedBox(height: 38),
                            for (final m in messages)
                              _message(m['role'] == 'assistant', m['text']!),
                            if (thinking != null)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: lilac,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    thinking!,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _composer(),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _tool(IconData i, String t, VoidCallback f) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 5),
    leading: Icon(i, color: lilac),
    title: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
    onTap: f,
  );
  Widget _message(bool ai, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 25),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: ai ? purple : const Color(0xFF303044),
          child: Icon(
            ai ? Icons.auto_awesome : Icons.person,
            color: Colors.white,
            size: 15,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ai ? 'DWELLINGIQ' : 'YOU',
                style: TextStyle(
                  color: ai ? lilac : muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _composer() => SafeArea(
    top: false,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 830),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 7, 6),
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    onSubmitted: _send,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ask, plan, or create something…',
                      hintStyle: TextStyle(color: muted),
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: purple),
                  onPressed: thinking == null ? _send : null,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PersonalizedCalendarPage extends StatefulWidget {
  const PersonalizedCalendarPage({super.key});
  @override
  State<PersonalizedCalendarPage> createState() => _CalendarState();
}

class _CalendarState extends State<PersonalizedCalendarPage> {
  List<Map<String, String>> events = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = (await SharedPreferences.getInstance()).getString(
      'acquisition_calendar_v1',
    );
    if (r != null)
      events = (jsonDecode(r) as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    if (mounted) setState(() {});
  }

  Future<void> _save() async => (await SharedPreferences.getInstance())
      .setString('acquisition_calendar_v1', jsonEncode(events));
  Future<void> _plan() async {
    final n = DateTime.now();
    events =
        [
              ('Refine acquisition Blueprint', 2),
              ('Prepare lender package', 10),
              ('Begin weekly opportunity review', 21),
              ('Review first deal shortlist', 45),
              ('90-day strategy checkpoint', 90),
            ]
            .map(
              (e) => {
                'title': e.$1,
                'date': n.add(Duration(days: e.$2)).toIso8601String(),
              },
            )
            .toList();
    await _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'Acquisition calendar',
    subtitle:
        'A personalized working plan. Google or Outlook sync requires a connected account.',
    action: FilledButton.icon(
      onPressed: _plan,
      icon: const Icon(Icons.auto_awesome),
      label: const Text('Build my 90-day plan'),
    ),
    child: events.isEmpty
        ? const _Empty('No plan yet. Ask the Guide to build one.')
        : Column(
            children: [
              for (var i = 0; i < events.length; i++)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: surface,
                    foregroundColor: lilac,
                    child: Text('${i + 1}'),
                  ),
                  title: Text(
                    events[i]['title']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    DateFormat.yMMMd().format(
                      DateTime.parse(events[i]['date']!),
                    ),
                    style: const TextStyle(color: muted),
                  ),
                  trailing: IconButton(
                    onPressed: () async {
                      events.removeAt(i);
                      await _save();
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete_outline, color: muted),
                  ),
                ),
            ],
          ),
  );
}

class PersonalizedConsultingPage extends StatefulWidget {
  const PersonalizedConsultingPage({super.key});
  @override
  State<PersonalizedConsultingPage> createState() => _ConsultingState();
}

class _ConsultingState extends State<PersonalizedConsultingPage> {
  final phone = TextEditingController(),
      outcome = TextEditingController(),
      challenge = TextEditingController();
  String format = 'Acquisition strategy session';
  bool sending = false, sent = false;
  Future<void> _submit() async {
    if (outcome.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      await ConsultingService.request(
        format: format,
        phone: phone.text,
        outcome: outcome.text,
        challenge: challenge.text,
      );
      if (mounted) setState(() => sent = true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'Founder-led acquisition consulting',
    subtitle:
        'Focused support for buyers who need judgment, structure, and an accountable next step—not another generic report.',
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOUNDER PROFILE',
                style: TextStyle(
                  color: lilac,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Product, decision systems & acquisition support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'The founder of DwellingIQ combines product development, transparent financial modelling, buyer-first acquisition frameworks, and AI-assisted decision tools. Consulting is designed for business buyers who need help defining a mandate, preparing for financing, screening a live deal, or organizing diligence.',
                style: TextStyle(color: muted, height: 1.6),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  Chip(label: Text('Acquisition Blueprint')),
                  Chip(label: Text('Buyer readiness')),
                  Chip(label: Text('Deal screening')),
                  Chip(label: Text('Diligence planning')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF251950), Color(0xFF121225)],
            ),
            border: Border.all(color: purple),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Tell us where you need support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: format,
                dropdownColor: surface,
                items:
                    [
                          'Acquisition strategy session',
                          'Readiness and financing review',
                          'Live deal decision review',
                          'Diligence planning',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => format = v!,
                decoration: const InputDecoration(
                  labelText: 'Consulting focus',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: outcome,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'What outcome do you need?',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: challenge,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'What is making the decision difficult?',
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: sent ? const Color(0xFF2E9D71) : purple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 18,
                  ),
                ),
                onPressed: sent || sending ? null : _submit,
                icon: Icon(sent ? Icons.check : Icons.support_agent),
                label: Text(
                  sent
                      ? 'Sent!'
                      : sending
                      ? 'Sending…'
                      : 'I Want Support!',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                BackendService.user == null
                    ? 'Sign in first so your verified email can be included.'
                    : 'Your signed-in email and the details above will be sent securely to the founder.',
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class MemberStudioPage extends StatelessWidget {
  const MemberStudioPage({super.key});
  void _open(BuildContext c, Widget p) =>
      Navigator.push(c, MaterialPageRoute<void>(builder: (_) => p));
  @override
  Widget build(BuildContext context) => _Page(
    title: 'Member Studio',
    subtitle:
        'The umbrella workspace for member growth, client service, content, leads, and professional connections.',
    child: LayoutBuilder(
      builder: (context, box) => Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          _studio(
            box,
            'AI email composer',
            'Create a reviewable client or acquisition email.',
            Icons.mail_outline,
            () => _open(context, const MemberEmailComposerPage()),
          ),
          _studio(
            box,
            'Newsletter builder',
            'Generate a useful local update for your audience.',
            Icons.newspaper_outlined,
            () => _open(context, const MemberNewsletterBuilderPage()),
          ),
          _studio(
            box,
            'Lead inbox',
            'Manage consented introductions and opportunities.',
            Icons.inbox_outlined,
            () => _open(context, const MemberLeadInboxPage()),
          ),
          _studio(
            box,
            'Members & experts',
            'Find realtors, lenders, lawyers, accountants and advisors.',
            Icons.groups_outlined,
            () => _open(
              context,
              const LocalNetworkPage(side: PlatformSide.business),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _studio(
    BoxConstraints b,
    String t,
    String d,
    IconData i,
    VoidCallback f,
  ) => SizedBox(
    width: b.maxWidth > 700 ? (b.maxWidth - 14) / 2 : b.maxWidth,
    child: InkWell(
      onTap: f,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 190,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(i, color: lilac, size: 30),
            const Spacer(),
            Text(
              t,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(d, style: const TextStyle(color: muted, height: 1.4)),
          ],
        ),
      ),
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });
  final String title, subtitle;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ink,
    appBar: AppBar(
      backgroundColor: ink,
      foregroundColor: Colors.white,
      title: const HomeBrandButton(size: 38, dark: true),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(subtitle, style: const TextStyle(color: muted, height: 1.5)),
              if (action != null) ...[const SizedBox(height: 18), action!],
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(48),
    decoration: BoxDecoration(
      color: surface,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: muted),
    ),
  );
}
