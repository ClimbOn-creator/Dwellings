import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/platform_side.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/topo_background.dart';
import '../widgets/membership_footer.dart';
import 'local_network_page.dart';
import 'member_workspace_pages.dart';
import '../services/backend_service.dart';
import '../services/calendar_sync_service.dart';
import '../services/consulting_service.dart';
import 'business_acquisition_page.dart';
import 'deal_rooms_page.dart';
import 'profile_page.dart';

const ink = Color(0xFF171717),
    surface = Color(0xFFFCFBF8),
    purple = Color(0xFF252525),
    lilac = Color(0xFF9B9B98),
    line = Color(0xFFD6D1C9),
    muted = Color(0xFF68635D);

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
              'I’m your Affinity acquisition strategist. I remember this workspace across visits. Before I recommend anything, what does a successful acquisition need to change in your life or business?',
        },
      ];
    if (mounted) setState(() {});
  }

  Future<void> _save() async => (await SharedPreferences.getInstance())
      .setString('guide_conversation_v2', jsonEncode(messages));

  Future<void> _applyToBlueprint() async {
    await _send(
      'Use everything you remember about me to help complete my business acquisition Blueprint. Only propose fields supported by what I have told you, and ask me for the most important missing fact.',
    );
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
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      messages.add({
        'role': 'assistant',
        'text':
            'For the MVP, use the structured Blueprint, Readiness, Deal Screen, calendar, and consulting tools. Your saved foundation is: ${widget.foundationSummary}',
      });
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
        const AppNavigationMenu(side: PlatformSide.business),
        const SizedBox(width: 12),
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
                  'Affinity creates drafts and plans. You approve every external action.',
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
                              'Acquisition workspace',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Structured tools for your Blueprint, deals, calendar, and member workspace.',
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
                style: const TextStyle(color: ink, fontSize: 15, height: 1.55),
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
  Set<String> connections = {};
  bool loadingConnections = false;
  @override
  void initState() {
    super.initState();
    _load();
    _refreshConnections();
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

  Future<void> _refreshConnections() async {
    if (BackendService.user == null) return;
    setState(() => loadingConnections = true);
    try {
      connections = await CalendarSyncService.connections();
    } catch (_) {
      connections = {};
    } finally {
      if (mounted) setState(() => loadingConnections = false);
    }
  }

  Future<void> _connect(String provider) async {
    try {
      await CalendarSyncService.connect(provider);
    } catch (error) {
      _notice('$error');
    }
  }

  Future<void> _sync(int index, String provider) async {
    try {
      final event = events[index];
      final result = await CalendarSyncService.syncEvent(
        provider: provider,
        title: event['title']!,
        start: DateTime.parse(event['date']!),
        externalId: event['${provider}Id'],
      );
      event['${provider}Id'] = result['external_id']!;
      await _save();
      if (mounted) setState(() {});
      _notice(
        '${provider == 'google' ? 'Google Calendar' : 'Outlook'} synced.',
      );
    } catch (error) {
      _notice('$error');
    }
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Bad state: ', ''))),
    );
  }

  Future<void> _edit(int index) async {
    final title = TextEditingController(text: events[index]['title']);
    final current = DateTime.parse(events[index]['date']!);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        title: const Text(
          'Edit calendar item',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, title.text.trim()),
            child: const Text('Choose date'),
          ),
        ],
      ),
    );
    title.dispose();
    if (newTitle == null || newTitle.isEmpty || !mounted) return;
    final newDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (newDate == null) return;
    events[index]['title'] = newTitle;
    events[index]['date'] = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      current.hour,
      current.minute,
    ).toIso8601String();
    await _save();
    setState(() {});
  }

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
    action: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: _plan,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Build my 90-day plan'),
        ),
        OutlinedButton.icon(
          onPressed: () => _connect('google'),
          icon: Icon(
            connections.contains('google')
                ? Icons.check_circle
                : Icons.add_link,
          ),
          label: Text(
            connections.contains('google')
                ? 'Google connected'
                : 'Connect Google',
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _connect('outlook'),
          icon: Icon(
            connections.contains('outlook')
                ? Icons.check_circle
                : Icons.add_link,
          ),
          label: Text(
            connections.contains('outlook')
                ? 'Outlook connected'
                : 'Connect Outlook',
          ),
        ),
        IconButton(
          tooltip: 'Refresh connections',
          onPressed: loadingConnections ? null : _refreshConnections,
          icon: loadingConnections
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
      ],
    ),
    child: events.isEmpty
        ? const _Empty('No plan yet. Build a 90-day plan to get started.')
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
                  trailing: Wrap(
                    children: [
                      PopupMenuButton<String>(
                        tooltip: 'Sync calendar item',
                        icon: const Icon(Icons.sync, color: lilac),
                        onSelected: (provider) => _sync(i, provider),
                        itemBuilder: (_) => [
                          for (final provider in ['google', 'outlook'])
                            PopupMenuItem(
                              value: provider,
                              enabled: connections.contains(provider),
                              child: Text(
                                '${events[i]['${provider}Id']?.isNotEmpty == true ? 'Update' : 'Add to'} ${provider == 'google' ? 'Google Calendar' : 'Outlook'}',
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _edit(i),
                        icon: const Icon(Icons.edit_outlined, color: muted),
                      ),
                      IconButton(
                        tooltip: 'Delete local item',
                        onPressed: () async {
                          events.removeAt(i);
                          await _save();
                          setState(() {});
                        },
                        icon: const Icon(Icons.delete_outline, color: muted),
                      ),
                    ],
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
                'The founder of Affinity combines product development, transparent financial modelling, buyer-first acquisition frameworks, and AI-assisted decision tools. Consulting is designed for business buyers who need help defining a mandate, preparing for financing, screening a live deal, or organizing diligence.',
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
            color: const Color(0xFFE9E6E0),
            border: Border.all(color: purple),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Tell us where you need support',
                style: TextStyle(
                  color: ink,
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
    title: 'Professional Member Studio',
    subtitle:
        'Build a credible presence where acquisition buyers can discover your expertise, understand your services, and request support.',
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BE VISIBLE AT THE RIGHT MOMENT',
                style: TextStyle(
                  color: purple,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your expertise belongs inside the acquisition journey.',
                style: TextStyle(
                  color: ink,
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Create a professional presence, be discovered by serious buyers, and receive consented introductions when your services match a real need.',
                style: TextStyle(color: Color(0xFF555568), height: 1.55),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _studio(
                box,
                'My professional profile',
                'Show buyers your credentials, location, specialties, and the services you provide.',
                Icons.badge_outlined,
                () => _open(context, const ProfilePage()),
              ),
              _studio(
                box,
                'Member directory presence',
                'See how acquisition professionals appear to buyers looking for trusted support.',
                Icons.storefront_outlined,
                () => _open(
                  context,
                  const LocalNetworkPage(side: PlatformSide.business),
                ),
              ),
              _studio(
                box,
                'Buyer lead inbox',
                'Manage consented introductions from buyers who need your specific expertise.',
                Icons.inbox_outlined,
                () => _open(context, const MemberLeadInboxPage()),
              ),
              _studio(
                box,
                'Deal collaboration',
                'Join the buyer around an active opportunity and keep the work moving in one place.',
                Icons.handshake_outlined,
                () => _open(
                  context,
                  const DealRoomsPage(initialSide: PlatformSide.business),
                ),
              ),
            ],
          ),
        ),
      ],
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
                color: ink,
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
    backgroundColor: const Color(0xFFF4F1EB),
    appBar: AppBar(
      toolbarHeight: 78,
      backgroundColor: const Color(0xFFF7F5F0),
      surfaceTintColor: Colors.transparent,
      foregroundColor: ink,
      title: const HomeBrandButton(size: 58, dark: false),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business, dark: false),
        SizedBox(width: 12),
      ],
    ),
    body: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EB),
        image: DecorationImage(
          image: const AssetImage(
            'assets/images/affinity-reflection-facade.png',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            const Color(0xFFF4F1EB).withValues(alpha: .92),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: SingleChildScrollView(
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
                    color: ink,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: muted, height: 1.5),
                ),
                if (action != null) ...[const SizedBox(height: 18), action!],
                const SizedBox(height: 28),
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
