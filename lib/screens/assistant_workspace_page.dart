import '../widgets/nova_target.dart';
import '../widgets/nova_panel.dart';
import '../services/nova_service.dart';
import '../widgets/site_text.dart';
import '../widgets/site_parallax_image.dart';
import '../widgets/site_section.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/platform_side.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/membership_footer.dart';
import '../widgets/fixed_editorial_background.dart';
import '../services/backend_service.dart';
import '../services/calendar_sync_service.dart';
import '../services/consulting_service.dart';
import '../services/site_content_service.dart';
import 'auth_page.dart';
import 'member_deal_marketplace_page.dart';

const ink = Color(0xFF171717),
    surface = Color(0xFFFCFBF8),
    purple = Color(0xFF252525),
    lilac = Color(0xFF9B9B98),
    line = Color(0xFFD6D1C9),
    muted = Color(0xFF68635D);

class GuideWorkspacePage extends StatelessWidget {
  const GuideWorkspacePage({super.key, required this.foundationSummary});
  final String foundationSummary;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FD),
    appBar: AppBar(
      title: const SiteText(
        contentKey: 'copy.assistant_workspace_page.3',
        literal: true,
        'Pebble app walkthrough',
      ),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business, dark: false),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SiteText(
                contentKey: 'copy.assistant_workspace_page.4',
                literal: true,
                'Explore the app with Pebble. Use Next and Back, then replay the tour whenever you need it.',
              ),
              const SizedBox(height: 18),
              NovaPanel(
                initiallyOpen: true,
                context: NovaContext(
                  area: 'learning',
                  label: 'Your acquisition learning workspace',
                  facts: {'foundationSummary': foundationSummary},
                ),
              ),
            ],
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
  static const _forest = Color(0xFF053827);
  static const _cream = Color(0xFFF7F5F0);
  static const _sage = Color(0xFFEAF0EC);

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

  Widget _copy(
    String key,
    String fallback, {
    double size = 16,
    Color color = ink,
    bool italic = false,
  }) => SiteText(
    fallback,
    contentKey: key,
    literal: true,
    style: TextStyle(
      color: color,
      fontSize: size,
      height: size > 25 ? 1.16 : 1.65,
      fontWeight: size > 25 ? FontWeight.w500 : FontWeight.w400,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: size > 25 ? -.7 : .15,
    ),
  );

  Widget _photo(String key, String asset, double height, {bool arch = false}) =>
      ClipRRect(
        borderRadius: arch
            ? const BorderRadius.only(
                topLeft: Radius.circular(230),
                topRight: Radius.circular(230),
                bottomRight: Radius.circular(130),
              )
            : BorderRadius.zero,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: SiteParallaxImage(
            controller: _scrollController,
            contentKey: key,
            asset: asset,
            maxTravel: 150,
            scrollFactor: .42,
            child: const SizedBox.expand(),
          ),
        ),
      );

  Widget _section({
    required Widget child,
    Color color = Colors.white,
    double vertical = 86,
  }) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: color,
      border: const Border(top: BorderSide(color: line, width: .7)),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: MediaQuery.sizeOf(context).width < 760 ? 24 : 64,
      vertical: vertical,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: child,
      ),
    ),
  );

  Widget _callButton() => OutlinedButton.icon(
    onPressed: () => _book(context),
    style: OutlinedButton.styleFrom(
      foregroundColor: _forest,
      side: const BorderSide(color: _forest),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
      shape: const StadiumBorder(),
    ),
    icon: const Icon(Icons.arrow_outward, size: 17),
    label: const SiteText(
      'SET UP A CALL',
      contentKey: 'copy.assistant_workspace_page.9',
      literal: true,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _hero(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 800;
      final words = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 24 : 64,
          vertical: compact ? 48 : 72,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _copy(
              'copy.assistant_workspace_page.m12',
              'THE PERSON BEHIND THE FRAMEWORK',
              size: 11,
            ),
            const SizedBox(height: 23),
            SiteText(
              SiteContentService.text(
                'consulting.title',
                'Founder-led acquisition consulting',
              ),
              contentKey: 'copy.assistant_workspace_page.m27',
              literal: false,
              style: TextStyle(
                color: _forest,
                fontSize: compact ? 39 : 52,
                height: 1.12,
                letterSpacing: -1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            SiteText(
              SiteContentService.text(
                'consulting.subtitle',
                'A personal, rigorous second set of eyes for the decisions that shape what you buy—and what happens after.',
              ),
              contentKey: 'copy.assistant_workspace_page.m28',
              literal: false,
              style: const TextStyle(color: muted, fontSize: 17, height: 1.65),
            ),
            const SizedBox(height: 30),
            _callButton(),
          ],
        ),
      );
      final photo = _photo(
        'image.assistant.consulting.background',
        'assets/images/affinity-consulting.jpg',
        compact ? 340 : 580,
      );
      return ColoredBox(
        color: _cream,
        child: compact
            ? Column(children: [words, photo])
            : Row(
                children: [
                  Expanded(child: words),
                  Expanded(child: photo),
                ],
              ),
      );
    },
  );

  Widget _perspectiveSection(BuildContext context) => _section(
    color: _cream,
    child: LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 740;
        final image = _photo(
          'image.assistant_workspace_page.m1',
          'assets/images/affinity-consulting.jpg',
          compact ? 370 : 560,
          arch: true,
        );
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _copy(
              'copy.assistant_workspace_page.m13',
              'Acquisition decisions deserve more than a spreadsheet.',
              size: 34,
            ),
            const SizedBox(height: 25),
            _copy(
              'copy.assistant_workspace_page.m14',
              'Affinity was created around a simple belief: buyers make stronger choices when their personal goals, financial readiness, and deal criteria are examined together. The founder’s work combines product development, transparent financial modelling, and buyer-first decision systems to turn an intimidating acquisition into a series of clear, defensible choices.',
              size: 16,
            ),
            const SizedBox(height: 18),
            _copy(
              'copy.assistant_workspace_page.m15',
              'The process is practical and candid. A consulting engagement can sharpen an acquisition mandate, identify readiness gaps before a lender does, challenge the assumptions in a live opportunity, or organize the next phase of diligence. The goal is not to make the decision for you. It is to help you see the decision clearly enough to own it.',
              size: 16,
            ),
          ],
        );
        return compact
            ? Column(children: [image, const SizedBox(height: 36), copy])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 4, child: image),
                  const SizedBox(width: 80),
                  Expanded(flex: 6, child: copy),
                ],
              );
      },
    ),
  );

  Widget _questionSection(BuildContext context) => _section(
    child: LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 740;
        final words = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _copy(
              'copy.assistant_workspace_page.m16',
              'WHEN A CONVERSATION HELPS',
              size: 11,
            ),
            const SizedBox(height: 22),
            _copy(
              'copy.assistant_workspace_page.m17',
              'Bring the question\nthat keeps looping.',
              size: 38,
            ),
            const SizedBox(height: 25),
            _copy(
              'copy.assistant_workspace_page.m18',
              'Consulting is most useful when the numbers are available but the judgment is still hard: choosing a target, preparing to approach lenders, deciding whether to advance a deal, or translating diligence findings into an action plan. Sessions are built around your real situation and end with an explicit next step.',
              size: 16,
            ),
          ],
        );
        final photo = ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(220),
            bottomLeft: Radius.circular(220),
          ),
          child: _photo(
            'image.assistant_workspace_page.m2',
            'assets/images/commercial-atrium.jpg',
            compact ? 320 : 490,
          ),
        );
        return compact
            ? Column(children: [photo, const SizedBox(height: 36), words])
            : Row(
                children: [
                  Expanded(child: words),
                  const SizedBox(width: 70),
                  Expanded(child: photo),
                ],
              );
      },
    ),
  );

  Widget _focusSection() => _section(
    color: _sage,
    child: LayoutBuilder(
      builder: (context, box) {
        const areas = <(String, String, String, IconData)>[
          (
            'direction',
            'Acquisition direction',
            'Clarify what you want to buy, why it fits, and what you need from ownership.',
            Icons.explore_outlined,
          ),
          (
            'readiness',
            'Financial readiness',
            'Prepare the questions and evidence to discuss with your financing team.',
            Icons.account_balance_outlined,
          ),
          (
            'deal',
            'Deal decisions',
            'Test the assumptions behind an opportunity before deciding your next step.',
            Icons.balance_outlined,
          ),
          (
            'diligence',
            'Diligence planning',
            'Turn open questions into a clear work plan with the right professional leads.',
            Icons.fact_check_outlined,
          ),
          (
            'transition',
            'Ownership transition',
            'Think through people, operations and the responsibilities of the handover.',
            Icons.handshake_outlined,
          ),
          (
            'next',
            'Your next move',
            'Leave the conversation with a practical decision or action to move forward.',
            Icons.arrow_forward_rounded,
          ),
        ];
        final columns = box.maxWidth < 600
            ? 1
            : box.maxWidth < 900
            ? 2
            : 3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _copy(
              'consulting.focus.title',
              'Focus areas',
              size: 34,
              color: _forest,
              italic: true,
            ),
            const SizedBox(height: 22),
            const Divider(color: line),
            const SizedBox(height: 30),
            Wrap(
              spacing: 36,
              runSpacing: 44,
              children: [
                for (final (id, title, description, icon) in areas)
                  SizedBox(
                    width: (box.maxWidth - (columns - 1) * 36) / columns,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: _forest, size: 24),
                        const SizedBox(height: 14),
                        _copy(
                          'consulting.focus.$id.title',
                          title,
                          size: 19,
                          color: _forest,
                        ),
                        const SizedBox(height: 10),
                        _copy(
                          'consulting.focus.$id.body',
                          description,
                          size: 15,
                          color: muted,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );

  Widget _closing(BuildContext context) => _section(
    color: _cream,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            const Icon(Icons.calendar_month_outlined, color: _forest, size: 34),
            const SizedBox(height: 22),
            _copy(
              'consulting.booking.heading',
              'Make room for a clearer next step.',
              size: 36,
              color: _forest,
            ),
            const SizedBox(height: 20),
            SiteText(
              BackendService.user == null
                  ? 'You will be asked to sign in before choosing a time.'
                  : 'Choose a preferred date and time for your call.',
              contentKey: 'copy.assistant_workspace_page.m19',
              literal: false,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 17, height: 1.6),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              key: const Key('consulting_calendar'),
              onPressed: () => _book(context),
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 22,
                ),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('SET UP A CALL'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: false),
    child: Scaffold(
      backgroundColor: _cream,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            toolbarHeight: 82,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: _cream,
            surfaceTintColor: Colors.transparent,
            title: const HomeBrandButton(size: 66, dark: false),
            actions: [
              const AppNavigationMenu(
                guidePage: 'consulting',
                side: PlatformSide.business,
                dark: false,
              ),
              const SizedBox(width: 12),
            ],
          ),
          SliverToBoxAdapter(
            child: SiteSection(
              id: 'consulting.hero',
              label: 'Introduction',
              child: NovaTarget(id: 'consulting.hero', child: _hero(context)),
            ),
          ),
          SliverToBoxAdapter(
            child: SiteSection(
              id: 'consulting.perspective',
              label: 'Our approach',
              child: NovaTarget(
                id: 'consulting.perspective',
                child: _perspectiveSection(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SiteSection(
              id: 'consulting.conversation',
              label: 'When a conversation helps',
              child: _questionSection(context),
            ),
          ),
          SliverToBoxAdapter(
            child: SiteSection(
              id: 'consulting.focus',
              label: 'Focus areas',
              child: NovaTarget(id: 'consulting.focus', child: _focusSection()),
            ),
          ),
          SliverToBoxAdapter(
            child: NovaTarget(
              id: 'consulting.booking',
              child: _closing(context),
            ),
          ),
          const SliverToBoxAdapter(child: MembershipFooter()),
        ],
      ),
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
