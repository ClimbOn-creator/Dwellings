import '../widgets/site_text.dart';
import '../widgets/site_parallax_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/platform_side.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/membership_footer.dart';
import '../widgets/fixed_editorial_background.dart';
import 'local_network_page.dart';
import '../services/backend_service.dart';
import '../services/calendar_sync_service.dart';
import '../services/consulting_service.dart';
import '../services/site_content_service.dart';
import 'business_acquisition_page.dart';
import 'auth_page.dart';
import 'member_deal_marketplace_page.dart';

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
                const SiteText(
                  contentKey: 'copy.assistant_workspace_page.1',
                  literal: true,
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
                const SiteText(
                  contentKey: 'copy.assistant_workspace_page.2',
                  literal: true,
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
                            const SiteText(
                              contentKey: 'copy.assistant_workspace_page.3',
                              literal: true,
                              'Acquisition workspace',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const SiteText(
                              contentKey: 'copy.assistant_workspace_page.4',
                              literal: true,
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
                                  SiteText(
                                    contentKey:
                                        'copy.assistant_workspace_page.m1',
                                    literal: false,
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
    title: SiteText(
      contentKey: 'copy.assistant_workspace_page.m2',
      literal: false,
      t,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
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
              SiteText(
                contentKey: 'copy.assistant_workspace_page.m3',
                literal: false,
                ai ? 'DWELLINGIQ' : 'YOU',
                style: TextStyle(
                  color: ai ? lilac : muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 7),
              SiteText(
                contentKey: 'copy.assistant_workspace_page.m4',
                literal: false,
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
                      hint: SiteText(
                        'Ask, plan, or create something…',
                        contentKey: 'copy.assistant_workspace_page.field1',
                        literal: true,
                      ),
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
      SnackBar(
        content: SiteText(
          contentKey: 'copy.assistant_workspace_page.m5',
          literal: false,
          message.replaceFirst('Bad state: ', ''),
        ),
      ),
    );
  }

  Future<void> _edit(int index) async {
    final title = TextEditingController(text: events[index]['title']);
    final current = DateTime.parse(events[index]['date']!);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        title: const SiteText(
          contentKey: 'copy.assistant_workspace_page.5',
          literal: true,
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
            child: const SiteText(
              contentKey: 'copy.assistant_workspace_page.6',
              literal: true,
              'Cancel',
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, title.text.trim()),
            child: const SiteText(
              contentKey: 'copy.assistant_workspace_page.7',
              literal: true,
              'Choose date',
            ),
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
  Widget build(BuildContext context) => _Page /* persistent page identity */ (
    contentId: 'pipeline',
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
          label: const SiteText(
            contentKey: 'copy.assistant_workspace_page.8',
            literal: true,
            'Build my 90-day plan',
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _connect('google'),
          icon: Icon(
            connections.contains('google')
                ? Icons.check_circle
                : Icons.add_link,
          ),
          label: SiteText(
            contentKey: 'copy.assistant_workspace_page.m6',
            literal: false,
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
          label: SiteText(
            contentKey: 'copy.assistant_workspace_page.m7',
            literal: false,
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
                    child: SiteText(
                      contentKey: 'copy.assistant_workspace_page.m8',
                      literal: false,
                      '${i + 1}',
                    ),
                  ),
                  title: SiteText(
                    contentKey: 'copy.assistant_workspace_page.m9',
                    literal: false,
                    events[i]['title']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: SiteText(
                    contentKey: 'copy.assistant_workspace_page.m10',
                    literal: false,
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
                              child: SiteText(
                                contentKey: 'copy.assistant_workspace_page.m11',
                                literal: false,
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
  State<PersonalizedConsultingPage> createState() =>
      _PersonalizedConsultingPageState();
}

class _PersonalizedConsultingPageState
    extends State<PersonalizedConsultingPage> {
  static const _night = Color(0xFF070717);
  static const _blue = Color(0xFF526DFF);
  static const _lilacBright = Color(0xFFC8B8FF);
  static const _lime = Color(0xFFD7FF78);
  static const _coral = Color(0xFFFF8B79);
  static const _paper = Color(0xFFF5F5F7);

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _book(BuildContext context) async {
    if (BackendService.user == null) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const AuthPage()),
      );
      if (!context.mounted || BackendService.user == null) return;
    }
    if (!context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const ConsultingBookingPage()),
    );
  }

  SliverLayoutBuilder _reveal(Widget child) => SliverLayoutBuilder(
    builder: (context, sliver) => SliverToBoxAdapter(
      child: ValueListenableBuilder<bool>(
        valueListenable: SiteContentService.editing,
        builder: (context, editing, _) => AnimatedBuilder(
          animation: _scrollController,
          child: child,
          builder: (context, content) {
            final still = editing || MediaQuery.disableAnimationsOf(context);
            final viewport = MediaQuery.sizeOf(context).height;
            final top =
                sliver.precedingScrollExtent -
                (_scrollController.hasClients ? _scrollController.offset : 0);
            final progress = still
                ? 1.0
                : ((viewport - top) / (viewport * .52)).clamp(0.0, 1.0);
            return Opacity(
              opacity: .18 + progress * .82,
              child: Transform.translate(
                offset: Offset(0, (1 - progress) * 86),
                child: content,
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _hero(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    return SizedBox(
      height: compact ? 760 : 720,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SiteParallaxImage(
            controller: _scrollController,
            contentKey: 'image.assistant.consulting.background',
            asset: 'assets/images/affinity-consulting.jpg',
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xE6070717),
                    Color(0x9E171747),
                    Color(0xBC050510),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: compact ? 110 : 130,
            right: compact ? -90 : 42,
            child: IgnorePointer(
              child: Container(
                width: compact ? 260 : 390,
                height: compact ? 260 : 390,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _blue.withValues(alpha: .72),
                      _lilacBright.withValues(alpha: .08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 24 : 58,
              compact ? 150 : 178,
              compact ? 24 : 58,
              64,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: compact ? double.infinity : 790,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _lime,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const SiteText(
                            contentKey: 'copy.assistant_workspace_page.m12',
                            literal: true,
                            'THE PERSON BEHIND THE FRAMEWORK',
                            style: TextStyle(
                              color: _night,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SiteText(
                          contentKey: 'copy.assistant_workspace_page.m27',
                          literal: false,
                          SiteContentService.text(
                            'consulting.title',
                            'Founder-led acquisition consulting',
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 52 : 78,
                            height: .96,
                            fontWeight: FontWeight.w700,
                            letterSpacing: compact ? -2.5 : -4.2,
                          ),
                        ),
                        const SizedBox(height: 26),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 660),
                          child: SiteText(
                            contentKey: 'copy.assistant_workspace_page.m28',
                            literal: false,
                            SiteContentService.text(
                              'consulting.subtitle',
                              'A personal, rigorous second set of eyes for the decisions that shape what you buy—and what happens after.',
                            ),
                            style: const TextStyle(
                              color: Color(0xFFE0E3FF),
                              fontSize: 19,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        FilledButton.icon(
                          onPressed: () => _book(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 22,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.arrow_outward),
                          label: const SiteText(
                            contentKey: 'copy.assistant_workspace_page.9',
                            literal: true,
                            'SET UP A CALL',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perspectiveSection(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 850;
    final copy = Container(
      padding: EdgeInsets.all(compact ? 28 : 52),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15050510),
            blurRadius: 42,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SiteText(
            contentKey: 'copy.assistant_workspace_page.m13',
            literal: true,
            'Acquisition decisions deserve more than a spreadsheet.',
            style: TextStyle(
              color: _night,
              fontSize: 38,
              height: 1.08,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
            ),
          ),
          SizedBox(height: 26),
          SiteText(
            contentKey: 'copy.assistant_workspace_page.m14',
            literal: true,
            'Affinity was created around a simple belief: buyers make stronger choices when their personal goals, financial readiness, and deal criteria are examined together. The founder’s work combines product development, transparent financial modelling, and buyer-first decision systems to turn an intimidating acquisition into a series of clear, defensible choices.',
            style: TextStyle(color: muted, fontSize: 17, height: 1.65),
          ),
          SizedBox(height: 20),
          SiteText(
            contentKey: 'copy.assistant_workspace_page.m15',
            literal: true,
            'The process is practical and candid. A consulting engagement can sharpen an acquisition mandate, identify readiness gaps before a lender does, challenge the assumptions in a live opportunity, or organize the next phase of diligence. The goal is not to make the decision for you. It is to help you see the decision clearly enough to own it.',
            style: TextStyle(color: muted, fontSize: 17, height: 1.65),
          ),
        ],
      ),
    );
    final image = Transform.translate(
      offset: Offset(0, compact ? 0 : 56),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          height: compact ? 420 : 630,
          child: SiteParallaxImage(
            controller: _scrollController,
            contentKey: 'image.assistant_workspace_page.m1',
            asset: 'assets/images/affinity-consulting.jpg',
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xA8070717)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      color: _paper,
      padding: EdgeInsets.fromLTRB(
        compact ? 22 : 54,
        compact ? 72 : 118,
        compact ? 22 : 54,
        compact ? 76 : 150,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: compact
              ? Column(children: [image, const SizedBox(height: 24), copy])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: image),
                    const SizedBox(width: 34),
                    Expanded(flex: 6, child: copy),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _questionSection(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 800;
    return Container(
      color: _night,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 22 : 54,
        vertical: compact ? 74 : 122,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SiteText(
                contentKey: 'copy.assistant_workspace_page.m16',
                literal: true,
                'WHEN A CONVERSATION HELPS',
                style: TextStyle(
                  color: _coral,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              const SiteText(
                contentKey: 'copy.assistant_workspace_page.m17',
                literal: true,
                'Bring the question\nthat keeps looping.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  height: 1.02,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2.1,
                ),
              ),
              const SizedBox(height: 36),
              ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: SizedBox(
                  height: compact ? 400 : 520,
                  child: SiteParallaxImage(
                    controller: _scrollController,
                    contentKey: 'image.assistant_workspace_page.m2',
                    asset: 'assets/images/commercial-atrium.jpg',
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: compact ? double.infinity : 650,
                        margin: EdgeInsets.all(compact ? 16 : 32),
                        padding: EdgeInsets.all(compact ? 24 : 36),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .22),
                          ),
                        ),
                        child: const SiteText(
                          contentKey: 'copy.assistant_workspace_page.m18',
                          literal: true,
                          'Consulting is most useful when the numbers are available but the judgment is still hard: choosing a target, preparing to approach lenders, deciding whether to advance a deal, or translating diligence findings into an action plan. Sessions are built around your real situation and end with an explicit next step.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _closing(BuildContext context) => Container(
    color: _lilacBright,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 96),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          children: [
            const Icon(Icons.forum_outlined, color: _night, size: 38),
            const SizedBox(height: 24),
            SiteText(
              contentKey: 'copy.assistant_workspace_page.m19',
              literal: false,
              BackendService.user == null
                  ? 'You will be asked to sign in before choosing a time.'
                  : 'Choose a preferred date and time for your call.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _night,
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: () => _book(context),
              style: FilledButton.styleFrom(
                backgroundColor: _night,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text(
                'SET UP A CALL',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _night,
    body: CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 78,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _night.withValues(alpha: .94),
          surfaceTintColor: Colors.transparent,
          title: const HomeBrandButton(size: 58, dark: true),
          actions: const [
            AppNavigationMenu(side: PlatformSide.business),
            SizedBox(width: 12),
          ],
        ),
        SliverToBoxAdapter(child: _hero(context)),
        _reveal(_perspectiveSection(context)),
        _reveal(_questionSection(context)),
        _reveal(_closing(context)),
        const SliverToBoxAdapter(child: MembershipFooter()),
      ],
    ),
  );
}

class ConsultingBookingPage extends StatefulWidget {
  const ConsultingBookingPage({super.key});

  @override
  State<ConsultingBookingPage> createState() => _ConsultingBookingPageState();
}

class _ConsultingBookingPageState extends State<ConsultingBookingPage> {
  final phone = TextEditingController();
  final contextNotes = TextEditingController();
  DateTime? date;
  String time = '9:00 AM Pacific';
  String focus = 'Acquisition strategy session';
  bool sending = false;
  bool sent = false;

  @override
  void dispose() {
    phone.dispose();
    contextNotes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 120)),
    );
    if (selected != null) setState(() => date = selected);
  }

  Future<void> _submit() async {
    if (date == null || contextNotes.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SiteText(
            contentKey: 'copy.assistant_workspace_page.m20',
            literal: true,
            'Choose a date and add a little context first.',
          ),
        ),
      );
      return;
    }
    setState(() => sending = true);
    try {
      await ConsultingService.request(
        format: focus,
        phone: phone.text,
        outcome:
            'Preferred call: ${DateFormat('EEEE, MMMM d, y').format(date!)} at $time',
        challenge: contextNotes.text,
      );
      if (mounted) setState(() => sent = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              contentKey: 'copy.assistant_workspace_page.m21',
              literal: false,
              '$error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Page /* persistent page identity */ (
    contentId: 'consulting_booking',
    backgroundImage: 'assets/images/affinity-consulting.jpg',
    washOpacity: .62,
    title: 'Choose a time to talk',
    subtitle:
        'Share a preferred time and the decision you want to work through. The founder will confirm the appointment by email.',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: focus,
            items:
                const [
                      'Acquisition strategy session',
                      'Readiness and financing review',
                      'Live deal decision review',
                      'Diligence planning',
                    ]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: SiteText(
                          contentKey: 'copy.assistant_workspace_page.m22',
                          literal: false,
                          value,
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (value) => focus = value!,
            decoration: const InputDecoration(
              label: SiteText(
                'What should the call focus on?',
                contentKey: 'copy.assistant_workspace_page.field2',
                literal: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickDate,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 58),
              alignment: Alignment.centerLeft,
            ),
            icon: const Icon(Icons.calendar_today_outlined),
            label: SiteText(
              contentKey: 'copy.assistant_workspace_page.m23',
              literal: false,
              date == null
                  ? 'CHOOSE A DATE'
                  : DateFormat('EEEE, MMMM d, y').format(date!),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: time,
            items:
                const [
                      '9:00 AM Pacific',
                      '10:30 AM Pacific',
                      '1:00 PM Pacific',
                      '3:00 PM Pacific',
                    ]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: SiteText(
                          contentKey: 'copy.assistant_workspace_page.m24',
                          literal: false,
                          value,
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (value) => time = value!,
            decoration: const InputDecoration(
              label: SiteText(
                'Preferred time',
                contentKey: 'copy.assistant_workspace_page.field3',
                literal: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phone,
            decoration: const InputDecoration(
              label: SiteText(
                'Phone number',
                contentKey: 'copy.assistant_workspace_page.field4',
                literal: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: contextNotes,
            maxLines: 5,
            decoration: const InputDecoration(
              label: SiteText(
                'What would make this call useful?',
                contentKey: 'copy.assistant_workspace_page.field5',
                literal: true,
              ),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: sent || sending ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: sent ? const Color(0xFF2E775C) : ink,
              minimumSize: const Size(double.infinity, 58),
            ),
            icon: Icon(sent ? Icons.check : Icons.send_outlined),
            label: SiteText(
              contentKey: 'copy.assistant_workspace_page.m25',
              literal: false,
              sent
                  ? 'CALL REQUESTED'
                  : sending
                  ? 'SENDING…'
                  : 'REQUEST THIS TIME',
            ),
          ),
          const SizedBox(height: 10),
          SiteText(
            templateValues: {
              'value1':
                  '${BackendService.user?.email ?? 'your signed-in account'}',
            },
            contentKey: 'copy.assistant_workspace_page.m26',
            literal: false,
            "Request sent as {{value1}}. This does not place anything on your personal calendar until the appointment is confirmed.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

class MemberStudioPage extends StatelessWidget {
  const MemberStudioPage({super.key});

  @override
  Widget build(BuildContext context) => const MemberDealMarketplacePage();
}

class _Page extends StatelessWidget {
  const _Page({
    required this.contentId,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
    this.backgroundImage = 'assets/images/residential-courtyard.jpg',
    this.washOpacity = .68,
  });
  final String title, subtitle;
  final String contentId;
  final Widget child;
  final Widget? action;
  final String backgroundImage;
  final double washOpacity;
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
    body: FixedEditorialBackground(
      contentKey: 'image.assistant.$contentId.background',
      imagePath: backgroundImage,
      wash: const Color(0xFFF4F1EB),
      washOpacity: washOpacity,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 80),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 36,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFCF9).withValues(alpha: .97),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 34,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SiteText(
                              contentKey: 'copy.assistant_workspace_page.m27',
                              literal: false,
                              title,
                              style: const TextStyle(
                                color: ink,
                                fontSize: 48,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -2.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: SiteText(
                                contentKey: 'copy.assistant_workspace_page.m28',
                                literal: false,
                                subtitle,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 15,
                                  height: 1.55,
                                ),
                              ),
                            ),
                            if (action != null) ...[
                              const SizedBox(height: 18),
                              action!,
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      child,
                    ],
                  ),
                ),
              ),
            ),
            const MembershipFooter(),
          ],
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
    child: SiteText(
      contentKey: 'copy.assistant_workspace_page.m29',
      literal: false,
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: muted),
    ),
  );
}
