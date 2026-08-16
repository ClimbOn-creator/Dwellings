import 'package:flutter/material.dart';

import '../screens/become_member_page.dart';
import 'home_brand_button.dart';
import 'topo_background.dart';

class MembershipFooter extends StatelessWidget {
  const MembershipFooter({super.key});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BecomeMemberPage(
          onHome: () => HomeBrandButton.open(context),
          onAbout: () => HomeBrandButton.open(context),
          onTeam: () => HomeBrandButton.open(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => TopoCard(
    width: double.infinity,
    opacity: .16,
    color: const Color(0xFF101022),
    padding: const EdgeInsets.all(26),
    borderRadius: BorderRadius.circular(20),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DWELLINGSIQ MEMBERSHIP',
              style: TextStyle(
                color: Color(0xFFBCAEFF),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock the full member network and growth tools.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'See membership options, professional perks, and ways to participate.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .62),
                height: 1.45,
              ),
            ),
          ],
        );
        final button = FilledButton.icon(
          onPressed: () => _open(context),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7657FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          ),
          icon: const Icon(Icons.workspace_premium_outlined),
          label: const Text('BECOME A MEMBER'),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [copy, const SizedBox(height: 20), button],
          );
        }
        return Row(
          children: [
            Expanded(child: copy),
            const SizedBox(width: 24),
            button,
          ],
        );
      },
    ),
  );
}
