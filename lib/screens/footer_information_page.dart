import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/footer_page_content.dart';
import '../models/platform_side.dart';
import '../services/site_content_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/membership_footer.dart';
import '../widgets/site_copy_text.dart';
import 'acquisition_support_page.dart';
import 'assistant_workspace_page.dart';
import 'deal_rooms_page.dart';
import 'member_deal_marketplace_page.dart';
import 'page_flow.dart';
import '../services/app_tunnel.dart';

const _forest = Color(0xFF053827);
const _cream = Color(0xFFF4F1EB);
const _ink = Color(0xFF17241E);
const _muted = Color(0xFF626B64);

/// Informational destinations reached through the site footer, separate from
/// the app's working screens and its dropdown navigation destinations.
class FooterInformationPage extends StatefulWidget {
  const FooterInformationPage({super.key, required this.topic});
  final FooterTopic topic;
  @override
  State<FooterInformationPage> createState() => _FooterInformationPageState();
}

Widget footerDestination(FooterTopic topic) {
  if (topic.isInformationPage) return FooterInformationPage(topic: topic);
  if (AppTunnelController.current.value == AppTunnel.landing) {
    AppTunnelController.select(
      topic == FooterTopic.memberStudio ? AppTunnel.member : AppTunnel.buyer,
    );
  }
  return footerToolDestination(topic);
}

Widget footerToolDestination(FooterTopic topic) => switch (topic) {
  FooterTopic.blueprint => const AcquisitionBlueprintPage(),
  FooterTopic.readiness => const BuyerReadinessPage(),
  FooterTopic.dealScreen => const DealRoomsPage(
    initialSide: PlatformSide.business,
    initialView: BuyerDashboardView.dealScreen,
  ),
  FooterTopic.pipeline || FooterTopic.approach => const DealRoomsPage(
    initialSide: PlatformSide.business,
  ),
  FooterTopic.memberStudio => const MemberDealMarketplacePage(),
  FooterTopic.directory => const MemberDealMarketplacePage(
    initialView: MemberDashboardView.professionals,
  ),
  FooterTopic.buyerLeads => const MemberDealMarketplacePage(
    initialView: MemberDashboardView.opportunities,
  ),
  FooterTopic.consulting ||
  FooterTopic.contact => const PersonalizedConsultingPage(),
  FooterTopic.privacy ||
  FooterTopic.terms => const FooterInformationPage(topic: FooterTopic.contact),
};

class _FooterInformationPageState extends State<FooterInformationPage> {
  final _scroll = ScrollController();
  late final _sectionKeys = List.generate(
    widget.topic.content.sections.length,
    (_) => GlobalKey(),
  );
  FooterPageContent get page => widget.topic.content;
  String get _prefix => 'footer.page.${widget.topic.slug}';
  bool get _document =>
      widget.topic == FooterTopic.privacy || widget.topic == FooterTopic.terms;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _copy(
    String key,
    String text, {
    double size = 16,
    Color color = _ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.65,
  }) => SiteCopyText(
    '$_prefix.$key',
    text,
    style: TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: size > 30 ? -size * .035 : 0,
    ),
  );

  void _jump(int index) {
    final target = _sectionKeys[index].currentContext;
    if (target != null)
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 350),
        alignment: .05,
      );
  }

  Future<void> _openTool() async {
    final destination = footerToolDestination(widget.topic);
    if (widget.topic == FooterTopic.blueprint ||
        widget.topic == FooterTopic.readiness) {
      await openAccountPage(context, destination);
    } else {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => destination));
    }
  }

  Widget _action({bool light = false}) => FilledButton.icon(
    key: Key('footer-tool-${widget.topic.slug}'),
    onPressed: _openTool,
    style: FilledButton.styleFrom(
      backgroundColor: light ? _cream : _forest,
      foregroundColor: light ? _forest : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    ),
    icon: const Icon(Icons.north_east, size: 18),
    label: _copy(
      'action',
      page.action,
      size: 15,
      color: light ? _forest : Colors.white,
      weight: FontWeight.w600,
      height: 1.3,
    ),
  );

  Widget _bounded(Widget child, {Color color = _cream, double vertical = 56}) =>
      Material(
        color: color,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 700 ? 24 : 56,
            vertical: vertical,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: child,
            ),
          ),
        ),
      );

  Widget _hero(bool wide) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _copy(
          'group',
          page.group,
          size: 11,
          color: _muted,
          weight: FontWeight.w700,
        ),
        const SizedBox(height: 16),
        _copy('label', page.label, size: 17, weight: FontWeight.w600),
        const SizedBox(height: 20),
        _copy(
          'headline',
          page.headline,
          size: wide ? 58 : 38,
          weight: FontWeight.w500,
          height: 1.1,
        ),
        const SizedBox(height: 24),
        _copy('intro', page.intro, size: 18),
        const SizedBox(height: 28),
        if (page.action.isNotEmpty)
          _action()
        else
          OutlinedButton.icon(
            onPressed: () => _jump(0),
            icon: const Icon(Icons.south, size: 18),
            label: _copy(
              'read',
              'Read the guide',
              size: 14,
              weight: FontWeight.w600,
            ),
          ),
      ],
    );
    final overview = Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _forest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _copy(
            'overview.label',
            _document ? 'AT A GLANCE' : 'YOUR NEXT CHAPTER',
            color: const Color(0xFFA4BAA8),
            size: 11,
            weight: FontWeight.w700,
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < page.sections.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    color: Color(0xFFA4BAA8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _copy(
                    'section.$i.title',
                    page.sections[i].title,
                    color: Colors.white,
                    size: 17,
                    weight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            if (i < page.sections.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 17),
                child: Divider(color: Color(0xFF365849), height: 1),
              ),
          ],
        ],
      ),
    );
    return wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: heading),
              const SizedBox(width: 80),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: overview,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [heading, const SizedBox(height: 38), overview],
          );
  }

  Widget _contents() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _copy(
        'contents',
        'ON THIS PAGE',
        size: 11,
        color: _muted,
        weight: FontWeight.w700,
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < page.sections.length; i++)
        TextButton(
          key: Key('footer-section-$i'),
          onPressed: () => _jump(i),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: _forest,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          ),
          child: _copy(
            'section.$i.title',
            page.sections[i].title,
            size: 14,
            weight: FontWeight.w500,
            height: 1.4,
          ),
        ),
    ],
  );

  Widget _sections() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < page.sections.length; i++)
        Container(
          key: _sectionKeys[i],
          padding: const EdgeInsets.only(bottom: 38),
          margin: const EdgeInsets.only(bottom: 38),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFDADFD9))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}'.padLeft(2, '0'),
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _copy(
                      'section.$i.title',
                      page.sections[i].title,
                      size: 27,
                      weight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _copy('section.$i.body', page.sections[i].body),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (var j = 0; j < page.sections[i].points.length; j++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _cream,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _copy(
                        'section.$i.point.$j',
                        page.sections[i].points[j],
                        size: 12,
                        color: _muted,
                        weight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      if (widget.topic == FooterTopic.contact) _contactDetails(),
      _copy(
        'faq.heading',
        'A few useful answers',
        size: 28,
        weight: FontWeight.w500,
        height: 1.3,
      ),
      const SizedBox(height: 22),
      for (var i = 0; i < page.faqs.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ExpansionTile(
            key: Key('footer-faq-$i'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 18),
            title: _copy(
              'faq.$i.question',
              page.faqs[i].$1,
              size: 17,
              weight: FontWeight.w500,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _copy('faq.$i.answer', page.faqs[i].$2, color: _muted),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _contactDetails() => ValueListenableBuilder<int>(
    valueListenable: SiteContentService.revision,
    builder: (_, _, _) {
      final email = SiteContentService.text(
        'footer.contact.company_email',
        'Company email coming soon',
      ).trim();
      final ready = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 40),
        color: _cream,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _copy(
              'company.heading',
              'Company contact',
              size: 23,
              weight: FontWeight.w500,
            ),
            const SizedBox(height: 12),
            const SiteCopyText(
              'footer.contact.company_email',
              'Company email coming soon',
              style: TextStyle(color: _forest, fontSize: 17),
            ),
            if (ready) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.mail_outline, size: 18),
                label: _copy(
                  'email.button',
                  'Email Affinity',
                  color: Colors.white,
                  size: 14,
                ),
                onPressed: () async {
                  final uri = Uri(scheme: 'mailto', path: email);
                  try {
                    if (!await launchUrl(uri))
                      throw StateError('Email app unavailable');
                  } catch (_) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please email $email using your email app.',
                          ),
                        ),
                      );
                  }
                },
              ),
            ],
            const SizedBox(height: 18),
            OutlinedButton.icon(
              icon: const Icon(Icons.people_outline, size: 18),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MemberDealMarketplacePage(
                    initialView: MemberDashboardView.professionals,
                  ),
                ),
              ),
              label: _copy(
                'directory.button',
                'Find a deal professional',
                size: 14,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.topic.isInformationPage)
      return footerToolDestination(widget.topic);
    final wide = MediaQuery.sizeOf(context).width >= 960;
    return Scaffold(
      backgroundColor: _cream,
      body: SelectionArea(
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(
              child: _bounded(
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const AcquisitionSupportPage(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: HomeBrandButton(size: 38, dark: false),
                      ),
                    ),
                    const AppNavigationMenu(dark: false),
                  ],
                ),
                vertical: 20,
              ),
            ),
            SliverToBoxAdapter(
              child: _bounded(_hero(wide), vertical: wide ? 76 : 40),
            ),
            SliverToBoxAdapter(
              child: _bounded(
                wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 230, child: _contents()),
                          const SizedBox(width: 70),
                          Expanded(child: _sections()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _contents(),
                          const SizedBox(height: 36),
                          _sections(),
                        ],
                      ),
                color: Colors.white,
                vertical: 64,
              ),
            ),
            SliverToBoxAdapter(
              child: _bounded(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _copy(
                      'closing.heading',
                      _document
                          ? 'Have a question?'
                          : 'Take the next step when you’re ready.',
                      size: wide ? 38 : 30,
                      weight: FontWeight.w500,
                      height: 1.2,
                    ),
                    const SizedBox(height: 24),
                    if (page.action.isNotEmpty)
                      _action()
                    else
                      OutlinedButton.icon(
                        onPressed: _openTool,
                        icon: const Icon(Icons.north_east, size: 18),
                        label: _copy(
                          'contact.button',
                          'Open Contact',
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: MembershipFooter()),
          ],
        ),
      ),
    );
  }
}
