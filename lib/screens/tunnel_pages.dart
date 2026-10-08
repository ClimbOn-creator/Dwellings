import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/business_sale_bulletin_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/nova_target.dart';
import '../widgets/site_copy_text.dart';
import 'auth_page.dart';
import 'bulletin_listing_pages.dart';
import 'member_deal_marketplace_page.dart';
import 'page_flow.dart';

const _forest = Color(0xFF164F3D);

class TunnelPageShell extends StatelessWidget {
  const TunnelPageShell({
    super.key,
    required this.guide,
    required this.title,
    required this.intro,
    required this.children,
  });
  final String guide;
  final String title;
  final String intro;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FBFD),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 82,
      backgroundColor: const Color(0xFFF7F8F4),
      surfaceTintColor: Colors.transparent,
      title: const HomeBrandButton(size: 66, dark: false),
      actions: [
        AppNavigationMenu(guidePage: guide, dark: false),
        const SizedBox(width: 12),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NovaTarget(
                id: '$guide.title',
                child: SiteCopyText(
                  'tunnel.$guide.title',
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SiteCopyText(
                'tunnel.$guide.intro',
                intro,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF657568),
                ),
              ),
              const SizedBox(height: 28),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _panel(String id, String title, String body, {Widget? action}) => Card(
  elevation: 0,
  color: Colors.white,
  shape: RoundedRectangleBorder(
    side: const BorderSide(color: Color(0xFFE2E8E5)),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Padding(
    padding: const EdgeInsets.all(26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteCopyText(
          'tunnel.$id.title',
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SiteCopyText(
          'tunnel.$id.body',
          body,
          style: const TextStyle(height: 1.6, fontSize: 15),
        ),
        if (action != null) ...[const SizedBox(height: 20), action],
      ],
    ),
  ),
);

class MemberPricingPage extends StatelessWidget {
  const MemberPricingPage({super.key});
  @override
  Widget build(BuildContext context) => TunnelPageShell(
    guide: 'member-pricing',
    title: 'Choose your membership',
    intro:
        'Build your presence on Affinity. Compare the membership options before you apply.',
    children: [
      NovaTarget(
        id: 'member-pricing.plans',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 840
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final plan in const [
                  (
                    'free',
                    'Free member',
                    'Public profile, reviews and limited introductions.',
                  ),
                  (
                    'professional',
                    'Professional',
                    'Deal Rooms, qualified introductions, pipeline and analytics.',
                  ),
                  (
                    'featured',
                    'Featured',
                    'Everything in Professional plus clearly disclosed promotion.',
                  ),
                ])
                  SizedBox(
                    width: width,
                    child: _panel(
                      'pricing.${plan.$1}',
                      plan.$2,
                      plan.$3,
                      action: FilledButton(
                        onPressed: () =>
                            startMemberSetup(context, tier: plan.$1),
                        child: const SiteCopyText(
                          'tunnel.pricing.apply',
                          'Apply for membership',
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      const SizedBox(height: 20),
      _panel(
        'pricing.availability',
        'Clear terms before you commit',
        'Paid plan prices have not been published yet. Applying records your preferred plan; it does not charge you or start a paid subscription. Final availability and pricing must be confirmed before purchase.',
      ),
    ],
  );
}

class MemberMarketingPage extends StatelessWidget {
  const MemberMarketingPage({super.key});
  @override
  Widget build(BuildContext context) => TunnelPageShell(
    guide: 'member-marketing',
    title: 'Make your expertise easy to find',
    intro:
        'A practical plan for building a credible presence and attracting relevant introductions on Affinity.',
    children: [
      NovaTarget(
        id: 'member-marketing.profile',
        child: _panel(
          'marketing.profile',
          '1. Start with your profile',
          'Use a clear portrait, your profession and service region. Write up to 200 words about your personal experience, who you help and the work you do. Keep qualifications and contact details current.',
          action: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MemberDealMarketplacePage(
                  initialView: MemberDashboardView.profile,
                ),
              ),
            ),
            icon: const Icon(Icons.person_outline),
            label: const SiteCopyText(
              'tunnel.marketing.edit',
              'Edit my professional profile',
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      NovaTarget(
        id: 'member-marketing.practice',
        child: _panel(
          'marketing.practice',
          '2. Earn trust through useful introductions',
          'Describe how your experience fits a particular deal. Keep responses specific, set expectations for the first conversation and agree on scope before starting work. Each deal team has one member per profession.',
        ),
      ),
      const SizedBox(height: 14),
      _panel(
        'marketing.reviews',
        '3. Let your work speak for itself',
        'After working together, invite clients to leave an honest member review. Do not promise incentives or invent testimonials. A detailed experience helps future clients understand your approach.',
      ),
      const SizedBox(height: 14),
      _panel(
        'marketing.promotion',
        '4. Consider promotion thoughtfully',
        'The Featured plan includes clearly disclosed promotion. Sponsored placement does not establish credentials or guarantee leads. Compare the options on Pricing, and keep your profile useful even without paid promotion.',
      ),
    ],
  );
}

class SellerPostsPage extends StatefulWidget {
  const SellerPostsPage({super.key, this.loadPosts});
  final Future<List<SellerPostStats>> Function()? loadPosts;
  @override
  State<SellerPostsPage> createState() => _SellerPostsPageState();
}

class _SellerPostsPageState extends State<SellerPostsPage> {
  late Future<List<SellerPostStats>> _posts;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _posts =
      (widget.loadPosts ?? BusinessSaleBulletinService.loadOwnedPosts)();
  Future<void> _edit([BusinessSaleBulletin? post]) async {
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => BulletinListingEditor(initial: post),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => TunnelPageShell(
    guide: 'seller-posts',
    title: 'My posts & analytics',
    intro:
        'Manage your business listings and follow real buyer saves. Only posts created by your account appear here.',
    children: [
      NovaTarget(
        id: 'seller-posts.create',
        child: FilledButton.icon(
          onPressed: _edit,
          icon: const Icon(Icons.add),
          label: const SiteCopyText(
            'tunnel.posts.create',
            'Create a business post',
          ),
        ),
      ),
      const SizedBox(height: 24),
      NovaTarget(
        id: 'seller-posts.list',
        child: FutureBuilder<List<SellerPostStats>>(
          future: _posts,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return _panel(
                'posts.error',
                'Posts could not load',
                'Please try again. If this persists, the seller analytics update may still need to be installed on the server.',
                action: TextButton(
                  onPressed: () => setState(_reload),
                  child: const SiteCopyText('tunnel.posts.retry', 'Try again'),
                ),
              );
            final posts = snapshot.data ?? [];
            if (posts.isEmpty)
              return _panel(
                'posts.empty',
                'Your sale starts here',
                'Create a post when you are ready to share your business. Your published listings, status and buyer saves will appear here. Sign in to load your existing posts.',
              );
            return Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metric('tunnel.posts.total', 'Posts', posts.length),
                    _metric(
                      'tunnel.posts.active',
                      'Active',
                      posts.where((p) => p.status == 'active').length,
                    ),
                    _metric(
                      'tunnel.posts.saves',
                      'Buyer saves',
                      posts.fold<int>(0, (sum, p) => sum + p.saves),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final post in posts)
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.listing.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${post.status} · ${post.listing.region} · ${post.listing.askingPriceBand}',
                          ),
                          const SizedBox(height: 10),
                          Text('${post.saves} buyer saves'),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            children: [
                              OutlinedButton(
                                onPressed: () => _edit(post.listing),
                                child: const SiteCopyText(
                                  'tunnel.posts.edit',
                                  'Edit post',
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => BusinessListingDetailPage(
                                      bulletinId: post.listing.id,
                                    ),
                                  ),
                                ),
                                child: const SiteCopyText(
                                  'tunnel.posts.view',
                                  'View listing',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                const SiteCopyText(
                  'tunnel.posts.note',
                  'Buyer saves are current bookmarks, not unique views or inquiries. No view counts are estimated.',
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
  Widget _metric(String id, String label, int value) => SizedBox(
    width: 200,
    child: Card(
      color: const Color(0xFFE9F3EE),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SiteCopyText(id, label),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 30,
                color: _forest,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
