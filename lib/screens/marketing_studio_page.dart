import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/topo_background.dart';
import 'member_workspace_pages.dart';

const _ink = Color(0xFF050510);
const _surface = Color(0xFF121225);
const _line = Color(0xFF2B2B49);
const _lilac = Color(0xFFBCAEFF);
const _muted = Color(0xFFA5A5B5);

class MarketingStudioPage extends StatelessWidget {
  const MarketingStudioPage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _ink,
    body: TopoBackground(
      color: _ink,
      opacity: .11,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      HomeBrandButton(size: 44, dark: true),
                      Spacer(),
                      AppNavigationMenu(side: PlatformSide.business),
                    ],
                  ),
                  const SizedBox(height: 72),
                  const Text(
                    'MEMBER MARKETING',
                    style: TextStyle(
                      color: _lilac,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Marketing Studio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.sizeOf(context).width < 650
                          ? 46
                          : 68,
                      height: .98,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: const Text(
                      'Create practical business-acquisition outreach and useful member communications without additional software fees. Choose a tool, add your real facts, then review and copy the finished draft.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  LayoutBuilder(
                    builder: (context, box) {
                      final width = box.maxWidth >= 760
                          ? (box.maxWidth - 18) / 2
                          : box.maxWidth;
                      return Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: [
                          _MarketingCard(
                            width: width,
                            icon: Icons.mark_email_read_outlined,
                            eyebrow: 'OUTREACH',
                            title: 'Acquisition email composer',
                            description:
                                'Draft follow-ups, document requests, professional introductions, client updates, and re-engagement emails.',
                            action: 'Create an email',
                            onTap: () =>
                                _open(context, const MemberEmailComposerPage()),
                          ),
                          _MarketingCard(
                            width: width,
                            icon: Icons.newspaper_outlined,
                            eyebrow: 'AUDIENCE',
                            title: 'Member newsletter builder',
                            description:
                                'Turn verified market insight into a clear newsletter for business buyers, clients, or referral partners.',
                            action: 'Build a newsletter',
                            onTap: () => _open(
                              context,
                              const MemberNewsletterBuilderPage(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: _surface,
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Wrap(
                      spacing: 28,
                      runSpacing: 18,
                      children: [
                        _Principle(
                          title: 'Your facts',
                          copy:
                              'Templates use the context and insight you supply.',
                        ),
                        _Principle(
                          title: 'Your approval',
                          copy:
                              'Nothing is emailed or published automatically.',
                        ),
                        _Principle(
                          title: 'MVP-friendly',
                          copy:
                              'No AI key, usage charge, or calendar account required.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MarketingCard extends StatelessWidget {
  const _MarketingCard({
    required this.width,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: _surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 280,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _lilac, size: 34),
              const Spacer(),
              Text(
                eyebrow,
                style: const TextStyle(
                  color: _lilac,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                description,
                style: const TextStyle(color: _muted, height: 1.45),
              ),
              const SizedBox(height: 16),
              Text(
                '$action  →',
                style: const TextStyle(
                  color: _lilac,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Principle extends StatelessWidget {
  const _Principle({required this.title, required this.copy});
  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 285,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(copy, style: const TextStyle(color: _muted, height: 1.45)),
      ],
    ),
  );
}
