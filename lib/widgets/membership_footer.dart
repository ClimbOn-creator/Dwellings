import 'footer_circle_physics.dart';
import 'site_text.dart';
import 'package:flutter/material.dart';

import '../models/footer_page_content.dart';
import '../screens/footer_information_page.dart';
import 'auth_button.dart';
import 'brand_logo.dart';
import 'home_brand_button.dart';
import '../services/app_tunnel.dart';

/// Full-width site footer. The historical class name is retained so every
/// existing screen receives the new footer without route-by-route migration.
class MembershipFooter extends StatelessWidget {
  const MembershipFooter({
    super.key,
    this.fullBleed = true,
    this.animateCircles = false,
  });
  final bool animateCircles;
  final bool fullBleed;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final compact = viewport < 1000;
    final tunnel = AppTunnelController.current.value;
    final columns = [
      if (tunnel == AppTunnel.landing || tunnel == AppTunnel.buyer)
        _FooterColumn(
          title: 'ACQUISITION PATH',
          items: [
            FooterTopic.blueprint,
            FooterTopic.readiness,
            FooterTopic.dealScreen,
            FooterTopic.pipeline,
          ],
        ),
      if (tunnel == AppTunnel.landing || tunnel == AppTunnel.member)
        _FooterColumn(
          title: 'PROFESSIONALS',
          items: [FooterTopic.memberStudio, FooterTopic.consulting],
        ),
      _FooterColumn(
        title: 'PACT',
        items: [
          FooterTopic.approach,
          FooterTopic.privacy,
          FooterTopic.terms,
          FooterTopic.contact,
        ],
      ),
    ];
    final content = Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 26 : 64,
        compact ? 54 : 76,
        compact ? 26 : 64,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FooterIdentity(),
                const SizedBox(height: 42),
                ...columns.map(
                  (column) => Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: column,
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 4, child: _FooterIdentity()),
                for (final column in columns) Expanded(flex: 2, child: column),
              ],
            ),
          const SizedBox(height: 46),
          const Divider(color: Color(0xFFDCE4DA)),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: SiteText(
                  contentKey: 'copy.membership_footer.m1',
                  literal: true,
                  '© 2026 PACT · BUSINESS ACQUISITION, MADE NAVIGABLE',
                  style: TextStyle(
                    color: Color(0xFF68756B),
                    fontSize: 9,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              AuthButton(dark: false),
            ],
          ),
        ],
      ),
    );
    final footer = animateCircles
        ? InteractiveCircleFooter(child: content)
        : ColoredBox(color: Colors.white, child: content);
    if (!fullBleed) return footer;
    return UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      alignment: Alignment.topCenter,
      child: SizedBox(width: viewport, child: footer),
    );
  }
}

class _FooterIdentity extends StatelessWidget {
  const _FooterIdentity();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () => HomeBrandButton.open(context),
        child: const AffinityFooterLogo(width: 300),
      ),
      SizedBox(height: 24),
      SizedBox(
        width: 300,
        child: SiteText(
          contentKey: 'copy.membership_footer.m2',
          literal: true,
          'Better judgment for the business you choose next.',
          style: TextStyle(
            color: Color(0xFF173A27),
            fontSize: 28,
            height: 1.08,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.items});
  final String title;
  final List<FooterTopic> items;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteText(
          contentKey: 'copy.membership_footer.m3',
          literal: false,
          title,
          style: const TextStyle(
            color: Color(0xFF173A27),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 20),
        for (final item in items) ...[
          TextButton(
            key: Key('footer-link-${item.slug}'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: RouteSettings(name: '/footer/${item.slug}'),
                builder: (_) => footerDestination(item),
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF405F4A),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: SiteText(
              contentKey: 'copy.membership_footer.m4',
              literal: false,
              item.content.label,
              style: const TextStyle(color: Color(0xFF536C59)),
            ),
          ),
        ],
      ],
    ),
  );
}
