import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/account_service.dart';
import '../services/member_content_service.dart';
import '../services/member_ai_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/topo_background.dart';

const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);

class MemberLeadInboxPage extends StatefulWidget {
  const MemberLeadInboxPage({super.key});

  @override
  State<MemberLeadInboxPage> createState() => _MemberLeadInboxPageState();
}

class _MemberLeadInboxPageState extends State<MemberLeadInboxPage> {
  late Future<List<IntroductionRequest>> _leads;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _leads = AccountService.loadIncomingIntroductions();
  }

  void _reload() => setState(() {
    _leads = AccountService.loadIncomingIntroductions();
  });

  Future<void> _update(IntroductionRequest lead, String status) async {
    await AccountService.respondToIntroduction(
      introductionId: lead.id,
      status: status,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) => _MemberWorkspaceShell(
    eyebrow: 'MEMBER WORKSPACE',
    title: 'Lead inbox',
    description:
        'Every consented connection brief in one place, from first response to a won client.',
    child: FutureBuilder<List<IntroductionRequest>>(
      future: _leads,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        final leads = snapshot.data ?? const <IntroductionRequest>[];
        final filtered = leads.where((lead) {
          if (_filter == 'all') return true;
          if (_filter == 'active') {
            return {
              'accepted',
              'qualified',
              'contacted',
              'consultation',
            }.contains(lead.status);
          }
          if (_filter == 'closed') {
            return {'lost', 'declined', 'closed'}.contains(lead.status);
          }
          return lead.status == _filter;
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final filter in const [
                  ('all', 'All'),
                  ('new', 'New'),
                  ('active', 'Active'),
                  ('won', 'Won'),
                  ('closed', 'Closed'),
                ])
                  ChoiceChip(
                    label: Text(filter.$2),
                    selected: _filter == filter.$1,
                    onSelected: (_) => setState(() => _filter = filter.$1),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            if (filtered.isEmpty)
              const _EmptyWorkspace(
                icon: Icons.inbox_outlined,
                title: 'No leads in this view',
                message:
                    'When a buyer sends a connection brief from your public profile, it appears here with their consented contact details and decision context.',
              )
            else
              ...filtered.map(
                (lead) => _LeadCard(
                  lead: lead,
                  onStatus: (status) => _update(lead, status),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead, required this.onStatus});

  final IntroductionRequest lead;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E1E8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lead.requesterName.isEmpty
                    ? 'New buyer lead'
                    : lead.requesterName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _StatusPill(lead.status),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${lead.requesterEmail}${lead.requesterPhone.isEmpty ? '' : ' · ${lead.requesterPhone}'} · ${DateFormat.yMMMd().format(lead.createdAt)}',
          style: const TextStyle(color: Color(0xFF696976), fontSize: 12),
        ),
        const SizedBox(height: 15),
        Text(
          lead.propertySummary.isEmpty
              ? 'No purchase context was supplied.'
              : lead.propertySummary,
          style: const TextStyle(height: 1.55),
        ),
        const SizedBox(height: 17),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (lead.status == 'new')
              FilledButton.tonal(
                onPressed: () => onStatus('accepted'),
                child: const Text('Accept lead'),
              ),
            if (!{'won', 'lost', 'declined', 'closed'}.contains(lead.status))
              OutlinedButton(
                onPressed: () => onStatus('contacted'),
                child: const Text('Mark contacted'),
              ),
            if (!{'won', 'lost', 'declined', 'closed'}.contains(lead.status))
              OutlinedButton(
                onPressed: () => onStatus('won'),
                child: const Text('Mark won'),
              ),
          ],
        ),
      ],
    ),
  );
}

class MemberEmailComposerPage extends StatefulWidget {
  const MemberEmailComposerPage({super.key, this.senderName = ''});

  final String senderName;

  @override
  State<MemberEmailComposerPage> createState() =>
      _MemberEmailComposerPageState();
}

class _MemberEmailComposerPageState extends State<MemberEmailComposerPage> {
  final _recipient = TextEditingController();
  final _context = TextEditingController();
  String _purpose = 'Client update';
  String _tone = 'Professional';
  MemberEmailDraft? _draft;
  bool _generating = false;

  @override
  void dispose() {
    _recipient.dispose();
    _context.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      _draft = await MemberAiService.composeEmail(
        recipientName: _recipient.text,
        senderName: widget.senderName,
        purpose: _purpose,
        context: _context.text,
        tone: _tone,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) => _MemberWorkspaceShell(
    eyebrow: 'MEMBER WORKSPACE · DRAFT ONLY',
    title: 'AI email composer',
    description:
        'Turn client context into a polished first draft. Nothing is sent automatically—review, personalize and copy it when ready.',
    child: Column(
      children: [
        _BuilderPanel(
          children: [
            TextField(
              controller: _recipient,
              decoration: const InputDecoration(labelText: 'Client name'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _purpose,
              decoration: const InputDecoration(labelText: 'Email goal'),
              items:
                  const [
                        'Client update',
                        'Meeting follow-up',
                        'Document request',
                        'Professional introduction',
                        'Re-engagement',
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _purpose = value!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _tone,
              decoration: const InputDecoration(labelText: 'Tone'),
              items: const ['Professional', 'Warm', 'Concise']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _tone = value!),
            ),
            TextField(
              controller: _context,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Context and facts to include',
                hintText:
                    'Meeting notes, next step, deadline or documents needed…',
              ),
            ),
            FilledButton.icon(
              onPressed: _generating ? null : _generate,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(_generating ? 'Generating…' : 'Create draft'),
            ),
          ],
        ),
        if (_draft != null) ...[
          const SizedBox(height: 18),
          _DraftCard(
            subject: _draft!.subject,
            body: _draft!.body,
            copyText: _draft!.copyText,
          ),
        ],
      ],
    ),
  );
}

class MemberNewsletterBuilderPage extends StatefulWidget {
  const MemberNewsletterBuilderPage({super.key, this.memberName = ''});

  final String memberName;

  @override
  State<MemberNewsletterBuilderPage> createState() =>
      _MemberNewsletterBuilderPageState();
}

class _MemberNewsletterBuilderPageState
    extends State<MemberNewsletterBuilderPage> {
  final _city = TextEditingController();
  final _theme = TextEditingController();
  final _insight = TextEditingController();
  final _cta = TextEditingController();
  String _audience = 'Property buyers';
  MemberNewsletterDraft? _draft;
  bool _generating = false;

  @override
  void dispose() {
    _city.dispose();
    _theme.dispose();
    _insight.dispose();
    _cta.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      _draft = await MemberAiService.composeNewsletter(
        memberName: widget.memberName,
        city: _city.text,
        audience: _audience,
        theme: _theme.text,
        insight: _insight.text,
        callToAction: _cta.text,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) => _MemberWorkspaceShell(
    eyebrow: 'MEMBER WORKSPACE · MONTHLY CONTENT',
    title: 'Newsletter builder',
    description:
        'Build a useful local update your clients will actually read. Add your verified insight, then review and copy the finished draft.',
    child: Column(
      children: [
        _BuilderPanel(
          children: [
            TextField(
              controller: _city,
              decoration: const InputDecoration(
                labelText: 'City or market',
                hintText: 'Victoria, BC',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              decoration: const InputDecoration(labelText: 'Audience'),
              items:
                  const [
                        'Property buyers',
                        'Business buyers',
                        'Past clients',
                        'Referral partners',
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _audience = value!),
            ),
            TextField(
              controller: _theme,
              decoration: const InputDecoration(
                labelText: 'Main theme',
                hintText: 'What buyers should prepare this month',
              ),
            ),
            TextField(
              controller: _insight,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Your verified market insight',
                hintText:
                    'Add the facts or observation that make this genuinely useful…',
              ),
            ),
            TextField(
              controller: _cta,
              decoration: const InputDecoration(labelText: 'Call to action'),
            ),
            FilledButton.icon(
              onPressed: _generating ? null : _generate,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(_generating ? 'Generating…' : 'Build newsletter'),
            ),
          ],
        ),
        if (_draft != null) ...[
          const SizedBox(height: 18),
          _DraftCard(
            subject: _draft!.subject,
            preview: _draft!.preview,
            body: _draft!.body,
            copyText: _draft!.copyText,
          ),
        ],
      ],
    ),
  );
}

class _MemberWorkspaceShell extends StatelessWidget {
  const _MemberWorkspaceShell({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TopoBackground(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 54),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            HomeBrandButton(size: 44),
                            Spacer(),
                            AppNavigationMenu(),
                          ],
                        ),
                        const SizedBox(height: 54),
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            color: Color(0xFFBCAEFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            height: .98,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 670),
                          child: Text(
                            description,
                            style: const TextStyle(
                              color: Color(0xFFB8B8C5),
                              fontSize: 15,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: child,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BuilderPanel extends StatelessWidget {
  const _BuilderPanel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE1E1E8)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 14,
        children: children
            .map(
              (child) => SizedBox(
                width: constraints.maxWidth > 760
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth,
                child: child,
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.subject,
    required this.body,
    required this.copyText,
    this.preview,
  });

  final String subject;
  final String? preview;
  final String body;
  final String copyText;

  @override
  Widget build(BuildContext context) => TopoCard(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR DRAFT',
          style: TextStyle(
            color: Color(0xFFBCAEFF),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(
          subject,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (preview != null) ...[
          const SizedBox(height: 7),
          SelectableText(
            preview!,
            style: const TextStyle(color: Color(0xFFB8B8C5)),
          ),
        ],
        const SizedBox(height: 20),
        SelectableText(
          body,
          style: const TextStyle(
            color: Color(0xFFE7E7ED),
            fontSize: 14,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: copyText));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Draft copied. Review it before sending.'),
                ),
              );
            }
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy draft'),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _purple.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF6040DD),
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE1E1E8)),
    ),
    child: Column(
      children: [
        Icon(icon, color: _purple, size: 35),
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF696976), height: 1.5),
        ),
      ],
    ),
  );
}
